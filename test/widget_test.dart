import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rivs/app_state.dart';
import 'package:rivs/main.dart';
import 'package:rivs/pages/protection_results_page.dart';
import 'package:rivs/models/threat_match.dart';
import 'package:rivs/widgets/threat_warning_card.dart';

void main() {
  testWidgets('dashboard shows core protection actions', (tester) async {
    await tester.pumpWidget(const DeepfakeShieldApp());

    expect(find.text('DEEPFAKE SHIELD'), findsOneWidget);
    expect(find.text('Protect My Photo'), findsOneWidget);
    expect(find.text('Scan Digital Footprint'), findsOneWidget);
    expect(find.text('Photos Processed'), findsOneWidget);
  });

  testWidgets('photo action opens selection and its back button returns home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DeepfakeShieldApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Protect My Photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Protect My Photo'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a portrait to get started.'), findsOneWidget);
    expect(find.text('Select Photo'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Go back'));
    await tester.pumpAndSettle();

    expect(find.text('Protect My Photo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('results pass the fingerprint to the scan page', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appState = AppState();
    addTearDown(appState.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ProtectionResultsPage(
          appState: appState,
          originalImage: Uint8List.fromList([1, 2, 3]),
          processedImage: Uint8List.fromList([4, 5, 6]),
          hash: 'invalid-hash',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Scan Digital Footprint'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Scan Digital Footprint'));
    await tester.pumpAndSettle();

    expect(find.text('Digital Footprint'), findsOneWidget);
    expect(find.text('invalid-hash'), findsOneWidget);
    expect(find.text('Scan unavailable'), findsOneWidget);
    expect(find.text('Retry Scan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('match card displays only supplied prototype data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: ThreatWarningCard(
                match: ThreatMatch(
                  platform: 'Prototype platform',
                  url: 'https://example.invalid/real-response',
                  similarity: 92.18,
                  isSimulated: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Prototype platform'), findsOneWidget);
    expect(find.text('https://example.invalid/real-response'), findsOneWidget);
    expect(find.text('92.2%'), findsOneWidget);
    expect(find.text('SIMULATED'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
