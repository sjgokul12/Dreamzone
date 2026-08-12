import 'package:flutter_test/flutter_test.dart';
import 'package:dreamzoneapp/main.dart';
import 'package:dreamzoneapp/providers/auth_provider.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    final authProvider = AuthProvider();
    await tester.pumpWidget(DZIApp(authProvider: authProvider));
    await tester.pump();
    expect(find.byType(DZIApp), findsOneWidget);
  });
}
