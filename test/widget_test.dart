import 'package:flutter_test/flutter_test.dart';

import 'package:helpumta_flutter/app/app.dart';
import 'package:helpumta_flutter/domain/repository/auth_repository.dart';
import 'package:helpumta_flutter/domain/repository/user_repository.dart';

/// 로그아웃 상태를 흉내 내는 가짜 Repository
class FakeAuthRepository extends Fake implements AuthRepository {
  @override
  String? getCurrentUserId() => null;
}

class FakeUserRepository extends Fake implements UserRepository {}

void main() {
  testWidgets('로그아웃 상태로 시작하면 로그인 화면으로 이동한다', (tester) async {
    await tester.pumpWidget(
      HelpumtaApp(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('이메일'), findsOneWidget);
  });
}