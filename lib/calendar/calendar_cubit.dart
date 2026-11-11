import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'calendar_day.dart';

enum CalendarPage { day, month }

class CalendarState {
  const CalendarState({
    required this.today,
    required this.selected,
    required this.lunarPrimary,
    this.page = CalendarPage.day,
  });

  final DateTime today;
  final CalendarDay selected;
  final bool lunarPrimary;
  final CalendarPage page;

  CalendarState copyWith({
    DateTime? today,
    CalendarDay? selected,
    bool? lunarPrimary,
    CalendarPage? page,
  }) => CalendarState(
    today: today ?? this.today,
    selected: selected ?? this.selected,
    lunarPrimary: lunarPrimary ?? this.lunarPrimary,
    page: page ?? this.page,
  );
}

class CalendarCubit extends Cubit<CalendarState> {
  CalendarCubit({
    required bool lunarPrimary,
    required this.saveMode,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(_initialState(clock ?? DateTime.now, lunarPrimary)) {
    refreshToday();
  }

  static final firstDay = DateTime.utc(1900);
  static final lastDay = DateTime.utc(2199, 12, 31);

  static CalendarState _initialState(DateTime Function() clock, bool lunar) {
    final today = vietnamDate(clock());
    return CalendarState(
      today: today,
      selected: CalendarDay(_supportedDate(today)),
      lunarPrimary: lunar,
    );
  }

  final DateTime Function() _clock;
  final Future<void> Function(bool) saveMode;
  Timer? _midnight;

  static DateTime _supportedDate(DateTime date) {
    if (date.isBefore(firstDay)) return firstDay;
    if (date.isAfter(lastDay)) return lastDay;
    return date;
  }

  void refreshToday() {
    final now = vietnamTime(_clock());
    final today = DateTime.utc(now.year, now.month, now.day);
    if (today != state.today) {
      final followingToday = state.selected.solar == state.today;
      emit(
        state.copyWith(
          today: today,
          selected: followingToday ? CalendarDay(_supportedDate(today)) : null,
        ),
      );
    }
    _midnight?.cancel();
    final midnight = today.add(const Duration(days: 1));
    _midnight = Timer(midnight.difference(now), refreshToday);
  }

  void show(CalendarPage page) => emit(state.copyWith(page: page));

  void goToday() => select(state.today);

  void select(DateTime date, {bool openDay = false}) => emit(
    state.copyWith(
      selected: CalendarDay(_supportedDate(date)),
      page: openDay ? CalendarPage.day : null,
    ),
  );

  void changeDay(int delta) =>
      select(state.selected.solar.add(Duration(days: delta)));

  void changeMonth(int delta) {
    final lunar = state.lunarPrimary;
    final date = delta > 0
        ? state.selected.nextMonth(lunar: lunar)
        : state.selected
              .monthStart(lunar: lunar)
              .subtract(const Duration(days: 1));
    final first = CalendarDay(date).monthStart(lunar: lunar);
    select(first);
  }

  Future<void> toggleMode() async {
    final lunar = !state.lunarPrimary;
    emit(state.copyWith(lunarPrimary: lunar));
    await saveMode(lunar);
  }

  @override
  Future<void> close() {
    _midnight?.cancel();
    return super.close();
  }
}
