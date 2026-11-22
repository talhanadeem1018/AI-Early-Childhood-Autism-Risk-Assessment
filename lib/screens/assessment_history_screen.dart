import 'package:flutter/material.dart';

import '../app_state.dart';
import '../services/api_client.dart';
import '../services/assessment_service.dart';
import '../services/session_service.dart';
import 'assessment_result_screen.dart';

const Color _primary = Color(0xFF347F83);
const Color _dark = Color(0xFF235B68);
const Color _muted = Color(0xFF718588);

String _concernLabel(String level) {
  switch (level.toLowerCase()) {
    case 'low':
      return 'Low concern';
    case 'moderate':
      return 'Moderate concern';
    case 'high':
      return 'High concern';
    default:
      final words = level.replaceAll('_', ' ').trim();
      return words.isEmpty
          ? 'Assessment'
          : words[0].toUpperCase() + words.substring(1);
  }
}

Color _concernColor(String level) {
  switch (level.toLowerCase()) {
    case 'low':
      return const Color(0xFF2F7D5D);
    case 'moderate':
      return const Color(0xFFB7791F);
    case 'high':
      return const Color(0xFFB44747);
    default:
      return _primary;
  }
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1);
}

String _formatTimestamp(DateTime? value) {
  if (value == null) return 'Date unavailable';

  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');

  return '$day/$month/${value.year} $hour:$minute';
}

String _messageFor(ApiException error) {
  if (error.statusCode == 401) {
    return 'Your session has expired. Please log in again.';
  }
  if (error.statusCode >= 500) {
    return 'The server could not load assessment history. Please try again.';
  }
  return error.message;
}

/// Full assessment history for the selected backend child.
class AssessmentHistoryScreen extends StatefulWidget {
  const AssessmentHistoryScreen({
    super.key,
    required this.childId,
    required this.childName,
    this.session,
  });

  final String childId;
  final String childName;
  final SessionService? session;

  @override
  State<AssessmentHistoryScreen> createState() =>
      _AssessmentHistoryScreenState();
}

class _AssessmentHistoryScreenState extends State<AssessmentHistoryScreen> {
  late final AssessmentService _service;

  List<AssessmentHistoryEntry> _entries = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = AssessmentService(
      api: (widget.session ?? SessionService.instance).api,
    );
    AppState.assessmentHistoryRevision.addListener(_reload);
    _load();
  }

  @override
  void dispose() {
    AppState.assessmentHistoryRevision.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final entries = await _service.fetchHistory(widget.childId);

      if (!mounted) return;

      setState(() {
        _entries = entries;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _messageFor(error);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong while loading assessment history.';
        _loading = false;
      });
    }
  }

  void _openDetails(AssessmentHistoryEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssessmentResultScreen(
          childName: widget.childName,
          result: entry.result,
          backLabel: 'Back',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardHistoryStyle.background,
      appBar: AppBar(
        backgroundColor: DashboardHistoryStyle.background,
        foregroundColor: _dark,
        title: const Text(
          'Assessment History',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            key: const Key('history-refresh'),
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _primary),
            SizedBox(height: 14),
            Text(
              'Loading assessment history...',
              key: Key('history-loading'),
              style: TextStyle(color: _muted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 44,
                  color: _muted,
                ),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  key: const Key('history-error'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFB44747),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('history-retry'),
                  onPressed: _load,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.assignment_outlined,
                size: 46,
                color: _primary,
              ),
              const SizedBox(height: 12),
              const Text(
                'No assessments yet',
                key: Key('history-empty'),
                style: TextStyle(
                  color: _dark,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Complete the developmental questionnaire to see the '
                'assessment results here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      key: const Key('history-list'),
      padding: const EdgeInsets.all(16),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];

        return _historyCard(entry);
      },
    );
  }

  Widget _historyCard(AssessmentHistoryEntry entry) {
    final color = _concernColor(entry.result.concernLevel);
    final percentage = entry.result.concernPercentage;

    return Card(
      key: Key('history-card-${entry.id}'),
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: () => _openDetails(entry),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(Icons.assignment_turned_in_rounded, color: color),
        ),
        title: Text(
          _concernLabel(entry.result.concernLevel),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          '${_formatTimestamp(entry.createdAt)}'
          '${entry.result.ageGroup.isEmpty ? '' : ' • ${entry.result.ageGroup}'}',
          style: const TextStyle(fontSize: 11, color: _muted),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (percentage != null)
              Text(
                '${_formatNumber(percentage)}%',
                style: const TextStyle(
                  color: _dark,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: _muted),
          ],
        ),
      ),
    );
  }
}

