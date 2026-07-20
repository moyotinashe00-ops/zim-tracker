import 'package:flutter_test/flutter_test.dart';
import 'package:zim_tracker/main.dart';

void main() {
  testWidgets('App base test', (WidgetTester tester) async {
    await tester.pumpWidget(const ZimTrackerApp());
  });
}
