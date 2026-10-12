sealed class GroupDetailEvent {
  const GroupDetailEvent();
}

/// 최초 진입: 그룹 정보 + 오늘 기록 + 오늘 작성 여부 로딩
final class GroupDetailStarted extends GroupDetailEvent {
  const GroupDetailStarted();
}

/// 화살표·달력으로 날짜 변경
final class GroupDetailDateChanged extends GroupDetailEvent {
  const GroupDetailDateChanged(this.date);

  final DateTime date;
}

/// 기록 작성·수정 완료 결과를 받았을 때: 오늘로 이동 + 새로고침
final class GroupDetailRefreshedToToday extends GroupDetailEvent {
  const GroupDetailRefreshedToToday();
}

final class GroupDetailRecordDeleteRequested extends GroupDetailEvent {
  const GroupDetailRecordDeleteRequested(this.recordId);

  final String recordId;
}

final class GroupDetailLeaveRequested extends GroupDetailEvent {
  const GroupDetailLeaveRequested();
}