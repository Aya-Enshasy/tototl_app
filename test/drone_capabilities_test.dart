import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tototl_app/core/constants/drone_capabilities.dart';
import 'package:tototl_app/features/pilot/models/drone_model.dart';
import 'package:tototl_app/core/localization/app_language.dart';
import 'package:tototl_app/core/localization/localized_text.dart';

void main() {
  tearDown(() => AppLanguage.locale.value = const Locale('en'));

  test('backend supports exactly nine capability values in documented order', () {
    expect(DroneCapabilities.values, [
      'thermal', 'laser', 'night_vision', 'lidar', 'radar',
      'imaging', 'rtk', 'zoom', 'other',
    ]);
    expect(DroneCapabilities.options.map((value) => value.value).toList(),
        DroneCapabilities.values);
    expect(DroneCapabilities.labels.length, 9);
  });

  test('registration and drone forms send unique canonical list values', () {
    expect(DroneCapabilities.canonicalizeAll([
      'Zoom Camera', 'THERMAL', 'Night Vision', 'zoom', 'Radar',
    ]), ['thermal', 'night_vision', 'radar', 'zoom']);
    expect(DroneCapabilities.canonicalizeAll(['LiDAR', 'Laser', 'Imaging']),
        ['laser', 'lidar', 'imaging']);
  });

  test('legacy accessories are not mistaken for explicitly selected Other', () {
    expect(DroneCapabilities.canonicalizeAll([
      'Spotlight', 'Winch', 'Multispectral', 'Parachute', 'Speaker',
    ]), isEmpty);
    expect(DroneCapabilities.canonicalizeAll(['']), isEmpty);
    expect(DroneCapabilities.canonicalizeAll(['Other']), ['other']);
    expect(DroneCapabilities.isFullMatch(
      required: ['other'],
      available: ['spotlight', 'multispectral'],
    ), isFalse);
    expect(DroneCapabilities.missing(
      required: ['other'],
      available: ['spotlight', 'multispectral'],
    ), ['other']);
    expect(DroneCapabilities.isFullMatch(
      required: ['other'],
      available: ['other'],
    ), isTrue);
  });

  test('a legacy drone payload cannot invent the backend Other capability', () {
    final drone = DroneModel.fromJson({
      'id': 1,
      'make': 'mavic',
      'model': 'test',
      'capabilities': ['spotlight', 'zoom'],
    });
    expect(drone.capabilities, ['zoom']);
    expect(DroneCapabilities.missing(
      required: ['other'],
      available: drone.capabilities,
    ), ['other']);
  });

  test('job application capability matching is normalized', () {
    expect(DroneCapabilities.isFullMatch(
      required: ['Thermal Camera', 'laser'],
      available: ['THERMAL', 'LiDAR', 'LASER'],
    ), true);
    expect(DroneCapabilities.missing(
      required: ['Thermal Camera', 'RADAR'],
      available: ['Thermal'],
    ), ['radar']);
  });

  testWidgets('localized constant Text updates on locale change', (tester) async {
    AppLanguage.locale.value = const Locale('ar');
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: LocalizedText('View Plans'),
    )));
    // LocalizedText extends Text and builds a child Text. Target the rendered
    // child so an English label isn't counted twice by find.text().
    final renderedLabel = find.descendant(
      of: find.byType(LocalizedText),
      matching: find.byType(Text),
    );
    expect(renderedLabel, findsOneWidget);
    expect(tester.widget<Text>(renderedLabel).data, 'عرض الخطط');

    AppLanguage.locale.value = const Locale('en');
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: LocalizedText('View Plans'),
    )));
    expect(renderedLabel, findsOneWidget);
    expect(tester.widget<Text>(renderedLabel).data, 'View Plans');
  });
}
