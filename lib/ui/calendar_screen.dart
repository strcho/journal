import 'package:flutter/material.dart';
import 'package:my_day_one/l10n/app_localizations.dart';
import 'package:table_calendar/table_calendar.dart';

import '../data/entry.dart';
import '../data/entry_repository.dart';
import '../data/journal_repository.dart';
import '../security/app_lock_service.dart';
import 'entry_detail_screen.dart';
import 'entry_list_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    required this.repository,
    required this.journalRepository,
    required this.appLockService,
  });

  final EntryRepository repository;
  final JournalRepository journalRepository;
  final AppLockService appLockService;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final DateTime _todayUtc;
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _todayUtc = _normalizeCalendarDay(DateTime.now());
    _focusedDay = _todayUtc;
    _selectedDay = _todayUtc;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.calendarTitle)),
      body: StreamBuilder<List<Entry>>(
        stream: widget.repository.watchEntries(),
        builder: (context, snapshot) {
          final entries = snapshot.data ?? [];
          final events = _groupEntriesByDay(entries);
          final firstDay = _firstDay(entries);
          final lastDay = _lastDay();
          final clampedFocusedDay = _clampDay(_focusedDay, firstDay, lastDay);
          final clampedSelectedDay = _clampDay(_selectedDay, firstDay, lastDay);

          return TableCalendar<Entry>(
            key: ValueKey(
              '${firstDay.toIso8601String()}-${lastDay.toIso8601String()}',
            ),
            locale: l10n.localeName,
            firstDay: firstDay,
            lastDay: lastDay,
            focusedDay: clampedFocusedDay,
            currentDay: _todayUtc,
            startingDayOfWeek: StartingDayOfWeek.monday,
            selectedDayPredicate: (day) => isSameDay(clampedSelectedDay, day),
            eventLoader: (day) =>
                events[_normalizeCalendarDay(day)] ?? const [],
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarBuilders: CalendarBuilders<Entry>(
              markerBuilder: (context, day, dayEntries) {
                if (dayEntries.isEmpty) {
                  return null;
                }
                final count = dayEntries.length;
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = _normalizeCalendarDay(selectedDay);
                _focusedDay = _normalizeCalendarDay(focusedDay);
              });
              _handleDayTap(context, selectedDay, events);
            },
          );
        },
      ),
    );
  }

  Map<DateTime, List<Entry>> _groupEntriesByDay(List<Entry> entries) {
    final map = <DateTime, List<Entry>>{};
    for (final entry in entries) {
      final day = _normalizeCalendarDay(entry.createdAt);
      map.putIfAbsent(day, () => []).add(entry);
    }
    return map;
  }

  DateTime _firstDay(List<Entry> entries) {
    if (entries.isEmpty) {
      final now = DateTime.now();
      return DateTime.utc(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 365));
    }
    final earliest = entries
        .map((entry) => entry.createdAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    return _normalizeCalendarDay(earliest);
  }

  void _handleDayTap(
    BuildContext context,
    DateTime selectedDay,
    Map<DateTime, List<Entry>> events,
  ) {
    final normalizedDay = _normalizeCalendarDay(selectedDay);
    final dayEntries = events[normalizedDay] ?? const [];
    if (dayEntries.isEmpty) {
      return;
    }
    if (dayEntries.length == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EntryDetailScreen(
            repository: widget.repository,
            journalRepository: widget.journalRepository,
            entryId: dayEntries.first.id,
          ),
        ),
      );
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final dateLabel = MaterialLocalizations.of(
      context,
    ).formatFullDate(selectedDay);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EntryListScreen(
          repository: widget.repository,
          journalRepository: widget.journalRepository,
          appLockService: widget.appLockService,
          dayFilter: normalizedDay,
          titleOverride: l10n.entriesOnDateTitle(dateLabel),
          showSearch: false,
          showSettingsAction: false,
          showCalendarAction: false,
        ),
      ),
    );
  }

  DateTime _clampDay(DateTime day, DateTime first, DateTime last) {
    if (day.isBefore(first)) {
      return first;
    }
    if (day.isAfter(last)) {
      return last;
    }
    return day;
  }

  DateTime _lastDay() {
    return _todayUtc.add(const Duration(days: 365 * 5));
  }

  DateTime _normalizeCalendarDay(DateTime date) {
    // TableCalendar normalizes all dates to UTC; mirror that for our lookup keys.
    return DateTime.utc(date.year, date.month, date.day);
  }
}
