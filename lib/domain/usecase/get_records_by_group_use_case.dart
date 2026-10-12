import '../../core/date_utils.dart';
import '../../core/result.dart';
import '../entity/workout_record.dart';
import '../repository/record_repository.dart';

class GetRecordsByGroupUseCase {
  const GetRecordsByGroupUseCase(this._recordRepository);

  final RecordRepository _recordRepository;

  /// [date]가 속한 하루(00:00 ~ 다음날 00:00)의 기록
  Future<Result<List<WorkoutRecord>>> call({
    required String groupId,
    required DateTime date,
  }) {
    final start = date.startOfDay;
    return _recordRepository.getRecordsByGroup(
      groupId: groupId,
      start: start,
      end: start.addDays(1),
    );
  }
}