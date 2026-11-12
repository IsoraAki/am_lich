import 'dart:io';

import 'package:am_lich/calendar/calendar_cubit.dart';
import 'package:am_lich/calendar/calendar_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('holidays follow solar dates and regular lunar months', () {
    expect(
      CalendarDay(DateTime.utc(2026, 9, 2)).holidays,
      contains('Quốc khánh Việt Nam'),
    );
    expect(
      CalendarDay(DateTime.utc(2024, 4, 18)).holidays,
      contains('Giỗ Tổ Hùng Vương'),
    );
    expect(
      CalendarDay(DateTime.utc(2025, 1, 28)).holidays,
      contains('Giao thừa Tết Nguyên đán'),
    );
    expect(
      CalendarDay(DateTime.utc(2024, 2, 9)).holidays,
      contains('Giao thừa Tết Nguyên đán'),
    );
    expect(
      CalendarDay(DateTime.utc(2020, 5, 7)).holidays,
      contains('Lễ Phật đản'),
    );
    expect(
      CalendarDay(DateTime.utc(2025, 11, 24)).holidays,
      isNot(contains('Ngày Văn hóa Việt Nam')),
    );
    expect(
      CalendarDay(DateTime.utc(2026, 11, 24)).holidays,
      contains('Ngày Văn hóa Việt Nam'),
    );
    final leapMonth = CalendarDay(DateTime.utc(2020, 6, 6));
    expect([leapMonth.day, leapMonth.month, leapMonth.leap], [15, 4, true]);
    expect(leapMonth.holidays, isNot(contains('Lễ Phật đản')));
  });

  test('Vietnamese new year fixtures and leap month', () {
    for (final date in [
      DateTime.utc(2007, 2, 17),
      DateTime.utc(2023, 1, 22),
      DateTime.utc(2024, 2, 10),
      DateTime.utc(2025, 1, 29),
      DateTime.utc(2026, 2, 17),
    ]) {
      final day = CalendarDay(date);
      expect(
        [day.day, day.month, day.year, day.leap],
        [1, 1, date.year, false],
      );
    }
    final leap = CalendarDay(DateTime.utc(2023, 3, 22));
    expect([leap.day, leap.month, leap.leap], [1, 2, true]);
    expect(leap.nextMonth(lunar: true), DateTime.utc(2023, 4, 20));
    expect(
      CalendarDay(DateTime.utc(2023, 2, 20)).nextMonth(lunar: true),
      DateTime.utc(2023, 3, 22),
    );
  });

  test('estimated new moon boundary never returns lunar day zero', () {
    final before = CalendarDay(DateTime.utc(2054, 5, 7));
    final after = CalendarDay(DateTime.utc(2054, 5, 8));
    expect([before.day, before.month], [30, 3]);
    expect([after.day, after.month], [1, 4]);
  });

  test('Can Chi and traditional day/hour classifications', () {
    final day = CalendarDay(DateTime.utc(2024, 2, 10));
    expect(day.yearCanChi, 'Giáp Thìn');
    expect(day.monthCanChi, 'Bính Dần');
    expect(day.dayCanChi, 'Giáp Thìn');
    expect(day.isAuspicious, isTrue);
    expect(day.auspiciousHours.length, 6);
    final days = List.generate(
      12,
      (index) => CalendarDay(DateTime.utc(2024, 2, 10 + index)),
    );
    expect(days.where((day) => day.isAuspicious).length, 6);
    expect(days.every((day) => day.auspiciousHours.length == 6), isTrue);
  });

  test('widget month data matches runtime calendar for all supported days', () {
    final rows = File('assets/widget_months.csv')
        .readAsLinesSync()
        .map((row) => row.split(',').map(int.parse).toList())
        .toList();
    var index = 0;
    for (
      var date = CalendarCubit.firstDay;
      !date.isAfter(CalendarCubit.lastDay);
      date = date.add(const Duration(days: 1))
    ) {
      final epochDay = date.difference(DateTime.utc(1970)).inDays;
      while (index + 1 < rows.length && rows[index + 1][0] <= epochDay) {
        index++;
      }
      final lunar = CalendarDay(date);
      expect(lunar.day, inInclusiveRange(1, 30));
      expect(lunar.month, inInclusiveRange(1, 12));
      if (epochDay == rows[index][0] && index > 0) {
        expect(rows[index][0] - rows[index - 1][0], anyOf(29, 30));
      }
      expect(
        [epochDay - rows[index][0] + 1, rows[index][1], rows[index][2] == 1],
        [lunar.day, lunar.month, lunar.leap],
        reason: date.toIso8601String(),
      );
    }
  });

  test(
    'Cubit follows lunar leap months, switches mode and persists it',
    () async {
      bool? saved;
      final cubit = CalendarCubit(
        lunarPrimary: true,
        saveMode: (value) async {
          saved = value;
        },
        clock: () => DateTime.utc(2023, 2, 20, 12),
      );
      addTearDown(cubit.close);
      cubit.changeMonth(1);
      expect(cubit.state.selected.leap, isTrue);
      cubit.changeMonth(1);
      expect(cubit.state.selected.month, 3);
      cubit.changeMonth(-1);
      expect(cubit.state.selected.leap, isTrue);
      await cubit.toggleMode();
      expect(saved, isFalse);
      expect(cubit.state.selected.solar, DateTime.utc(2023, 3, 22));
      cubit.goToday();
      expect(cubit.state.selected.solar, DateTime.utc(2023, 2, 20));
    },
  );

  test(
    'Vietnam midnight updates today and preserves a manually selected day',
    () async {
      var now = DateTime.utc(2026, 11, 11, 16, 59);
      final cubit = CalendarCubit(
        lunarPrimary: true,
        saveMode: (_) async {},
        clock: () => now,
      );
      addTearDown(cubit.close);
      now = DateTime.utc(2026, 11, 11, 17);
      cubit.refreshToday();
      expect(cubit.state.today, DateTime.utc(2026, 11, 12));
      expect(cubit.state.selected.solar, cubit.state.today);
      cubit.select(DateTime.utc(2026, 2, 17));
      now = now.add(const Duration(days: 1));
      cubit.refreshToday();
      expect(cubit.state.today, DateTime.utc(2026, 11, 13));
      expect(cubit.state.selected.solar, DateTime.utc(2026, 2, 17));
      cubit.select(DateTime.utc(1800));
      expect(cubit.state.selected.solar, CalendarCubit.firstDay);
      cubit.select(DateTime.utc(2300));
      expect(cubit.state.selected.solar, CalendarCubit.lastDay);
    },
  );
}
