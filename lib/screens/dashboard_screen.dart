import 'package:flutter/material.dart';

import '../app_state.dart';
import 'assessment_history_screen.dart';
import 'assessment_screen.dart';
import 'milestone_tracking_screen.dart';
import 'screen_time_screen.dart';
import 'camera_analysis_screen.dart';
import 'activity_observation_screen.dart';

class DashboardScreen extends StatelessWidget {
  // Constructor values remain as a compatibility fallback for older routes.
  final String _initialChildName;
  final DateTime _initialDateOfBirth;
  final String _initialGender;
  final String _initialParentName;
  final String _initialParentEmail;
  final String _initialRelationship;
  final String _initialPhone;

  const DashboardScreen({
    super.key,
    required String childName,
    required DateTime dateOfBirth,
    required String gender,
    required String parentName,
    required String parentEmail,
    required String relationship,
    required String phone,
  }) : _initialChildName = childName,
       _initialDateOfBirth = dateOfBirth,
       _initialGender = gender,
       _initialParentName = parentName,
       _initialParentEmail = parentEmail,
       _initialRelationship = relationship,
       _initialPhone = phone;

  ChildProfileRecord? get _activeProfile => AppState.selectedChildProfile;

  /// Real backend child ID when the active profile came from the API.
  String? get _remoteChildId {
    final id = _activeProfile?.id;
    return AppState.isBackendChild(id) ? id : null;
  }

  String get childName => _activeProfile?.childName ?? _initialChildName;
  DateTime get dateOfBirth =>
      _activeProfile?.dateOfBirth ?? _initialDateOfBirth;
  String get gender => _activeProfile?.gender ?? _initialGender;
  String get parentName => _activeProfile?.parentName ?? _initialParentName;
  String get parentEmail => _activeProfile?.parentEmail ?? _initialParentEmail;
  String get relationship =>
      _activeProfile?.relationship ?? _initialRelationship;
  String get phone => _activeProfile?.phone ?? _initialPhone;

  static const Color primary = Color(0xFF287F83);
  static const Color background = Color(0xFFF3F8F8);

  int get childAgeInMonths {
    final now = DateTime.now();
    return (now.year - dateOfBirth.year) * 12 +
        now.month -
        dateOfBirth.month -
        (now.day < dateOfBirth.day ? 1 : 0);
  }

  String get childAge {
    final months = childAgeInMonths;

    if (months < 12) return '$months months';

    final years = months ~/ 12;
    final remaining = months % 12;

    return remaining == 0 ? '$years years' : '$years years, $remaining months';
  }

  String get formattedDate =>
      '${dateOfBirth.day.toString().padLeft(2, '0')}/'
      '${dateOfBirth.month.toString().padLeft(2, '0')}/'
      '${dateOfBirth.year}';

