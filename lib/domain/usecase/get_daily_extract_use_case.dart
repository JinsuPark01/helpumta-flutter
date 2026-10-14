import '../../core/date_utils.dart';
import '../../core/result.dart';
import '../entity/extract_slot.dart';
import '../entity/workout_record.dart';
import '../repository/group_repository.dart';
import '../repository/record_repository.dart';
import '../repository/user_repository.dart';

class GetDailyExtractUseCase {
  const GetDailyExtractUseCase(
      this._groupRepository,
      this._recordRepository,
      this._userRepository,
      );

  final GroupRepository _groupRepository;
  final RecordRepository _recordRepository;
  final UserRepository _userRepository;

  /// 기록한 멤버 칸이 먼저, 기록하지 않은 멤버(💤) 칸이 뒤에
  Future<Result<List<ExtractSlot>>> call({
    required String groupId,
    required DateTime date,
  }) async {
    final start = date.startOfDay;

    // 1, 2. 그날 기록과 그룹 멤버를 동시에 조회
    final (recordsResult, membersResult) = await (
    _recordRepository.getRecordsByGroup(
      groupId: groupId,
      start: start,
      end: start.addDays(1),
    ),
    _groupRepository.getMemberIds(groupId),
    ).wait;

    // switch 표현식 안에선 return을 쓸 수 없어서 switch 문으로 값을 꺼냄
    final List<WorkoutRecord> records;
    switch (recordsResult) {
      case Ok(:final value):
        records = value;
      case Error(:final error):
        return Result.error(error);
    }

    final List<String> memberIds;
    switch (membersResult) {
      case Ok(:final value):
        memberIds = value;
      case Error(:final error):
        return Result.error(error);
    }

    // 3, 4. 기록하지 않은 멤버
    final recordedUserIds = records.map((record) => record.userId).toSet();
    final missingIds =
    memberIds.where((id) => !recordedUserIds.contains(id)).toList();

    // 5. 기록하지 않은 멤버의 닉네임
    final Map<String, String> missingNicknames;
    if (missingIds.isEmpty) {
      missingNicknames = const {};
    } else {
      final nicknamesResult = await _userRepository.getNicknames(missingIds);
      switch (nicknamesResult) {
        case Ok(:final value):
          missingNicknames = value;
        case Error(:final error):
          return Result.error(error);
      }
    }

    // 6. 칸 목록 조립
    final recordedSlots = records.map(
          (record) => RecordedSlot(
        nickname: record.userName,
        workoutType: record.workoutType,
        workoutDuration: record.workoutDuration,
        comment: record.comment,
        imageUrl: record.imageUrl,
      ),
    );
    final emptySlots = missingIds.map(
          (uid) => EmptySlot(nickname: missingNicknames[uid] ?? '알 수 없음'),
    );

    return Result.ok([...recordedSlots, ...emptySlots]);
  }
}