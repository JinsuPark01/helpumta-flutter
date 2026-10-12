extension DateOnly on DateTime {
  /// 로컬 기준 그 날짜의 00:00
  DateTime get startOfDay => DateTime(year, month, day);

  /// 날짜 단위 이동. 결과는 이동한 날의 00:00 (월말·서머타임 자동 처리)
  DateTime addDays(int days) => DateTime(year, month, day + days);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}