/// Shared colours used by the backend history widgets on the dashboard.
class DashboardHistoryStyle {
  DashboardHistoryStyle._();

  static const Color background = Color(0xFFF3F8F8);
}

/// Compact “Recent Activity” card backed by the history endpoint.
class RecentAssessmentCard extends StatefulWidget {
  const RecentAssessmentCard({
    super.key,
    required this.childId,
    required this.childName,
    this.session,
  });

  final String childId;
  final String childName;
  final SessionService? session;

  @override
  State<RecentAssessmentCard> createState() => _RecentAssessmentCardState();
}

class _RecentAssessmentCardState extends State<RecentAssessmentCard> {
  late final AssessmentService _service;

  AssessmentHistoryEntry? _latest;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _service = AssessmentService(
      api: (widget.session ?? SessionService.instance).api,
    );
    AppState.assessmentHistoryRevision.addListener(_reload);
    _load();
  }

  @override
  void dispose() {
    AppState.assessmentHistoryRevision.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });

    try {
      final entries = await _service.fetchHistory(widget.childId);

      if (!mounted) return;

      setState(() {
        _latest = entries.isEmpty ? null : entries.first;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  void _openDetails() {
    final entry = _latest;
    if (entry == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssessmentResultScreen(
          childName: widget.childName,
          result: entry.result,
          backLabel: 'Back',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text(
              'Loading assessments...',
              style: TextStyle(fontSize: 12, color: _muted),
            ),
          ],
        ),
      );
    }

    if (_failed) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFB44747), size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Assessment history could not be loaded.',
                style: TextStyle(fontSize: 12, color: Color(0xFFB44747)),
              ),
            ),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final entry = _latest;

    if (entry == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.event_note_outlined, color: _primary, size: 25),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No assessments recorded yet. Your first observation will appear here.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final color = _concernColor(entry.result.concernLevel);
    final percentage = entry.result.concernPercentage;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: const Key('recent-assessment'),
        borderRadius: BorderRadius.circular(14),
        onTap: _openDetails,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                Icons.assignment_turned_in_rounded,
                color: color,
                size: 26,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _concernLabel(entry.result.concernLevel),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(entry.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (percentage != null)
                Text(
                  '${_formatNumber(percentage)}%',
                  style: const TextStyle(
                    color: _dark,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              const Icon(Icons.chevron_right_rounded, color: _muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loads the backend assessment count for the dashboard overview.
class AssessmentHistoryCount extends StatefulWidget {
  const AssessmentHistoryCount({
    super.key,
    required this.childId,
    required this.builder,
    this.session,
  });

  final String childId;
  final Widget Function(BuildContext context, int? count) builder;
  final SessionService? session;

  @override
  State<AssessmentHistoryCount> createState() => _AssessmentHistoryCountState();
}

class _AssessmentHistoryCountState extends State<AssessmentHistoryCount> {
  late final AssessmentService _service;

  int? _count;

  @override
  void initState() {
    super.initState();
    _service = AssessmentService(
      api: (widget.session ?? SessionService.instance).api,
    );
    AppState.assessmentHistoryRevision.addListener(_reload);
    _load();
  }

  @override
  void dispose() {
    AppState.assessmentHistoryRevision.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    try {
      final entries = await _service.fetchHistory(widget.childId);

      if (!mounted) return;

      setState(() => _count = entries.length);
    } catch (_) {
      if (!mounted) return;
      setState(() => _count = null);
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _count);
}
