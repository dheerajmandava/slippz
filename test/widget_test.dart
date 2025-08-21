// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:slips_warranty_tracker/main.dart';

void main() {
  testWidgets('slips-warranty-tracker app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app starts with the ReceiptStorage screen
    expect(find.text('Receipt Storage'), findsOneWidget);
    expect(find.text('Add Receipt'), findsOneWidget);
    
    // Verify that form fields are present
    expect(find.text('Product Name'), findsOneWidget);
    expect(find.text('Store Name'), findsOneWidget);
    expect(find.text('Price'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
  });
}
