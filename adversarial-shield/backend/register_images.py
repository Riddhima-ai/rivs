"""Register selected local image files as Digital Footprint candidates."""
import argparse
from pathlib import Path

from image_registry import register_file


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("images", nargs="+", type=Path, help="Image file paths to register")
    args = parser.parse_args()
    for path in args.images:
        row = register_file(path)
        print(f"Registered {row['filename']} ({row['sha256']})")


if __name__ == "__main__":
    main()
