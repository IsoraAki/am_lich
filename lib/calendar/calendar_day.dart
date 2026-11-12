import 'package:vnlunar/vnlunar.dart';

import 'lunar_conversion.dart';

const weekdays = [
  'Thứ Hai',
  'Thứ Ba',
  'Thứ Tư',
  'Thứ Năm',
  'Thứ Sáu',
  'Thứ Bảy',
  'Chủ nhật',
];
const _stems = [
  'Giáp',
  'Ất',
  'Bính',
  'Đinh',
  'Mậu',
  'Kỷ',
  'Canh',
  'Tân',
  'Nhâm',
  'Quý',
];
const _branches = [
  'Tý',
  'Sửu',
  'Dần',
  'Mão',
  'Thìn',
  'Tỵ',
  'Ngọ',
  'Mùi',
  'Thân',
  'Dậu',
  'Tuất',
  'Hợi',
];

String twoDigits(int value) => value.toString().padLeft(2, '0');

DateTime vietnamTime(DateTime instant) =>
    instant.toUtc().add(const Duration(hours: 7));

DateTime vietnamDate(DateTime instant) {
  final local = vietnamTime(instant);
  return DateTime.utc(local.year, local.month, local.day);
}

const _solarHolidays = {
  (1, 1): 'Tết Dương lịch',
  (3, 8): 'Ngày Quốc tế Phụ nữ',
  (4, 30): 'Ngày Giải phóng miền Nam, thống nhất đất nước',
  (5, 1): 'Ngày Quốc tế Lao động',
  (6, 1): 'Ngày Quốc tế Thiếu nhi',
  (9, 2): 'Quốc khánh Việt Nam',
  (10, 20): 'Ngày Phụ nữ Việt Nam',
  (11, 20): 'Ngày Nhà giáo Việt Nam',
  (12, 25): 'Lễ Giáng sinh',
};

const _lunarHolidays = {
  (1, 1): 'Mùng 1 Tết Nguyên đán',
  (1, 2): 'Mùng 2 Tết Nguyên đán',
  (1, 3): 'Mùng 3 Tết Nguyên đán',
  (1, 15): 'Tết Nguyên tiêu',
  (3, 10): 'Giỗ Tổ Hùng Vương',
  (4, 15): 'Lễ Phật đản',
  (5, 5): 'Tết Đoan Ngọ',
  (7, 15): 'Lễ Vu Lan',
  (8, 15): 'Tết Trung thu',
  (12, 23): 'Ông Công, ông Táo',
};

class CalendarDay {
  factory CalendarDay(DateTime solar) {
    final lunar = vietnameseLunarDate(solar);
    return CalendarDay._(solar, lunar[0], lunar[1], lunar[2], lunar[3] == 1);
  }

  const CalendarDay._(this.solar, this.day, this.month, this.year, this.leap);

  final DateTime solar;
  final int day;
  final int month;
  final int year;
  final bool leap;

  static const _auspicious = {0, 1, 4, 5, 7, 10};

  int get _julian => jdFromDate(solar.day, solar.month, solar.year);
  int get _dayBranch => (_julian + 1) % 12;
  bool get isAuspicious =>
      _auspicious.contains((_dayBranch - 2 * (month - 1)) % 12);
  String get dayType => isAuspicious ? 'Hoàng đạo' : 'Hắc đạo';
  String get weekday => weekdays[solar.weekday - 1];
  String get lunarMonth => 'Tháng $month${leap ? ' nhuận' : ''}';
  String get solarLabel =>
      '${twoDigits(solar.day)}/${twoDigits(solar.month)}/${solar.year}';

  List<String> get holidays {
    final solarHoliday = _solarHolidays[(solar.month, solar.day)];
    final lunarHoliday = leap ? null : _lunarHolidays[(month, day)];
    return [
      ?solarHoliday,
      if (solar.year >= 2026 && solar.month == 11 && solar.day == 24)
        'Ngày Văn hóa Việt Nam',
      ?lunarHoliday,
      if (month == 12 &&
          day >= 29 &&
          CalendarDay(solar.add(const Duration(days: 1))).month == 1)
        'Giao thừa Tết Nguyên đán',
    ];
  }

  String get dayCanChi => _canChi(_julian + 9, _dayBranch);
  String get monthCanChi => _canChi(year * 12 + month + 3, month + 1);
  String get yearCanChi => _canChi(year + 6, year + 8);
  String _canChi(int stem, int branch) =>
      '${_stems[stem % 10]} ${_branches[branch % 12]}';

  Iterable<String> get auspiciousHours sync* {
    final start = 2 * (_dayBranch - 2);
    for (var branch = 0; branch < 12; branch++) {
      if (_auspicious.contains((branch - start) % 12)) {
        yield '${_branches[branch]} ${twoDigits((2 * branch - 1) % 24)}–${twoDigits((2 * branch + 1) % 24)}h';
      }
    }
  }

  DateTime monthStart({required bool lunar}) => lunar
      ? solar.subtract(Duration(days: day - 1))
      : DateTime.utc(solar.year, solar.month);

  DateTime nextMonth({required bool lunar}) {
    if (!lunar) return DateTime.utc(solar.year, solar.month + 1);
    final candidate = monthStart(lunar: true).add(const Duration(days: 29));
    return CalendarDay(candidate).day == 1
        ? candidate
        : candidate.add(const Duration(days: 1));
  }
}
