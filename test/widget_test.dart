import 'package:flutter_test/flutter_test.dart';

import 'package:helpumta_flutter/main.dart';

void main() {
  testWidgets('앱 시작 시 연결 확인 문구가 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(const HelpumtaApp());

    expect(find.text('Firebase 연결 완료'), findsOneWidget);
  });
}