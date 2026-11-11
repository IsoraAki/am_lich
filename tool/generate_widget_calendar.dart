import 'dart:io';

import 'package:am_lich/calendar/lunar_conversion.dart';

void main() {
  final output = StringBuffer();
  final limit = DateTime.utc(2200);
  for (
    var date = DateTime.utc(1899, 12);
    date.isBefore(limit);
    date = date.add(const Duration(days: 1))
  ) {
    final lunar = vietnameseLunarDate(date);
    if (lunar[0] == 1) {
      final day = date.difference(DateTime.utc(1970)).inDays;
      output.writeln('$day,${lunar[1]},${lunar[3]}');
    }
  }
  File('assets/widget_months.csv').writeAsStringSync(output.toString());
}
