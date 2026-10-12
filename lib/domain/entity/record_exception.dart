/// 오늘 이미 기록을 작성함 (하루 한 번 규칙)
class AlreadyWroteTodayException implements Exception {
  const AlreadyWroteTodayException();
}

/// 작성한 날이 지나 수정할 수 없음 (당일 수정 규칙)
class RecordEditExpiredException implements Exception {
  const RecordEditExpiredException();
}