import 'package:flutter_test/flutter_test.dart';

import 'package:helpumta_flutter/app/app.dart';

void main() {
  testWidgets('앱 시작 시 로그인 화면이 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(const HelpumtaApp());
    await tester.pumpAndSettle();

    expect(find.text('로그인'), findsOneWidget);
  });
}