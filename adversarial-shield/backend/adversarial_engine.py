"""
adversarial_engine.py
---------------------
OPTIONAL module: a real gradient-based (PGD) adversarial perturbation against
a pretrained ResNet18, plus helpers to measure how much it changes the
model's predictions and embeddings.

Requires:  pip install torch torchvision
If torch is missing, TORCH_OK is False and the rest of the backend still works.

HONEST LIMITS (say this in your pitch):
  * This is a WHITE-BOX attack on ResNet18. It reliably fools ResNet18, but
    transfers only partially to other models (e.g. face-recognition or
    diffusion encoders).
  * Mild JPEG compression / resizing can weaken it.
  * Production tools (Fawkes, Glaze, Nightshade) optimize against many
    models and use perceptual-loss constraints.
"""

from typing import List

import numpy as np
from PIL import Image

try:
    import torch
    import torch.nn.functional as F
    from torchvision.models import ResNet18_Weights, resnet18

    TORCH_OK = True
except ImportError:  # pragma: no cover
    TORCH_OK = False

_MODEL = None
_CATEGORIES: List[str] = []
_INPUT_SIZE = 224


def _load_model():
    """Lazy-load ResNet18 (downloads ~45 MB of weights on first use)."""
    global _MODEL, _CATEGORIES
    if _MODEL is None:
        weights = ResNet18_Weights.DEFAULT
        _MODEL = resnet18(weights=weights).eval()
        for p in _MODEL.parameters():
            p.requires_grad_(False)
        _CATEGORIES = weights.meta["categories"]
    return _MODEL


def _to_tensor(image: Image.Image):
    """PIL -> float tensor (1,3,224,224) in [0,1]."""
    img = image.convert("RGB").resize((_INPUT_SIZE, _INPUT_SIZE), Image.BILINEAR)
    arr = np.array(img, dtype=np.float32) / 255.0
    return torch.from_numpy(arr).permute(2, 0, 1).unsqueeze(0)


def _normalize(x):
    mean = torch.tensor([0.485, 0.456, 0.406]).view(1, 3, 1, 1)
    std = torch.tensor([0.229, 0.224, 0.225]).view(1, 3, 1, 1)
    return (x - mean) / std


def _logits(x):
    return _MODEL(_normalize(x))


def _features(x):
    """Penultimate-layer embedding (512-d) of ResNet18."""
    m = _MODEL
    x = m.maxpool(m.relu(m.bn1(m.conv1(_normalize(x)))))
    x = m.layer4(m.layer3(m.layer2(m.layer1(x))))
    return torch.flatten(m.avgpool(x), 1)


def pgd_attack(image: Image.Image, eps: float = 6.0, steps: int = 20) -> Image.Image:
    """
    Untargeted PGD attack.

    Args:
        image: input PIL image.
        eps:   max per-pixel change in 0-255 units (4-8 is near-invisible).
        steps: optimization iterations.

    Maximizes (classification loss + embedding drift) so both the predicted
    label and the feature vector move away from the original.
    The perturbation is computed at 224x224 and upsampled to full size.
    """
    _load_model()
    eps_f = eps / 255.0
    alpha = eps_f / 4

    x0 = _to_tensor(image)
    with torch.no_grad():
        label = _logits(x0).argmax(1)
        feat0 = _features(x0)

    delta = torch.zeros_like(x0, requires_grad=True)
    for _ in range(steps):
        x_adv = (x0 + delta).clamp(0, 1)
        loss = F.cross_entropy(_logits(x_adv), label) + (
            1 - F.cosine_similarity(_features(x_adv), feat0).mean()
        )
        (grad,) = torch.autograd.grad(loss, delta)
        delta = (delta + alpha * grad.sign()).clamp(-eps_f, eps_f).detach()
        delta.requires_grad_(True)

    delta = ((x0 + delta).clamp(0, 1) - x0).detach()

    # Upsample perturbation to the original resolution and apply
    w, h = image.size
    delta_up = F.interpolate(delta, size=(h, w), mode="bilinear", align_corners=False)
    arr = np.asarray(image.convert("RGB"), dtype=np.float32) / 255.0
    out = np.clip(arr + delta_up[0].permute(1, 2, 0).numpy(), 0.0, 1.0)
    return Image.fromarray((out * 255).round().astype(np.uint8), mode="RGB")


def predict(image: Image.Image, k: int = 3) -> List[dict]:
    """Top-k ImageNet predictions from ResNet18."""
    _load_model()
    with torch.no_grad():
        probs = F.softmax(_logits(_to_tensor(image)), dim=1)[0]
        top = torch.topk(probs, k)
    return [
        {"label": _CATEGORIES[i], "confidence": round(float(p), 4)}
        for p, i in zip(top.values.tolist(), top.indices.tolist())
    ]


def embedding_similarity(a: Image.Image, b: Image.Image) -> float:
    """Cosine similarity of ResNet18 embeddings (1.0 = same, lower = model 'sees' a change)."""
    _load_model()
    with torch.no_grad():
        fa, fb = _features(_to_tensor(a)), _features(_to_tensor(b))
    return round(float(F.cosine_similarity(fa, fb).item()), 4)