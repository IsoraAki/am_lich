import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'calendar_colors.dart';
import 'calendar_cubit.dart';
import 'calendar_day.dart';

const _paper = Color(0xFFF7F8FA);
const _ink = Color(0xFF263039);
const _red = Color(0xFFAD5039);
const _muted = Color(0xFF69747C);
const _gold = Color(0xFF9B6B17);
const _weekday = _ink;

Color _monthDayColor(DateTime date) =>
    date.weekday >= DateTime.saturday ? _red : _weekday;

ThemeData calendarTheme([Color accent = const Color(0xFF2C6E68)]) => ThemeData(
  useMaterial3: true,
  fontFamily: 'BeVietnamPro',
  scaffoldBackgroundColor: _paper,
  colorScheme: ColorScheme.fromSeed(seedColor: accent, surface: _paper),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: _ink, height: 1.5),
    titleLarge: TextStyle(color: _ink, fontWeight: FontWeight.w600),
  ),
  dividerColor: const Color(0xFFE5E9ED),
  navigationBarTheme: NavigationBarThemeData(
    height: 72,
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    indicatorColor: accent.withValues(alpha: 0.12),
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        color: states.contains(WidgetState.selected) ? accent : _muted,
        size: 23,
      ),
    ),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 11,
        fontWeight: states.contains(WidgetState.selected)
            ? FontWeight.w600
            : FontWeight.normal,
        color: states.contains(WidgetState.selected) ? accent : _muted,
      ),
    ),
  ),
  segmentedButtonTheme: SegmentedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? accent : Colors.white,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? Colors.white : _muted,
      ),
      side: const WidgetStatePropertyAll(BorderSide.none),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'BeVietnamPro',
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    ),
  ),
);

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<CalendarCubit>().refreshToday();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CalendarCubit, CalendarState>(
        builder: (context, state) {
          final cubit = context.read<CalendarCubit>();
          final accent = state.page == CalendarPage.month
              ? _red
              : calendarDayColor(state.selected.solar);
          final reduceMotion = MediaQuery.disableAnimationsOf(context);
          return AnimatedTheme(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 200),
            data: calendarTheme(accent),
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: _paper,
                surfaceTintColor: Colors.transparent,
                systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: Colors.white,
                ),
                title: const Text(
                  'Âm Lịch',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.8,
                    fontSize: 24,
                  ),
                ),
                actions: [
                  TextButton.icon(
                    onPressed: cubit.goToday,
                    icon: const Icon(Icons.today_outlined, size: 18),
                    label: const Text('Hôm nay'),
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      backgroundColor: accent.withValues(alpha: 0.08),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
              body: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: AnimatedSwitcher(
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      child: state.page == CalendarPage.day
                          ? _DayPage(key: const ValueKey('day'), state: state)
                          : _MonthPage(
                              key: const ValueKey('month'),
                              state: state,
                            ),
                    ),
                  ),
                ),
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: state.page.index,
                onDestinationSelected: (index) =>
                    cubit.show(CalendarPage.values[index]),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.wb_sunny_outlined),
                    selectedIcon: Icon(Icons.wb_sunny),
                    label: 'Lịch ngày',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    selectedIcon: Icon(Icons.calendar_month),
                    label: 'Lịch tháng',
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class _DayPage extends StatelessWidget {
  const _DayPage({super.key, required this.state});
  final CalendarState state;

  @override
  Widget build(BuildContext context) {
    final day = state.selected;
    final accent = calendarDayColor(day.solar);
    final cubit = context.read<CalendarCubit>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      children: [
        _DateNavigation(
          title: day.solar == state.today ? 'HÔM NAY' : 'LỊCH NGÀY',
          previous: day.solar.isAfter(CalendarCubit.firstDay)
              ? () => cubit.changeDay(-1)
              : null,
          next: day.solar.isBefore(CalendarCubit.lastDay)
              ? () => cubit.changeDay(1)
              : null,
        ),
        const SizedBox(height: 16),
        AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
          child: Column(
            children: [
              Text(
                day.weekday.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  letterSpacing: 2,
                  fontSize: 13,
                ),
              ),
              AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                child: Text(
                  twoDigits(day.day),
                  key: ValueKey(day.solar),
                  style: const TextStyle(
                    fontSize: 118,
                    height: 1.25,
                    color: _paper,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -10,
                  ),
                ),
              ),
              Text(
                '${day.lunarMonth.toUpperCase()} · ${day.year}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _paper,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white30),
              const SizedBox(height: 10),
              Text(
                'Năm ${day.yearCanChi}',
                style: const TextStyle(color: _paper, fontSize: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'DƯƠNG LỊCH',
              style: TextStyle(color: _muted, fontSize: 11, letterSpacing: 2),
            ),
            Text(
              day.solarLabel,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        Wrap(
          spacing: 36,
          runSpacing: 16,
          children: [
            _Detail(label: 'Can Chi ngày', value: day.dayCanChi),
            _Detail(label: 'Can Chi tháng', value: day.monthCanChi),
            _Detail(
              label: 'Lịch ngày',
              value: day.dayType,
              color: day.isAuspicious ? _gold : _muted,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Giờ hoàng đạo',
          style: TextStyle(
            color: _ink,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: day.auspiciousHours
              .map(
                (hour) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    hour,
                    style: TextStyle(fontSize: 12, color: accent),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 28),
        const Divider(),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () async {
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
              final requested = await const MethodChannel('am_lich/widget')
                  .invokeMethod<bool>('requestPin');
              if (requested == true || !context.mounted) return;
            }
            if (!context.mounted) return;
            await showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (_) => const SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Âm lịch trên màn hình chính',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Android\nNhấn giữ màn hình chính → Tiện ích → Âm Lịch, rồi kéo tiện ích ra màn hình.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        'iPhone\nNhấn giữ màn hình chính → Sửa → Thêm tiện ích → Âm Lịch.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Widget tự hiển thị ngày hiện tại theo giờ Việt Nam. Chạm widget để mở ứng dụng.',
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          icon: const Icon(Icons.widgets_outlined, size: 20),
          label: const Text('Thêm tiện ích màn hình chính'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Âm lịch Việt Nam · UTC+7\nHoàng đạo, hắc đạo theo lịch pháp truyền thống.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 11),
        ),
      ],
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value, this.color = _ink});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
      const SizedBox(height: 6),
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _DateNavigation extends StatelessWidget {
  const _DateNavigation({
    required this.title,
    required this.previous,
    required this.next,
  });
  final String title;
  final VoidCallback? previous;
  final VoidCallback? next;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: 'Trước',
        onPressed: previous,
        style: IconButton.styleFrom(backgroundColor: Colors.white),
        icon: const Icon(Icons.chevron_left),
      ),
      Expanded(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      IconButton(
        tooltip: 'Sau',
        onPressed: next,
        style: IconButton.styleFrom(backgroundColor: Colors.white),
        icon: const Icon(Icons.chevron_right),
      ),
    ],
  );
}

class _MonthPage extends StatelessWidget {
  const _MonthPage({super.key, required this.state});
  final CalendarState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CalendarCubit>();
    final selected = state.selected;
    final lunar = state.lunarPrimary;
    final start = selected.monthStart(lunar: lunar);
    final end = selected.nextMonth(lunar: lunar);
    final offset = start.weekday - 1;
    final count = end.difference(start).inDays;
    final cells = ((count + offset) / 7).ceil() * 7;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Align(
          child: SegmentedButton<bool>(
            expandedInsets: EdgeInsets.zero,
            segments: const [
              ButtonSegment(value: true, label: Text('Âm lịch')),
              ButtonSegment(value: false, label: Text('Dương lịch')),
            ],
            selected: {lunar},
            onSelectionChanged: (_) => cubit.toggleMode(),
            showSelectedIcon: false,
          ),
        ),
        const SizedBox(height: 16),
        _DateNavigation(
          title: lunar
              ? '${selected.lunarMonth} · ${selected.year}'
              : 'Tháng ${selected.solar.month} · ${selected.solar.year}',
          previous: start.isAfter(CalendarCubit.firstDay)
              ? () => cubit.changeMonth(-1)
              : null,
          next: end.isBefore(CalendarCubit.lastDay)
              ? () => cubit.changeMonth(1)
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          lunar
              ? 'Âm lịch · Năm ${selected.yearCanChi}'
              : 'Dương lịch · Ngày âm hiển thị bên dưới',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            for (final name in ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'])
              Expanded(
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: name == 'T7' || name == 'CN' ? _red : _muted,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final height = 70.0 * textScale.clamp(1.0, 2.5);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cells,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: height,
              ),
              itemBuilder: (context, index) {
                final number = index - offset;
                if (number < 0 || number >= count) {
                  return const SizedBox.shrink();
                }
                final date = start.add(Duration(days: number));
                if (date.isBefore(CalendarCubit.firstDay) ||
                    date.isAfter(CalendarCubit.lastDay)) {
                  return const SizedBox.shrink();
                }
                final day = CalendarDay(date);
                return _DayCell(
                  day: day,
                  lunar: lunar,
                  selected: date == selected.solar,
                  today: date == state.today,
                  onTap: () => cubit.select(date),
                );
              },
            );
          },
        ),
        const SizedBox(height: 14),
        const Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 8,
          children: [
            _Legend(color: _gold, label: 'Hoàng đạo'),
            _Legend(color: _muted, label: 'Hắc đạo'),
          ],
        ),
        const SizedBox(height: 20),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              '${selected.day}/${selected.month} âm lịch'
              '${selected.leap ? ' · Tháng nhuận' : ''}',
            ),
            subtitle: Text(
              '${selected.weekday}, ${selected.solarLabel}\n'
              'Ngày ${selected.dayCanChi} · ${selected.dayType}',
            ),
            isThreeLine: true,
            leading: Container(
              width: 46,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _monthDayColor(selected.solar).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                twoDigits(selected.day),
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w600,
                  color: _monthDayColor(selected.solar),
                ),
              ),
            ),
            titleTextStyle: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _ink,
            ),
            subtitleTextStyle: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 11,
              height: 1.7,
              color: _muted,
            ),
            trailing: const Icon(Icons.arrow_forward, size: 20),
            onTap: () => cubit.select(selected.solar, openDay: true),
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.lunar,
    required this.selected,
    required this.today,
    required this.onTap,
  });
  final CalendarDay day;
  final bool lunar;
  final bool selected;
  final bool today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? _red : _monthDayColor(day.solar);
    final primary = lunar ? day.day : day.solar.day;
    final secondary = lunar
        ? '${day.solar.day}/${day.solar.month}'
        : '${day.day}${day.day == 1 ? '/${day.month}' : ''}';
    return Semantics(
      label:
          '${day.solarLabel}, âm lịch ${day.day}/${day.month}'
          '${day.leap ? ' nhuận' : ''}, ${day.dayType}${today ? ', hôm nay' : ''}',
      selected: selected,
      button: true,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: selected ? accent : accent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: today ? Border.all(color: accent, width: 2) : null,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onTap,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$primary',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : accent,
                      ),
                    ),
                    Text(
                      secondary,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 9,
                        color: selected ? Colors.white : _muted,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Icon(
                      day.isAuspicious
                          ? Icons.star_rounded
                          : Icons.circle_outlined,
                      size: 9,
                      color: selected
                          ? Colors.white
                          : (day.isAuspicious ? _gold : _muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        label == 'Hoàng đạo' ? Icons.star_rounded : Icons.circle_outlined,
        size: 12,
        color: color,
      ),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
    ],
  );
}