  void openAssessment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssessmentScreen(
          childName: childName,
          dateOfBirth: dateOfBirth,
          childId: AppState.selectedChildProfile?.id,
        ),
      ),
    );
  }

  void openMilestones(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MilestoneTrackingScreen(
          childName: childName,
          dateOfBirth: dateOfBirth,
        ),
      ),
    );
  }

  // SCREEN TIME MODULE
  void openScreenTime(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ScreenTimeScreen(childName: childName, dateOfBirth: dateOfBirth),
      ),
    );
  }

  // ACTIVITY OBSERVATIONS MODULE
  void openActivityObservations(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityObservationScreen(childName: childName),
      ),
    );
  }

  // CAMERA AND VIDEO ANALYSIS MODULE
  void openCameraAnalysis(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraAnalysisScreen(childName: childName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: const Color(0xFF243B3D),
        elevation: 0,
        title: const Text(
          'NurtureSteps',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _NotificationsScreen(childName: childName),
              ),
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: AppState.revision,
          builder: (context, revision, _) {
            final assessments = AppState.assessmentsFor(childName);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _welcome(),
                      const SizedBox(height: 16),
                      _childCard(),
                      if (AppState.allChildProfiles.length > 1) ...[
                        const SizedBox(height: 10),
                        _childProfileSwitcher(),
                      ],
                      const SizedBox(height: 22),
                      _sectionTitle('Development Overview'),
                      const SizedBox(height: 12),
                      _overview(),
                      const SizedBox(height: 24),
                      _sectionTitle('Development Modules'),
                      const SizedBox(height: 5),
                      const Text(
                        'Choose an area to explore your child’s progress.',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                      const SizedBox(height: 13),
                      _modules(context),
                      const SizedBox(height: 22),
                      _sectionTitle('Recent Activity'),
                      const SizedBox(height: 10),
                      if (_remoteChildId != null)
                        RecentAssessmentCard(
                          childId: _remoteChildId!,
                          childName: childName,
                        )
                      else if (assessments.isEmpty)
                        _emptyActivity()
                      else
                        _recentAssessment(assessments.first),
                      const SizedBox(height: 22),
                      _sectionTitle('Caregiver Information'),
                      const SizedBox(height: 10),
                      _caregiverCard(),
                      const SizedBox(height: 18),
                      _disclaimer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _welcome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, $parentName!',
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: Color(0xFF243B3D),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Every little step is a step towards a brighter future.',
          style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
        ),
      ],
    );
  }

  Widget _childCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF287F83), Color(0xFF235B68)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          Container(
            height: 57,
            width: 57,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.child_care_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  childName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$childAge  •  $gender',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  'Born: $formattedDate',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.favorite_rounded,
            color: Color(0xFFFFD5D5),
            size: 23,
          ),
        ],
      ),
    );
  }

  Widget _childProfileSwitcher() {
    final profiles = AppState.allChildProfiles;
    final selectedId = AppState.selectedChildProfileId;
    final validSelectedId = profiles.any((profile) => profile.id == selectedId)
        ? selectedId
        : profiles.first.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE2ECEC)),
      ),
      child: Row(
        children: [
          const Icon(Icons.swap_horiz_rounded, color: primary, size: 21),
          const SizedBox(width: 9),
          const Text(
            'Viewing child',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF405456),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: validSelectedId,
                items: profiles.map((profile) {
                  return DropdownMenuItem<String>(
                    value: profile.id,
                    child: Text(
                      profile.childName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (id) {
                  if (id != null) AppState.selectChildProfile(id);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF243B3D),
        fontWeight: FontWeight.bold,
        fontSize: 17,
      ),
    );
  }

  // ============================================================
  // DEVELOPMENT OVERVIEW - CHILD SPECIFIC DYNAMIC COUNTERS
  // ============================================================

  Widget _overview() {
    final assessmentCount = AppState.assessmentCountFor(childName);

    final completedMilestones = AppState.completedMilestonesFor(childName);

    final totalMilestones = AppState.totalMilestonesFor(childName);

    final screenTimeCount = AppState.screenTimeRecordCountFor(childName);

    return Row(
      children: [
        Expanded(
          child: _remoteChildId == null
              ? _statCard(
                  icon: Icons.assignment_rounded,
                  title: 'Assessments',
                  value: '$assessmentCount',
                  color: const Color(0xFF287F83),
                  background: const Color(0xFFE2F3F1),
                )
              : AssessmentHistoryCount(
                  childId: _remoteChildId!,
                  builder: (context, count) => _statCard(
                    icon: Icons.assignment_rounded,
                    title: 'Assessments',
                    value: count == null ? '–' : '$count',
                    color: const Color(0xFF287F83),
                    background: const Color(0xFFE2F3F1),
                  ),
                ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _statCard(
            icon: Icons.flag_rounded,
            title: 'Milestones',
            value: '$completedMilestones/$totalMilestones',
            color: const Color(0xFF8A65B4),
            background: const Color(0xFFF0E9FA),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _statCard(
            icon: Icons.access_time_filled_rounded,
            title: 'Screen Time',
            value: '$screenTimeCount',
            color: const Color(0xFFD58A42),
            background: const Color(0xFFFFF0DE),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color background,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF405456),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DEVELOPMENT MODULES
  // ============================================================

  Widget _modules(BuildContext context) {
    final modules = [
      _Module(
        title: 'Development Assessment',
        description: 'Record developmental observations',
        icon: Icons.assignment_outlined,
        color: const Color(0xFF287F83),
        background: const Color(0xFFE2F3F1),
        action: () => openAssessment(context),
      ),
      _Module(
        title: 'Milestone Tracking',
        description: 'Follow important growth milestones',
        icon: Icons.flag_outlined,
        color: const Color(0xFF8A65B4),
        background: const Color(0xFFF0E9FA),
        action: () => openMilestones(context),
      ),
      _Module(
        title: 'Screen Time Tracking',
        description: 'Add and review daily screen usage history',
        icon: Icons.access_time_filled_rounded,
        color: const Color(0xFFD58A42),
        background: const Color(0xFFFFF0DE),
        action: () => openScreenTime(context),
      ),
      _Module(
        title: 'Activity Observations',
        description: 'Record everyday activities and behaviours you notice',
        icon: Icons.visibility_outlined,
        color: const Color(0xFF4D8B72),
        background: const Color(0xFFE6F3EB),
        action: () => openActivityObservations(context),
      ),
      _Module(
        title: 'Camera & Video Analysis',
        description: 'Record or upload videos for developmental review',
        icon: Icons.videocam_rounded,
        color: const Color(0xFF527CB5),
        background: const Color(0xFFE8F0FC),
        action: () => openCameraAnalysis(context),
      ),
      _Module(
        title: 'Progress History',
        description: 'Review previous assessments',
        icon: Icons.timeline_rounded,
        color: const Color(0xFFD58A42),
        background: const Color(0xFFFFF0DE),
        action: () {
          final remoteChildId = _remoteChildId;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => remoteChildId == null
                  ? _ProgressHistoryScreen(childName: childName)
                  : AssessmentHistoryScreen(
                      childId: remoteChildId,
                      childName: childName,
                    ),
            ),
          );
        },
      ),
      _Module(
        title: 'Notifications',
        description: 'View updates and reminders',
        icon: Icons.notifications_active_outlined,
        color: const Color(0xFF527CB5),
        background: const Color(0xFFE8F0FC),
        action: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _NotificationsScreen(childName: childName),
          ),
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 360 ? 1 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: modules.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 11,
            mainAxisSpacing: 11,
            mainAxisExtent: 124,
          ),
          itemBuilder: (context, index) {
            final module = modules[index];

            return Material(
              color: module.background,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: module.action,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 34,
                        width: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(module.icon, color: module.color, size: 21),
                      ),
                      const Spacer(),
                      Text(
                        module.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF243B3D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        module.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          height: 1.3,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // RECENT ACTIVITY
  // ============================================================

  Widget _emptyActivity() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.event_note_outlined, color: primary, size: 25),
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

  Widget _recentAssessment(AssessmentRecord record) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.assignment_turned_in_rounded,
            color: primary,
            size: 26,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Development Assessment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.date.day}/${record.date.month}/${record.date.year}',
                  style: const TextStyle(color: Colors.black54, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: primary, size: 20),
        ],
      ),
    );
  }

  // ============================================================
  // CAREGIVER INFORMATION
  // ============================================================

  Widget _caregiverCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _infoRow(Icons.person_outline, 'Parent', parentName),
          const Divider(height: 19),
          _infoRow(Icons.family_restroom, 'Relationship', relationship),
          const Divider(height: 19),
          _infoRow(Icons.email_outlined, 'Email', parentEmail),
          const Divider(height: 19),
          _infoRow(Icons.phone_outlined, 'Phone', phone),
          const Divider(height: 19),
          _infoRow(Icons.wc, 'Gender', gender),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: primary, size: 19),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ),
        Flexible(
          child: Text(
            value.isEmpty ? 'Not provided' : value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Color(0xFF243B3D),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MEDICAL DISCLAIMER
  // ============================================================

  Widget _disclaimer() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F0F0),
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: primary, size: 20),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'This application supports developmental monitoring and '
              'early identification of potential concerns. It does not '
              'provide a medical diagnosis. Consult a qualified '
              'healthcare professional for clinical evaluation.',
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: Color(0xFF35585A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// MODULE MODEL
// ================================================================

class _Module {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback action;

  const _Module({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.background,
    required this.action,
  });
}

// ================================================================
// LONGITUDINAL PROGRESS HISTORY
// ================================================================

class _ProgressHistoryScreen extends StatelessWidget {
  final String childName;

  const _ProgressHistoryScreen({required this.childName});

  int _count(Map<String, Map<String, int>> results, String key) {
    return results.values.fold<int>(
      0,
      (sum, domain) => sum + (domain[key] ?? 0),
    );
  }

  double? _observedRate(AssessmentRecord record) {
    final yes =
        _count(record.results, 'Yes') +
        _count(record.results, 'Achieved / Observed');
    final unsure = _count(record.results, 'Not Sure');
    final notYet = _count(record.results, 'Not Yet');
    final sometimes = _count(record.results, 'Sometimes');
    final total = yes + unsure + notYet + sometimes;
    if (total == 0) return null;
    return yes / total * 100;
  }

  double? _periodAverage(
    List<AssessmentRecord> records,
    DateTime start,
    DateTime end,
  ) {
    final values = records
        .where((r) => !r.date.isBefore(start) && r.date.isBefore(end))
        .map(_observedRate)
        .whereType<double>()
        .toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  String _percent(double? value) =>
      value == null ? '—' : '${value.toStringAsFixed(0)}%';

  String _change(double? current, double? previous) {
    if (current == null || previous == null) {
      return 'Not enough sessions to compare';
    }
    final difference = current - previous;
    if (difference.abs() < 0.5) {
      return 'No meaningful change in recorded observations';
    }
    return '${difference > 0 ? '+' : ''}${difference.toStringAsFixed(1)} percentage points';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final weekStart = today.subtract(const Duration(days: 6));
    final previousWeekStart = today.subtract(const Duration(days: 13));
    final monthStart = today.subtract(const Duration(days: 29));
    final previousMonthStart = today.subtract(const Duration(days: 59));

    return Scaffold(
      backgroundColor: DashboardScreen.background,
      appBar: AppBar(
        title: const Text('Progress & History'),
        backgroundColor: DashboardScreen.background,
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: AppState.revision,
        builder: (context, revision, _) {
          final records = AppState.assessmentsFor(childName);
          final screenRecords = AppState.screenTimeFor(childName);
          final observations = AppState.observationsFor(childName);
          final milestones = AppState.milestonesFor(childName);
          final milestoneHistory = AppState.milestoneHistoryFor(childName);

          final currentWeek = _periodAverage(
            records,
            weekStart,
            today.add(const Duration(days: 1)),
          );
          final previousWeek = _periodAverage(
            records,
            previousWeekStart,
            weekStart,
          );
          final currentMonth = _periodAverage(
            records,
            monthStart,
            today.add(const Duration(days: 1)),
          );
          final previousMonth = _periodAverage(
            records,
            previousMonthStart,
            monthStart,
          );

          final trendRecords = records.reversed
              .where((r) => _observedRate(r) != null)
              .toList();
          final trend = trendRecords.length > 8
              ? trendRecords.sublist(trendRecords.length - 8)
              : trendRecords;
          final trendValues = trend.map((r) => _observedRate(r)!).toList();

          final dailyScreenMinutes = List<int>.generate(7, (index) {
            final day = today.subtract(Duration(days: 6 - index));
            final nextDay = day.add(const Duration(days: 1));
            return screenRecords
                .where(
                  (r) =>
                      !r.startTime.isBefore(day) &&
                      r.startTime.isBefore(nextDay),
                )
                .fold<int>(0, (sum, r) => sum + r.durationMinutes);
          });

          final currentWeekScreen = screenRecords
              .where(
                (r) =>
                    !r.startTime.isBefore(weekStart) &&
                    r.startTime.isBefore(today.add(const Duration(days: 1))),
              )
              .fold<int>(0, (sum, r) => sum + r.durationMinutes);
          final previousWeekScreen = screenRecords
              .where(
                (r) =>
                    !r.startTime.isBefore(previousWeekStart) &&
                    r.startTime.isBefore(weekStart),
              )
              .fold<int>(0, (sum, r) => sum + r.durationMinutes);

          final yesCount = records.fold<int>(
            0,
            (sum, r) =>
                sum +
                _count(r.results, 'Yes') +
                _count(r.results, 'Achieved / Observed'),
          );
          final unsureCount = records.fold<int>(
            0,
            (sum, r) => sum + _count(r.results, 'Not Sure'),
          );
          final notYetCount = records.fold<int>(
            0,
            (sum, r) => sum + _count(r.results, 'Not Yet'),
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _historyHeader(records.length),
              const SizedBox(height: 14),
              _comparisonCard(
                title: 'Last 7 days vs previous 7 days',
                currentLabel: 'Current week',
                previousLabel: 'Previous week',
                current: currentWeek,
                previous: previousWeek,
                change: _change(currentWeek, previousWeek),
              ),
              const SizedBox(height: 10),
              _comparisonCard(
                title: 'Last 30 days vs previous 30 days',
                currentLabel: 'Current month',
                previousLabel: 'Previous month',
                current: currentMonth,
                previous: previousMonth,
                change: _change(currentMonth, previousMonth),
              ),
              const SizedBox(height: 16),
              _chartCard(
                title: 'Observed milestones across sessions',
                subtitle:
                    'Percentage marked “Yes” in each saved CDC checklist session. This is a descriptive trend, not a clinical score.',
                child: trendValues.length < 2
                    ? _chartEmpty(
                        'Complete at least two sessions to see a trend graph.',
                      )
                    : SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _MilestoneTrendPainter(trendValues),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              _chartCard(
                title: 'Screen-time history',
                subtitle: 'Recorded minutes per day for the last 7 days.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    dailyScreenMinutes.every((v) => v == 0)
                        ? _chartEmpty(
                            'No screen-time sessions recorded in the last 7 days.',
                          )
                        : SizedBox(
                            height: 180,
                            width: double.infinity,
                            child: CustomPaint(
                              painter: _ScreenTimeBarsPainter(
                                dailyScreenMinutes,
                              ),
                            ),
                          ),
                    const SizedBox(height: 8),
                    Text(
                      'This week: ${_duration(currentWeekScreen)} • Previous week: ${_duration(previousWeekScreen)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _chartCard(
                title: 'Record overview',
                subtitle: 'Saved records across all sessions for this child.',
                child: Column(
                  children: [
                    _metricRow(
                      'Development sessions',
                      '${records.length}',
                      Icons.assignment_outlined,
                    ),
                    _metricRow(
                      'Activity observations',
                      '${observations.length}',
                      Icons.visibility_outlined,
                    ),
                    _metricRow(
                      'Milestones currently tracked',
                      '${milestones.length}',
                      Icons.flag_outlined,
                    ),
                    _metricRow(
                      'Milestone status changes',
                      '${milestoneHistory.length}',
                      Icons.history_rounded,
                    ),
                    _metricRow(
                      'Screen-time sessions',
                      '${screenRecords.length}',
                      Icons.access_time_rounded,
                    ),
                    _metricRow(
                      'Total recorded screen time',
                      _duration(AppState.totalScreenTimeMinutesFor(childName)),
                      Icons.timer_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _chartCard(
                title: 'Caregiver review',
                subtitle:
                    'Automatic summary of recorded answers. It does not classify a child as healthy, ill, or at risk.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _metricRow(
                      'Milestones marked Yes',
                      '$yesCount',
                      Icons.check_circle_outline,
                    ),
                    _metricRow(
                      'Milestones marked Not Sure',
                      '$unsureCount',
                      Icons.help_outline,
                    ),
                    _metricRow(
                      'Milestones marked Not Yet',
                      '$notYetCount',
                      Icons.info_outline,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      records.isEmpty
                          ? 'No assessment sessions are saved yet. Complete an age-appropriate CDC milestone checklist to begin longitudinal monitoring.'
                          : notYetCount > 0
                          ? 'Some milestones have been marked “Not Yet”. Share the completed checklist and your observations with the child’s healthcare professional. Do not interpret these entries as a diagnosis.'
                          : unsureCount > 0
                          ? 'Some milestones are marked “Not Sure”. Observe the child in suitable everyday opportunities over the next week or two. If you remain unsure or concerned, discuss this with a healthcare professional.'
                          : 'All recorded checklist items are marked “Yes”. Continue routine developmental monitoring and discuss any concerns with the child’s healthcare professional.',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.55,
                        color: Color(0xFF35585A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (records.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No assessment history is available yet.'),
                  ),
                )
              else ...[
                const Text(
                  'Session history',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...records.map(
                  (record) => Card(
                    elevation: 0,
                    color: Colors.white,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE2F3F1),
                        child: Icon(
                          Icons.assignment_outlined,
                          color: DashboardScreen.primary,
                        ),
                      ),
                      title: Text(
                        record.notes['__checklist_age_months'] == null
                            ? 'Development observation'
                            : 'CDC checklist • ${record.notes['__checklist_age_months']} months',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        '${record.date.day}/${record.date.month}/${record.date.year} '
                        '${record.date.hour.toString().padLeft(2, '0')}:'
                        '${record.date.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: Text(_percent(_observedRate(record))),
                      onTap: () => _showSession(context, record),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Important: CDC milestone checklists support developmental monitoring. CDC states that these materials are not a substitute for standardized, validated developmental screening tools. Any concern, loss of skills, or missed milestones should be discussed with a qualified healthcare professional.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.55,
                  color: Colors.black54,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _duration(int minutes) {
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;

    // FIX: Removed unnecessary interpolation braces.
    if (hours == 0) return '$remainder min';

    if (remainder == 0) return '$hours hr';

    return '$hours hr $remainder min';
  }

  Widget _historyHeader(int sessions) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF347F83), Color(0xFF235B68)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights_rounded, color: Colors.white, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Longitudinal development record',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$sessions saved assessment sessions',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
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
    required double? current,
    required double? previous,
    required String change,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _periodValue(currentLabel, _percent(current))),
                Expanded(
                  child: _periodValue(previousLabel, _percent(previous)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              change,
              style: const TextStyle(color: Color(0xFF527477), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 11),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: DashboardScreen.primary,
          ),
        ),
      ],
    );
  }

  Widget _chartCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _chartEmpty(String message) {
    return Container(
      height: 110,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black54, fontSize: 12),
      ),
    );
  }

  Widget _metricRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: DashboardScreen.primary),
          const SizedBox(width: 9),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showSession(BuildContext context, AssessmentRecord record) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Session details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Date: ${record.date}'),
              if (record.notes['__checklist_age_months'] != null)
                Text(
                  'Checklist age: ${record.notes['__checklist_age_months']} months',
                ),
              const SizedBox(height: 12),
              ...record.results.entries.map(
                (domain) => Card(
                  elevation: 0,
                  color: const Color(0xFFF3F8F8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          domain.key,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ...domain.value.entries.map(
                          (entry) => Text('${entry.key}: ${entry.value}'),
                        ),
                        if (record.notes[domain.key]?.isNotEmpty ?? false)
                          Text('Caregiver note: ${record.notes[domain.key]}'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Observational record only — not a diagnosis or clinical risk score.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MilestoneTrendPainter extends CustomPainter {
  final List<double> values;

  _MilestoneTrendPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    const left = 30.0;
    const right = 12.0;
    const top = 12.0;
    const bottom = 24.0;

    final chart = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );

    final gridPaint = Paint()
      ..color = const Color(0xFFE7EEEE)
      ..strokeWidth = 1;

    // FIX: Must be const because it is used by const TextSpan widgets below.
    const labelStyle = TextStyle(color: Colors.black45, fontSize: 9);

    for (var i = 0; i <= 4; i++) {
      final y = chart.top + chart.height * i / 4;

      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);

      final label = TextPainter(
        text: TextSpan(text: '${100 - i * 25}', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      label.paint(canvas, Offset(0, y - label.height / 2));
    }

    final points = <Offset>[];

    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? chart.center.dx
          : chart.left + chart.width * i / (values.length - 1);

      final y =
          chart.bottom -
          (values[i].clamp(0, 100).toDouble() / 100) * chart.height;

      points.add(Offset(x, y));
    }

    final line = Paint()
      ..color = DashboardScreen.primary
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(path, line);

    final dot = Paint()..color = DashboardScreen.primary;

    for (final point in points) {
      canvas.drawCircle(point, 4.5, dot);
    }

    final first = TextPainter(
      text: const TextSpan(text: 'Oldest', style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final last = TextPainter(
      text: const TextSpan(text: 'Latest', style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    first.paint(canvas, Offset(chart.left, size.height - first.height));

    last.paint(
      canvas,
      Offset(chart.right - last.width, size.height - last.height),
    );
  }

  @override
  bool shouldRepaint(covariant _MilestoneTrendPainter oldDelegate) =>
      oldDelegate.values != values;
}

class _ScreenTimeBarsPainter extends CustomPainter {
  final List<int> minutes;

  _ScreenTimeBarsPainter(this.minutes);

  @override
  void paint(Canvas canvas, Size size) {
    const left = 25.0;
    const right = 10.0;
    const top = 10.0;
    const bottom = 25.0;

    final chart = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );

    final maxValue = minutes
        .fold<int>(0, (a, b) => a > b ? a : b)
        .clamp(1, 100000)
        .toDouble();

    final grid = Paint()
      ..color = const Color(0xFFE7EEEE)
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = chart.top + chart.height * i / 4;

      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
    }

    final barPaint = Paint()..color = const Color(0xFFD58A42);

    final slot = chart.width / minutes.length;

    for (var i = 0; i < minutes.length; i++) {
      final barHeight = chart.height * minutes[i] / maxValue;

      final rect = Rect.fromLTWH(
        chart.left + slot * i + slot * 0.2,
        chart.bottom - barHeight,
        slot * 0.6,
        barHeight,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        barPaint,
      );

      final label = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(fontSize: 9, color: Colors.black45),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      label.paint(
        canvas,
        Offset(rect.center.dx - label.width / 2, size.height - label.height),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScreenTimeBarsPainter oldDelegate) =>
      oldDelegate.minutes != minutes;
}

// ================================================================
// NOTIFICATIONS SCREEN
// ================================================================

class _NotificationsScreen extends StatelessWidget {
  final String childName;

  const _NotificationsScreen({required this.childName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardScreen.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: DashboardScreen.background,
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: AppState.revision,
        builder: (context, revision, _) {
          final messages = AppState.notificationsFor(
            childName,
          ).map((record) => record.message).toList();

          if (messages.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 55,
                      color: DashboardScreen.primary,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'You are all caught up!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'New activity updates will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) => Card(
              elevation: 0,
              color: Colors.white,
              child: ListTile(
                leading: const Icon(
                  Icons.notifications_active_outlined,
                  color: DashboardScreen.primary,
                ),
                title: Text(messages[index]),
              ),
            ),
          );
        },
      ),
    );
  }
}
