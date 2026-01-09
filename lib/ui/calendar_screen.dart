import 'package:flutter/material.dart';
import 'package:my_day_one/l10n/app_localizations.dart';
import 'package:table_calendar/table_calendar.dart';

import '../data/entry.dart';
import '../data/entry_repository.dart';
import '../security/app_lock_service.dart';
import 'entry_detail_screen.dart';
import 'entry_list_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    required this.repository,
    required this.appLockService,
  });

  final EntryRepository repository;
  final AppLockService appLockService;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.calendarTitle),
      ),
      body: StreamBuilder<List<Entry>>(
        stream: widget.repository.watchEntries(),
        builder: (context, snapshot) {
          final entries = snapshot.data ?? [];
          final events = _groupEntriesByDay(entries);

          return TableCalendar<Entry>(
            locale: l10n.localeName,
            firstDay: _firstDay(entries),
            lastDay: DateTime.now().add(const Duration(days: 365 * 5)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) =>
                isSameDay(_selectedDay, day),
            eventLoader: (day) =>
                events[DateUtils.dateOnly(day)] ?? const [],
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
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
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
      final day = DateUtils.dateOnly(entry.createdAt);
      map.putIfAbsent(day, () => []).add(entry);
    }
    return map;
  }

  DateTime _firstDay(List<Entry> entries) {
    if (entries.isEmpty) {
      return DateTime.now().subtract(const Duration(days: 365));
    }
    final earliest = entries
        .map((entry) => entry.createdAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    return DateUtils.dateOnly(earliest);
  }

  void _handleDayTap(
    BuildContext context,
    DateTime selectedDay,
    Map<DateTime, List<Entry>> events,
  ) {
    final dayEntries =
        events[DateUtils.dateOnly(selectedDay)] ?? const [];
    if (dayEntries.isEmpty) {
      return;
    }
    if (dayEntries.length == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EntryDetailScreen(
            repository: widget.repository,
            entryId: dayEntries.first.id,
          ),
        ),
      );
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final dateLabel = MaterialLocalizations.of(context).formatFullDate(
      selectedDay,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EntryListScreen(
          repository: widget.repository,
          appLockService: widget.appLockService,
          dayFilter: selectedDay,
          titleOverride: l10n.entriesOnDateTitle(dateLabel),
          showSearch: false,
          showSettingsAction: false,
          showCalendarAction: false,
        ),
      ),
    );
  }
}
