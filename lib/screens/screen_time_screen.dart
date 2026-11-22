import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_state.dart';

class ScreenTimeScreen extends StatefulWidget {
  final String childName;
  final DateTime dateOfBirth;

  const ScreenTimeScreen({
    super.key,
    required this.childName,
    required this.dateOfBirth,
  });

  @override
  State<ScreenTimeScreen> createState() => _ScreenTimeScreenState();
}

class _ScreenTimeScreenState extends State<ScreenTimeScreen> {
  String _historyFilter = 'All';
  String _deviceFilter = 'All';
  int _visibleRecords = 30;

  static const Color _primary = Color(0xFF4776A8);
  static const Color _background = Color(0xFFF5F8FC);

  DateTime get _today => DateUtils.dateOnly(DateTime.now());

  DateTime get _birthDate => DateUtils.dateOnly(widget.dateOfBirth);

  List<ScreenTimeRecord> get _records {
    final records = AppState.screenTimeFor(widget.childName);
    records.sort((a, b) => b.startTime.compareTo(a.startTime));
    return records;
  }

  int _minutesBetween(DateTime start, DateTime end) {
    return _records
        .where((r) => !r.startTime.isBefore(start) && r.startTime.isBefore(end))
        .fold<int>(0, (sum, r) => sum + r.durationMinutes);
  }

  String _duration(int minutes) {
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;

    if (hours == 0) return '${remaining}m';
    if (remaining == 0) return '${hours}h';
    return '${hours}h ${remaining}m';
  }

