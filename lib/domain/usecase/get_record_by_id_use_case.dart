import '../../core/result.dart';
import '../entity/workout_record.dart';
import '../repository/record_repository.dart';

class GetRecordByIdUseCase {
  const GetRecordByIdUseCase(this._recordRepository);

  final RecordRepository _recordRepository;

  Future<Result<WorkoutRecord>> call(String recordId) =>
      _recordRepository.getRecordById(recordId);
}