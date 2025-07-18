import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orya/features/dashboard/application/gamification_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:orya/core/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityCalendarPage extends ConsumerStatefulWidget {
  const ActivityCalendarPage({super.key});

  @override
  ConsumerState<ActivityCalendarPage> createState() => _ActivityCalendarPageState();
}

class _ActivityCalendarPageState extends ConsumerState<ActivityCalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _firstDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Fetch all activities when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserCreationDate();
    });
  }

  Future<void> _loadUserCreationDate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.metadata.creationTime != null) {
      setState(() {
        _firstDay = user.metadata.creationTime;
      });
    } else {
      // Fallback to a year ago if creation time is not available
      setState(() {
        _firstDay = DateTime.now().subtract(const Duration(days: 365));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gamificationState = ref.watch(gamificationProvider);
    final allActivities = gamificationState.allActivities;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Calendar'),
        backgroundColor: AppTheme.primaryBackgroundColor,
        elevation: 0,
        foregroundColor: AppTheme.primaryTextColor,
      ),
      backgroundColor: AppTheme.primaryBackgroundColor,
      body: _firstDay == null
          ? const Center(child: CircularProgressIndicator())
          : TableCalendar(
              firstDay: _firstDay!,
              lastDay: DateTime.now(),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              eventLoader: (day) {
                // Normalize the day to ignore time component
                final normalizedDay = DateTime(day.year, day.month, day.day);
                return allActivities.contains(normalizedDay) ? [day] : [];
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: TextStyle(color: AppTheme.primaryTextColor),
                weekendTextStyle: TextStyle(color: AppTheme.primaryTextColor),
                todayDecoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  color: AppTheme.primaryTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon: Icon(Icons.chevron_left, color: AppTheme.primaryTextColor),
                rightChevronIcon: Icon(Icons.chevron_right, color: AppTheme.primaryTextColor),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isNotEmpty) {
                    return Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          shape: BoxShape.circle,
                        ),
                        width: 32,
                        height: 32,
                        child: const Icon(Icons.check, color: Colors.white, size: 18),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
    );
  }
}