  DateTime _dayStart(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  List<ScreenTimeRecord> _recordsInPeriod(DateTime start, DateTime end) {
    return _records.where((r) {
      return !r.startTime.isBefore(start) && r.startTime.isBefore(end);
    }).toList();
  }

  int _totalMinutes(List<ScreenTimeRecord> records) {
    return records.fold<int>(0, (sum, record) => sum + record.durationMinutes);
  }

  double _averagePerDay(List<ScreenTimeRecord> records, int days) {
    if (days <= 0) return 0;
    return _totalMinutes(records) / days;
  }

  String _trendText(int current, int previous) {
    if (current == 0 && previous == 0) {
      return 'No screen-time sessions recorded';
    }

    if (previous == 0 && current > 0) {
      return 'Usage increased';
    }

    final change = ((current - previous) / previous) * 100;

    if (change > 10) return 'Usage increased';
    if (change < -10) return 'Usage decreased';
    return 'Usage remained stable';
  }

  Color _trendColor(int current, int previous) {
    if (current == 0 && previous == 0) {
      return Colors.blueGrey;
    }

    if (previous == 0 && current > 0) {
      return Colors.orange;
    }

    final change = ((current - previous) / previous) * 100;

    if (change > 10) return Colors.orange;
    if (change < -10) return Colors.green;
    return Colors.blueGrey;
  }

  String _percentageChange(int current, int previous) {
    if (previous == 0) {
      return current == 0 ? '0%' : 'New usage';
    }

    final change = ((current - previous) / previous) * 100;
    final sign = change > 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(1)}%';
  }

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF25364A),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview() {
    final todayStart = _today;
    final tomorrow = _today.add(const Duration(days: 1));

    final todayMinutes = _minutesBetween(todayStart, tomorrow);

    final sevenDaysAgo = _today.subtract(const Duration(days: 6));

    final sevenDaysMinutes = _minutesBetween(sevenDaysAgo, tomorrow);

    final allTime = _records.fold<int>(
      0,
      (sum, record) => sum + record.durationMinutes,
    );

    return Row(
      children: [
        _summaryCard(
          'Today',
          _duration(todayMinutes),
          Icons.today_rounded,
          Colors.blue,
        ),
        const SizedBox(width: 9),
        _summaryCard(
          'Last 7 days',
          _duration(sevenDaysMinutes),
          Icons.date_range_rounded,
          Colors.deepPurple,
        ),
        const SizedBox(width: 9),
        _summaryCard(
          'All time',
          _duration(allTime),
          Icons.history_rounded,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _buildGuidance() {
    final ageMonths =
        (_today.year - _birthDate.year) * 12 +
        _today.month -
        _birthDate.month -
        (_today.day < _birthDate.day ? 1 : 0);

    String guidance;

    if (ageMonths < 24) {
      guidance =
          'For children under 2, avoid routine passive screen use. '
          'Interactive video calls with an adult are a different context. '
          'Follow your child\'s healthcare professional for individual advice.';
    } else {
      guidance =
          'For children aged 2–5, general guidance is to keep recreational '
          'screen time around 1 hour per day or less, with adult co-viewing. '
          'Less is generally preferable.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FB),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: _primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              guidance,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF304B68),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final values = <int>[];
    final labels = <String>[];

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 6; i >= 0; i--) {
      final day = _today.subtract(Duration(days: i));
      final nextDay = day.add(const Duration(days: 1));

      values.add(_minutesBetween(day, nextDay));
      labels.add(weekdays[day.weekday - 1]);
    }

    final maximum = values.isEmpty ? 60 : math.max(60, values.reduce(math.max));

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily screen-time',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 5),
          Text(
            'Minutes recorded for the last 7 calendar days',
            style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade500),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 155,
            width: double.infinity,
            child: CustomPaint(
              painter: _WeeklyChartPainter(
                values: values,
                labels: labels,
                maximum: maximum.toDouble(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonCard({
    required String title,
    required String currentLabel,
    required String previousLabel,
    required int current,
    required int previous,
    required int days,
  }) {
    final trend = _trendText(current, previous);
    final color = _trendColor(current, previous);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _comparisonValue(currentLabel, _duration(current)),
              ),
              Expanded(
                child: _comparisonValue(previousLabel, _duration(previous)),
              ),
              Expanded(
                child: _comparisonValue(
                  'Change',
                  _percentageChange(current, previous),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                Icon(
                  current > previous
                      ? Icons.trending_up
                      : current < previous
                      ? Icons.trending_down
                      : Icons.trending_flat,
                  size: 17,
                  color: color,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'Daily average: '
            '${_averagePerDay(_recordsInPeriod(_today.subtract(Duration(days: days)), _today), days).toStringAsFixed(0)} minutes in the current period.',
            style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _comparisonValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade500),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildComparisons() {
    final currentWeekStart = _today.subtract(const Duration(days: 7));
    final previousWeekStart = _today.subtract(const Duration(days: 14));

    final currentWeek = _minutesBetween(currentWeekStart, _today);
    final previousWeek = _minutesBetween(previousWeekStart, currentWeekStart);

    final currentMonthStart = _today.subtract(const Duration(days: 30));
    final previousMonthStart = _today.subtract(const Duration(days: 60));

    final currentMonth = _minutesBetween(currentMonthStart, _today);
    final previousMonth = _minutesBetween(
      previousMonthStart,
      currentMonthStart,
    );

    return Column(
      children: [
        _comparisonCard(
          title: 'Weekly comparison',
          currentLabel: 'Last 7 days',
          previousLabel: 'Previous 7',
          current: currentWeek,
          previous: previousWeek,
          days: 7,
        ),
        _comparisonCard(
          title: 'Monthly comparison',
          currentLabel: 'Last 30 days',
          previousLabel: 'Previous 30',
          current: currentMonth,
          previous: previousMonth,
          days: 30,
        ),
      ],
    );
  }

  Widget _buildInsights() {
    final recentStart = _today.subtract(const Duration(days: 7));

    final recentRecords = _recordsInPeriod(
      recentStart,
      _today.add(const Duration(days: 1)),
    );

    final total = _totalMinutes(recentRecords);
    final average = total / 7;

    final unsupervised = recentRecords
        .where((r) => !r.supervised)
        .fold<int>(0, (sum, r) => sum + r.durationMinutes);

    final supervised = recentRecords
        .where((r) => r.supervised)
        .fold<int>(0, (sum, r) => sum + r.durationMinutes);

    final previousStart = _today.subtract(const Duration(days: 14));

    final previousMinutes = _minutesBetween(previousStart, recentStart);

    final currentMinutes = _minutesBetween(
      recentStart,
      _today.add(const Duration(days: 1)),
    );

    final trend = _trendText(currentMinutes, previousMinutes);

    final suggestions = <String>[];

    if (recentRecords.isEmpty) {
      suggestions.add(
        'No recent sessions are recorded. Add sessions consistently '
        'to make weekly and monthly comparisons more meaningful.',
      );
    } else {
      if (average > 60) {
        suggestions.add(
          'The recorded daily average is above 60 minutes. '
          'Consider gradually reducing recreational screen sessions.',
        );
      }

      if (unsupervised > 0 && unsupervised > supervised) {
        suggestions.add(
          'More recorded screen time was unsupervised. '
          'Try co-viewing, discussing content and keeping an adult nearby.',
        );
      }

      if (trend == 'Usage increased') {
        suggestions.add(
          'Screen time has increased compared with the previous week. '
          'Review the daily routine and consider setting consistent '
          'device-free periods.',
        );
      } else if (trend == 'Usage decreased') {
        suggestions.add(
          'Recorded screen time has decreased. Maintain healthy routines '
          'and protect sleep, active play and family interaction.',
        );
      } else {
        suggestions.add(
          'Usage is relatively stable. Continue monitoring the pattern '
          'and keep screen use balanced with other activities.',
        );
      }

      if (recentRecords.any(
        (r) => r.activity.toLowerCase().contains('video call'),
      )) {
        suggestions.add(
          'Video calls appear in the records. Interactive family calls '
          'can be different from passive viewing, but continue recording '
          'them separately where possible.',
        );
      }

      final nightSessions = recentRecords.where((r) {
        return r.startTime.hour >= 20 || r.startTime.hour < 6;
      }).length;

      if (nightSessions > 0) {
        suggestions.add(
          'Some sessions were recorded during late evening or night. '
          'Consider a screen-free wind-down routine before sleep.',
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Personalized observations',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Based on the child\'s last 7 days of recorded screen-time data.',
            style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade500),
          ),
          const SizedBox(height: 12),
          ...suggestions.map(
            (suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: _primary,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: const TextStyle(fontSize: 12, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 18),
          Text(
            'Supervised: ${_duration(supervised)}   •   '
            'Unsupervised: ${_duration(unsupervised)}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'These observations describe recorded screen-time patterns only. '
            'They do not diagnose autism or developmental delay. '
            'Review developmental assessments and milestones separately.',
            style: TextStyle(
              fontSize: 10,
              height: 1.45,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }

  List<ScreenTimeRecord> get _filteredRecords {
    var list = _records;

    if (_historyFilter == 'Today') {
      list = list
          .where((r) => DateUtils.isSameDay(r.startTime, _today))
          .toList();
    } else if (_historyFilter == '7 Days') {
      final start = _today.subtract(const Duration(days: 6));
      list = list.where((r) => !r.startTime.isBefore(start)).toList();
    } else if (_historyFilter == '30 Days') {
      final start = _today.subtract(const Duration(days: 29));
      list = list.where((r) => !r.startTime.isBefore(start)).toList();
    }

    if (_deviceFilter != 'All') {
      list = list.where((r) => r.device == _deviceFilter).toList();
    }

    return list;
  }

  Widget _buildHistory() {
    final records = _filteredRecords;
    final visible = records.take(_visibleRecords).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: ['All', 'Today', '7 Days', '30 Days'].map((filter) {
            final selected = _historyFilter == filter;

            return ChoiceChip(
              label: Text(filter),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _historyFilter = filter;
                  _visibleRecords = 30;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _deviceFilter,
          decoration: InputDecoration(
            labelText: 'Filter by device',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: ['All', 'Mobile', 'Tablet', 'Television', 'Computer', 'Other']
              .map((device) {
                return DropdownMenuItem(value: device, child: Text(device));
              })
              .toList(),
          onChanged: (value) {
            setState(() {
              _deviceFilter = value ?? 'All';
              _visibleRecords = 30;
            });
          },
        ),
        const SizedBox(height: 12),
        if (records.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Column(
              children: [
                Icon(Icons.history_rounded, size: 35, color: Colors.blueGrey),
                SizedBox(height: 8),
                Text(
                  'No screen-time records found',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 5),
                Text(
                  'Add a session to start tracking.',
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
              ],
            ),
          )
        else ...[
          Text(
            '${records.length} record(s) found',
            style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600),
          ),
          const SizedBox(height: 8),
          ...visible.map(_recordCard),
          if (visible.length < records.length)
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _visibleRecords += 30;
                  });
                },
                icon: const Icon(Icons.expand_more),
                label: const Text('Load more records'),
              ),
            ),
        ],
      ],
    );
  }

  Widget _recordCard(ScreenTimeRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.devices_rounded,
                  color: _primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.activity,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${record.device} • ${_duration(record.durationMinutes)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blueGrey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showRecordDialog(existing: record);
                  } else if (value == 'delete') {
                    _confirmDelete(record);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${record.startTime.day}/${record.startTime.month}/${record.startTime.year}'
            '  •  ${TimeOfDay.fromDateTime(record.startTime).format(context)}'
            ' – ${TimeOfDay.fromDateTime(record.endTime).format(context)}',
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Icon(
                record.supervised
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                size: 15,
                color: record.supervised ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 5),
              Text(
                record.supervised ? 'Supervised' : 'Unsupervised',
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
          if (record.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              record.notes,
              style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(ScreenTimeRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete record?'),
        content: const Text('This screen-time session will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      AppState.deleteScreenTime(record.id);
    }
  }

  // ==========================================================
  // ADD / EDIT SCREEN-TIME SESSION
  // ==========================================================

  Future<void> _showRecordDialog({ScreenTimeRecord? existing}) async {
    final isEditing = existing != null;

    final formKey = GlobalKey<FormState>();

    String device = existing?.device ?? 'Mobile';
    String activity = existing?.activity ?? 'Educational videos';
    bool supervised = existing?.supervised ?? true;

    DateTime selectedDate = existing != null
        ? _dayStart(existing.startTime)
        : _today;

    TimeOfDay startTime = existing != null
        ? TimeOfDay.fromDateTime(existing.startTime)
        : TimeOfDay.fromDateTime(
            DateTime.now().subtract(const Duration(minutes: 30)),
          );

    TimeOfDay endTime = existing != null
        ? TimeOfDay.fromDateTime(existing.endTime)
        : TimeOfDay.fromDateTime(DateTime.now());

    // Keep notes as local dialog state instead of owning a controller
    // outside the dialog route. This avoids disposing a TextEditingController
    // while the dialog's reverse transition may still be running.
    String notes = existing?.notes ?? '';

    String? errorMessage;

    Future<void> chooseDate(
      BuildContext pickerContext,
      StateSetter dialogSetState,
    ) async {
      final firstDate = _birthDate;
      final lastDate = _today;

      if (firstDate.isAfter(lastDate)) {
        dialogSetState(() {
          errorMessage = 'The child\'s birth date is in the future.';
        });
        return;
      }

      final initial = selectedDate.isBefore(firstDate)
          ? firstDate
          : selectedDate.isAfter(lastDate)
          ? lastDate
          : selectedDate;

      final picked = await showDatePicker(
        context: pickerContext,
        initialDate: initial,
        firstDate: firstDate,
        lastDate: lastDate,
        helpText: 'Select screen-time date',
        initialEntryMode: DatePickerEntryMode.calendar,
      );

      if (picked != null) {
        dialogSetState(() {
          selectedDate = _dayStart(picked);
          errorMessage = null;
        });
      }
    }

    Future<void> chooseTime(
      BuildContext pickerContext,
      StateSetter dialogSetState,
      bool isStart,
    ) async {
      final picked = await showTimePicker(
        context: pickerContext,
        initialTime: isStart ? startTime : endTime,
      );

      if (picked != null) {
        dialogSetState(() {
          if (isStart) {
            startTime = picked;
          } else {
            endTime = picked;
          }
          errorMessage = null;
        });
      }
    }

    // IMPORTANT:
    // The dialog only returns the prepared record.
    // AppState is NOT updated while the dialog is still open.
    final savedRecord = await showDialog<ScreenTimeRecord>(
      context: context,
      barrierDismissible: false,
      builder: (dialogRouteContext) {
        return StatefulBuilder(
          builder: (dialogContentContext, dialogSetState) {
            return AlertDialog(
              title: Text(
                isEditing
                    ? 'Edit screen-time session'
                    : 'Add screen-time session',
                style: const TextStyle(fontSize: 17),
              ),
              content: SizedBox(
                width: 430,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Child: ${widget.childName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Date',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () =>
                              chooseDate(dialogContentContext, dialogSetState),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  color: _primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'You can select any date from the child\'s birth date to today. '
                          'Tap the month/year at the top of the calendar to navigate.',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blueGrey.shade600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: device,
                          decoration: const InputDecoration(
                            labelText: 'Device',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              [
                                'Mobile',
                                'Tablet',
                                'Television',
                                'Computer',
                                'Other',
                              ].map((v) {
                                return DropdownMenuItem(
                                  value: v,
                                  child: Text(v),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              dialogSetState(() => device = value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: activity,
                          decoration: const InputDecoration(
                            labelText: 'Activity',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              [
                                'Educational videos',
                                'Cartoons / entertainment',
                                'Games',
                                'Video calls',
                                'Learning application',
                                'Other',
                              ].map((v) {
                                return DropdownMenuItem(
                                  value: v,
                                  child: Text(v),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              dialogSetState(() => activity = value);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _timeButton(
                                'Start time',
                                startTime,
                                () => chooseTime(
                                  dialogContentContext,
                                  dialogSetState,
                                  true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: _timeButton(
                                'End time',
                                endTime,
                                () => chooseTime(
                                  dialogContentContext,
                                  dialogSetState,
                                  false,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'If the end time is earlier than the start time, '
                          'the session is treated as an overnight session.',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blueGrey.shade600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Adult supervision',
                            style: TextStyle(fontSize: 13),
                          ),
                          value: supervised,
                          onChanged: (value) {
                            dialogSetState(() => supervised = value);
                          },
                        ),
                        TextFormField(
                          initialValue: notes,
                          maxLines: 3,
                          onChanged: (value) => notes = value,
                          decoration: const InputDecoration(
                            labelText: 'Notes (optional)',
                            hintText: 'Add details about this session...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogRouteContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }

                    final date = _dayStart(selectedDate);

                    if (date.isBefore(_birthDate)) {
                      dialogSetState(() {
                        errorMessage =
                            'Date cannot be earlier than the child\'s date of birth.';
                      });
                      return;
                    }

                    if (date.isAfter(_today)) {
                      dialogSetState(() {
                        errorMessage = 'Future dates are not allowed.';
                      });
                      return;
                    }

                    final start = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      startTime.hour,
                      startTime.minute,
                    );

                    DateTime end = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      endTime.hour,
                      endTime.minute,
                    );

                    if (end.isBefore(start)) {
                      end = end.add(const Duration(days: 1));
                    } else if (end.isAtSameMomentAs(start)) {
                      dialogSetState(() {
                        errorMessage =
                            'Start and end times cannot be the same.';
                      });
                      return;
                    }

                    final now = DateTime.now();

                    if (start.isAfter(now) || end.isAfter(now)) {
                      dialogSetState(() {
                        errorMessage =
                            'Future times are not allowed. Select a completed session.';
                      });
                      return;
                    }

                    if (start.isBefore(_birthDate)) {
                      dialogSetState(() {
                        errorMessage =
                            'Session cannot be before the child\'s birth date.';
                      });
                      return;
                    }

                    final duration = end.difference(start).inMinutes;

                    if (duration <= 0 || duration > 24 * 60) {
                      dialogSetState(() {
                        errorMessage =
                            'Please enter a valid session duration of less than 24 hours.';
                      });
                      return;
                    }

                    // Prepare the record, but do not save it yet.
                    final record = ScreenTimeRecord(
                      id: existing?.id ?? AppState.createId(),
                      childName: widget.childName,
                      device: device,
                      activity: activity,
                      date: date,
                      startTime: start,
                      endTime: end,
                      durationMinutes: duration,
                      supervised: supervised,
                      notes: notes.trim(),
                      recordedAt: existing?.recordedAt ?? DateTime.now(),
                    );

                    // Close the dialog first and return the record.
                    Navigator.of(dialogRouteContext).pop(record);
                  },
                  child: Text(isEditing ? 'Save changes' : 'Save session'),
                ),
              ],
            );
          },
        );
      },
    );

    // showDialog completes when the route is popped; allow its reverse
    // transition to finish before notifying the underlying screen listeners.
    // This prevents the screen's inherited-widget dependents from being
    // rebuilt while the dialog subtree is still being removed.
    if (savedRecord == null) return;
    await Future<void>.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;

    if (isEditing) {
      AppState.updateScreenTime(savedRecord);
    } else {
      AppState.addScreenTime(savedRecord);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEditing
              ? 'Screen-time record updated.'
              : 'Screen-time session saved.',
        ),
      ),
    );
  }

  Widget _timeButton(String label, TimeOfDay time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade600),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: _primary,
                ),
                const SizedBox(width: 5),
                Text(
                  time.format(context),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // SCREEN UI
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    // Keep Scaffold stable. Only rebuild its body when AppState changes.
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Screen Time',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF25364A),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRecordDialog(),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add session'),
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: AppState.revision,
        builder: (context, revision, child) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 95),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4776A8), Color(0xFF6496C5)],
                      ),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Screen-time monitoring',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tracking records for ${widget.childName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Record past sessions, review usage patterns and '
                          'build healthier daily routines.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _sectionTitle('Usage overview'),
                  _buildOverview(),
                  _sectionTitle('General age guidance'),
                  _buildGuidance(),
                  _sectionTitle(
                    'Weekly usage chart',
                    subtitle: 'A quick view of daily recorded screen time',
                  ),
                  _buildWeeklyChart(),
                  _sectionTitle(
                    'Usage comparisons',
                    subtitle:
                        'Current periods compared with the previous periods',
                  ),
                  _buildComparisons(),
                  _sectionTitle(
                    'Insights and suggestions',
                    subtitle: 'Generated from this child\'s recorded usage',
                  ),
                  _buildInsights(),
                  _sectionTitle(
                    'Screen-time history',
                    subtitle: 'Every saved session remains a separate record',
                  ),
                  _buildHistory(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// WEEKLY CHART PAINTER
// ============================================================

class _WeeklyChartPainter extends CustomPainter {
  final List<int> values;
  final List<String> labels;
  final double maximum;

  _WeeklyChartPainter({
    required this.values,
    required this.labels,
    required this.maximum,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const left = 8.0;
    const right = 8.0;
    const top = 10.0;
    const bottom = 25.0;

    final chartHeight = size.height - top - bottom;
    final chartWidth = size.width - left - right;

    final gridPaint = Paint()
      ..color = const Color(0xFFE8EDF3)
      ..strokeWidth = 1;

    final barPaint = Paint()
      ..color = const Color(0xFF6496C5)
      ..style = PaintingStyle.fill;

    const textStyle = TextStyle(color: Color(0xFF718096), fontSize: 9);

    for (int i = 0; i < 4; i++) {
      final y = top + chartHeight * i / 3;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
    }

    const gap = 10.0;
    final barWidth = (chartWidth - gap * (values.length - 1)) / values.length;

    for (int i = 0; i < values.length; i++) {
      final x = left + i * (barWidth + gap);
      final barHeight = (values[i] / maximum).clamp(0.0, 1.0) * chartHeight;

      final rect = Rect.fromLTWH(
        x,
        top + chartHeight - barHeight,
        barWidth,
        barHeight,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        barPaint,
      );

      final valueText = values[i].toString();

      final valuePainter = TextPainter(
        text: const TextSpan(text: '', style: textStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      valuePainter.text = TextSpan(text: valueText, style: textStyle);
      valuePainter.layout();

      valuePainter.paint(
        canvas,
        Offset(
          x + (barWidth - valuePainter.width) / 2,
          math.max(0, rect.top - 13),
        ),
      );

      final labelPainter = TextPainter(
        text: TextSpan(text: labels[i], style: textStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      labelPainter.paint(
        canvas,
        Offset(x + (barWidth - labelPainter.width) / 2, size.height - 17),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.labels != labels ||
        oldDelegate.maximum != maximum;
  }
}
