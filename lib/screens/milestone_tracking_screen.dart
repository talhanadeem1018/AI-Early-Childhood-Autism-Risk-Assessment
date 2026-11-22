import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data/cdc_milestone_data.dart';

class MilestoneTrackingScreen extends StatefulWidget {
  final String childName;
  final DateTime dateOfBirth;

  const MilestoneTrackingScreen({
    super.key,
    required this.childName,
    required this.dateOfBirth,
  });

  @override
  State<MilestoneTrackingScreen> createState() =>
      _MilestoneTrackingScreenState();
}

class _MilestoneTrackingScreenState extends State<MilestoneTrackingScreen> {
  static const Color primary = Color(0xFF347F83);
  static const Color background = Color(0xFFF5F8F8);

  String selectedCategory = 'All';

  final List<String> categories = [
    'All',
    'Motor',
    'Language',
    'Social',
    'Cognitive',
  ];

  late final List<MilestoneItem> milestones;

  List<MilestoneHistory> get history {
    return AppState.milestoneHistoryFor(widget.childName)
        .map(
          (record) => MilestoneHistory(
            title: record.milestoneTitle,
            oldStatus: record.previousStatus,
            newStatus: record.newStatus,
            note: record.observation,
            date: record.date,
          ),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _initializeMilestones();
  }

  void _initializeMilestones() {
    final age = ageInMonths;
    final checklistAge = CdcMilestoneData.checklistAgeMonths(age);
    final sourceChecklist = CdcMilestoneData.checklistForAge(age);
    final savedRecords = AppState.milestonesFor(widget.childName);

    final templates = <MilestoneItem>[];
    for (final domain in sourceChecklist.entries) {
      final category = domain.key.startsWith('Social')
          ? 'Social'
          : domain.key.startsWith('Language')
          ? 'Language'
          : domain.key.startsWith('Cognitive')
          ? 'Cognitive'
          : 'Motor';
      for (final title in domain.value) {
        MilestoneRecord? existing;
        for (final saved in savedRecords) {
          if (saved.milestoneTitle == title) {
            existing = saved;
            break;
          }
        }
        templates.add(
          MilestoneItem(
            id: existing?.id ?? AppState.createId(),
            title: title,
            category: category,
            description:
                'CDC developmental milestone. Source: ${CdcMilestoneData.sourceForAge(age)}',
            ageRange: 'By $checklistAge months',
            status: existing?.status ?? 'Not Started',
            note: existing?.observation ?? '',
          ),
        );
      }
    }

    final newRecords = templates
        .where(
          (item) =>
              !savedRecords.any((saved) => saved.milestoneTitle == item.title),
        )
        .map(
          (item) => MilestoneRecord(
            id: item.id,
            childName: widget.childName,
            milestoneTitle: item.title,
            category: item.category,
            ageRange: item.ageRange,
            status: item.status,
            observation: item.note,
            updatedAt: DateTime.now(),
          ),
        )
        .toList();

    AppState.ensureMilestones(newRecords);
    milestones = templates;
  }

  int get ageInMonths {
    final now = DateTime.now();

    int months =
        (now.year - widget.dateOfBirth.year) * 12 +
        now.month -
        widget.dateOfBirth.month;

    if (now.day < widget.dateOfBirth.day) {
      months--;
    }

    return months < 0 ? 0 : months;
  }

  List<MilestoneItem> get filteredMilestones {
    if (selectedCategory == 'All') {
      return milestones;
    }

    return milestones
        .where((item) => item.category == selectedCategory)
        .toList();
  }

  int get achievedCount =>
      milestones.where((item) => item.status == 'Achieved').length;

  int get inProgressCount =>
      milestones.where((item) => item.status == 'In Progress').length;

  int get notAchievedCount =>
      milestones.where((item) => item.status == 'Not Achieved').length;

  void updateMilestone(MilestoneItem item, String newStatus, String note) {
    final now = DateTime.now();

    final updatedRecord = MilestoneRecord(
      id: item.id,
      childName: widget.childName,
      milestoneTitle: item.title,
      category: item.category,
      ageRange: item.ageRange,
      status: newStatus,
      observation: note,
      updatedAt: now,
    );

    AppState.updateMilestone(updatedRecord);

    setState(() {
      item.status = newStatus;
      item.note = note;
    });
  }

  Future<void> editMilestone(MilestoneItem item) async {
    String temporaryStatus = item.status;

    final controller = TextEditingController(text: item.note);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                item.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Milestone Status',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: temporaryStatus,
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Not Started',
                          child: Text('Not Started'),
                        ),
                        DropdownMenuItem(
                          value: 'In Progress',
                          child: Text('In Progress'),
                        ),
                        DropdownMenuItem(
                          value: 'Achieved',
                          child: Text('Achieved'),
                        ),
                        DropdownMenuItem(
                          value: 'Not Achieved',
                          child: Text('Not Achieved'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            temporaryStatus = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Parent Observation',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: controller,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            'Describe what you observed about your child...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);

                    updateMilestone(
                      item,
                      temporaryStatus,
                      controller.text.trim(),
                    );
                  },
                  child: const Text('Save Record'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
  }

  Color statusColor(String status) {
    switch (status) {
      case 'Achieved':
        return Colors.green;
      case 'In Progress':
        return Colors.orange;
      case 'Not Achieved':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  IconData categoryIcon(String category) {
    switch (category) {
      case 'Motor':
        return Icons.directions_run;
      case 'Language':
        return Icons.record_voice_over;
      case 'Social':
        return Icons.people_alt_outlined;
      default:
        return Icons.psychology_outlined;
    }
  }

  String get ageText {
    final years = ageInMonths ~/ 12;
    final months = ageInMonths % 12;

    if (years == 0) return '$months months';
    if (months == 0) return '$years years';

    return '$years years, $months months';
  }

  @override
  Widget build(BuildContext context) {
    final progress = milestones.isEmpty
        ? 0.0
        : achievedCount / milestones.length;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        foregroundColor: const Color(0xFF243B40),
        title: const Text(
          'Milestone Tracking',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 950),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF347F83), Color(0xFF235B68)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 29,
                          backgroundColor: Colors.white24,
                          child: Icon(
                            Icons.child_care,
                            color: Colors.white,
                            size: 35,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.childName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Current age: $ageText',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Milestone Progress',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF243B40),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Achieved milestones',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${(progress * 100).round()}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primary,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: Colors.grey.shade200,
                            color: primary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _statItem(
                                'Achieved',
                                achievedCount,
                                Colors.green,
                              ),
                            ),
                            Expanded(
                              child: _statItem(
                                'In Progress',
                                inProgressCount,
                                Colors.orange,
                              ),
                            ),
                            Expanded(
                              child: _statItem(
                                'Not Achieved',
                                notAchievedCount,
                                Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Development Domains',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF243B40),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((category) {
                      final selected = selectedCategory == category;

                      return ChoiceChip(
                        label: Text(category),
                        selected: selected,
                        selectedColor: const Color(0xFF347F83),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF36565A),
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Milestone Checklist',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF243B40),
                        ),
                      ),
                      Text(
                        '${filteredMilestones.length} items',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...filteredMilestones.map((item) => _milestoneCard(item)),
                  const SizedBox(height: 28),
                  const Text(
                    'Recent Activity History',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF243B40),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (history.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.history, size: 35, color: Colors.blueGrey),
                          SizedBox(height: 10),
                          Text(
                            'No activity recorded yet.',
                            style: TextStyle(color: Colors.black54),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Your milestone updates will appear here.',
                            style: TextStyle(
                              color: Colors.black45,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...history.map((record) => _historyCard(record)),
                  const SizedBox(height: 25),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1F1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: primary),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Developmental milestones are general '
                            'observations, not diagnostic criteria. '
                            'Children develop at different rates. '
                            'Consult a qualified healthcare professional '
                            'if you have concerns.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: Color(0xFF36565A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statItem(String title, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _milestoneCard(MilestoneItem item) {
    final color = statusColor(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => editMilestone(item),
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      categoryIcon(item.category),
                      color: primary,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF243B40),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${item.category} • ${item.ageRange}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.edit_outlined, color: color, size: 21),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                item.description,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Update',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: primary),
                ],
              ),
              if (item.note.isNotEmpty) ...[
                const Divider(height: 22),
                Text(
                  'Parent Observation: ${item.note}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF36565A),
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyCard(MilestoneHistory record) {
    final color = statusColor(record.newStatus);

    final date = record.date;

    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';

    final formattedTime =
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            record.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '${record.oldStatus} → ${record.newStatus}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          if (record.note.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              record.note,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '$formattedDate at $formattedTime',
            style: const TextStyle(color: Colors.black45, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// MILESTONE MODEL
class MilestoneItem {
  final String id;
  final String title;
  final String category;
  final String description;
  final String ageRange;

  String status;
  String note;

  MilestoneItem({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.ageRange,
    this.status = 'Not Started',
    this.note = '',
  });
}

// HISTORY MODEL
class MilestoneHistory {
  final String title;
  final String oldStatus;
  final String newStatus;
  final String note;
  final DateTime date;

  MilestoneHistory({
    required this.title,
    required this.oldStatus,
    required this.newStatus,
    required this.note,
    required this.date,
  });
}
