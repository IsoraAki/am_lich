import 'package:flutter/material.dart';

const _dayColors = [
  Color(0xFF2C6E68),
  Color(0xFF4D5F9E),
  Color(0xFF92516E),
  Color(0xFFAD5039),
  Color(0xFF527448),
  Color(0xFF715690),
];

/// A stable daily shuffle, shared with the native home-screen widgets.
Color calendarDayColor(DateTime date) {
  final day = DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime.utc(1970)).inDays;
  final shuffled = (day * 37) ^ (day >> 3) ^ (day >> 5);
  return _dayColors[shuffled % _dayColors.length];
}
