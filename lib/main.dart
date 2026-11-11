import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'calendar/calendar_cubit.dart';
import 'calendar/calendar_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(
    CalendarApp(
      lunarPrimary: preferences.getBool('lunarPrimary') ?? true,
      saveMode: (value) async {
        await preferences.setBool('lunarPrimary', value);
      },
    ),
  );
}

class CalendarApp extends StatelessWidget {
  const CalendarApp({
    super.key,
    required this.lunarPrimary,
    required this.saveMode,
    this.clock,
  });

  final bool lunarPrimary;
  final Future<void> Function(bool) saveMode;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Âm Lịch',
    debugShowCheckedModeBanner: false,
    theme: calendarTheme(),
    home: BlocProvider(
      create: (_) => CalendarCubit(
        lunarPrimary: lunarPrimary,
        saveMode: saveMode,
        clock: clock,
      ),
      child: const CalendarView(),
    ),
  );
}
