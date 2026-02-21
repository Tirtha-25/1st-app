import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/main.dart';

void main() {
  testWidgets('Weather app smoke test', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const WeatherApp());
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(WeatherApp), findsOneWidget);
    });
  });
}
