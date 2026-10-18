import 'package:flutter_test/flutter_test.dart';
import 'package:helpumta_flutter/core/date_utils.dart';
import 'package:helpumta_flutter/core/result.dart';
import 'package:helpumta_flutter/domain/entity/record_exception.dart';
import 'package:helpumta_flutter/domain/repository/auth_repository.dart';
import 'package:helpumta_flutter/domain/repository/record_repository.dart';
import 'package:helpumta_flutter/domain/usecase/create_record_use_case.dart';

class FakeAuthRepository extends Fake implements AuthRepository {
  @override
  String? getCurrentUserId() => 'user1';

  @override
  String? getCurrentUserName() => '진수';
}

/// 오늘 작성 여부를 지정할 수 있고, 저장이 호출됐는지 기록하는 가짜 Repository
class FakeRecordRepository extends Fake implements RecordRepository {
  FakeRecordRepository({required this.alreadyWroteToday});

  final bool alreadyWroteToday;

  DateTime? checkedSince;
  bool createCalled = false;
  String? savedUserName;

  @override
  Future<Result<bool>> hasRecordSince({
    required String groupId,
    required String userId,
    required DateTime since,
  }) async {
    checkedSince = since;
    return Result.ok(alreadyWroteToday);
  }

  @override
  Future<Result<String>> createRecord({
    required String groupId,
    required String userId,
    required String userName,
    required String workoutType,
    required int workoutDuration,
    String? imagePath,
    required String comment,
  }) async {
    createCalled = true;
    savedUserName = userName;
    return const Result.ok('record1');
  }
}

void main() {
  Future<Result<String>> createRecordWith(FakeRecordRepository repository) {
    final useCase = CreateRecordUseCase(repository, FakeAuthRepository());
    return useCase(
      groupId: 'group1',
      workoutType: '헬스',
      workoutDuration: 60,
      comment: '',
    );
  }

  group('CreateRecordUseCase', () {
    test('오늘 이미 작성했으면 저장하지 않고 AlreadyWroteTodayException을 반환한다',
            () async {
          final repository = FakeRecordRepository(alreadyWroteToday: true);

          final result = await createRecordWith(repository);

          expect(
            result,
            isA<Error<String>>().having(
                  (error) => error.error,
              'error',
              isA<AlreadyWroteTodayException>(),
            ),
          );
          // 핵심: 저장 자체가 호출되지 않아야 함
          expect(repository.createCalled, isFalse);
        });

    test('오늘 00:00 이후 기록이 있는지 확인한다', () async {
      final repository = FakeRecordRepository(alreadyWroteToday: false);

      await createRecordWith(repository);

      expect(repository.checkedSince, DateTime.now().startOfDay);
    });

    test('오늘 작성하지 않았으면 현재 사용자 이름으로 저장한다', () async {
      final repository = FakeRecordRepository(alreadyWroteToday: false);

      final result = await createRecordWith(repository);

      expect(result, isA<Ok<String>>());
      expect(repository.createCalled, isTrue);
      expect(repository.savedUserName, '진수');
    });
  });
}