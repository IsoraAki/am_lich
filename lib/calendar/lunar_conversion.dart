import 'package:vnlunar/vnlunar.dart';

/// Vietnamese lunar conversion using vnlunar's astronomical primitives at UTC+7.
/// Search both sides of the estimated lunation so a boundary never yields day 0.
List<int> vietnameseLunarDate(DateTime solar) {
  final julian = jdFromDate(solar.day, solar.month, solar.year);
  var lunation = ((julian - 2415021.076998695) / 29.530588853).floor();
  while (getNewMoonDay(lunation, 7) > julian) {
    lunation--;
  }
  while (getNewMoonDay(lunation + 1, 7) <= julian) {
    lunation++;
  }
  final start = getNewMoonDay(lunation, 7);
  var month11 = getLunarMonth11(solar.year, 7);
  var nextMonth11 = month11;
  var year = solar.year;
  if (start < month11) {
    month11 = getLunarMonth11(solar.year - 1, 7);
  } else {
    year++;
    nextMonth11 = getLunarMonth11(solar.year + 1, 7);
  }
  final offset = ((start - month11) / 29).floor();
  var month = offset + 11;
  var leap = 0;
  if (nextMonth11 - month11 > 365) {
    final leapOffset = getLeapMonthOffset(month11, 7);
    if (offset >= leapOffset) {
      month--;
      if (offset == leapOffset) leap = 1;
    }
  }
  if (month > 12) month -= 12;
  if (month >= 11 && offset < 4) year--;
  return [julian - start + 1, month, year, leap];
}
