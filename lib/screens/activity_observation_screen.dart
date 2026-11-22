import 'package:flutter/material.dart';

import '../app_state.dart';

class ActivityObservationScreen extends StatefulWidget {
  final String childName;

  const ActivityObservationScreen({super.key, required this.childName});

  @override
  State<ActivityObservationScreen> createState() =>
      _ActivityObservationScreenState();
}

class _ActivityObservationScreenState extends State<ActivityObservationScreen> {
  static const Color _primary = Color(0xFF287F83);
  static const Color _background = Color(0xFFF3F8F8);

  static const List<String> _activityTypes = [
    'Play',
    'Communication',
    'Social Interaction',
    'Daily Living',
    'Motor Skills',
    'Learning',
    'Other',
  ];

  List<ActivityObservationRecord> get _records =>
      AppState.observationsFor(widget.childName);

  Future<void> _openEditor({ActivityObservationRecord? existing}) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    final observationController = TextEditingController(
      text: existing?.observation ?? '',
    );
    var activityType = existing?.activityType ?? _activityTypes.first;
    var selectedDate = existing?.date ?? DateTime.now();
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> chooseDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setSheetState(() => selectedDate = picked);
              }
            }

            Future<void> save() async {
              if (saving || !formKey.currentState!.validate()) return;
              setSheetState(() => saving = true);

              final now = DateTime.now();
              final record = ActivityObservationRecord(
                id: existing?.id ?? AppState.createId(),
                childName: widget.childName,
                activityType: activityType,
                title: titleController.text.trim(),
                description: descriptionController.text.trim(),
                observation: observationController.text.trim(),
                date: DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                ),
                recordedAt: existing?.recordedAt ?? now,
              );

              if (existing == null) {
                AppState.addActivityObservation(record);
              } else {
                AppState.updateActivityObservation(record);
              }

              if (sheetContext.mounted) Navigator.pop(sheetContext);
              if (mounted) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      existing == null
                          ? 'Observation saved.'
                          : 'Observation updated.',
                    ),
                  ),
                );
              }
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          existing == null
                              ? 'Add activity observation'
                              : 'Edit activity observation',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF243B3D),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Record what you noticed during ${widget.childName}’s activity.',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 18),
                        DropdownButtonFormField<String>(
                          initialValue: activityType,
                          decoration: const InputDecoration(
                            labelText: 'Activity area',
                            border: OutlineInputBorder(),
                          ),
                          items: _activityTypes
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setSheetState(() => activityType = value);
                            }
                          },
                        ),
                        const SizedBox(height: 13),
                        TextFormField(
                          controller: titleController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Observation title',
                            hintText: 'e.g. Shared toys during play',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Enter a short title.'
                              : null,
                        ),
                        const SizedBox(height: 13),
                        TextFormField(
                          controller: descriptionController,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 2,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Activity description (optional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 13),
                        TextFormField(
                          controller: observationController,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'What did you observe?',
                            hintText:
                                'Describe what happened without making a diagnosis.',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Please describe the observation.'
                              : null,
                        ),
                        const SizedBox(height: 13),
                        OutlinedButton.icon(
                          onPressed: chooseDate,
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(
                            'Observation date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          ),
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: saving ? null : save,
                          style: FilledButton.styleFrom(
                            backgroundColor: _primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.save_outlined),
                          label: Text(
                            existing == null
                                ? 'Save observation'
                                : 'Update observation',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
    observationController.dispose();
  }

  Future<void> _delete(ActivityObservationRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete observation?'),
        content: const Text(
          'This observation will be removed from this device.',
        ),
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
    if (confirmed == true) AppState.deleteActivityObservation(record.id);
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Activity Observations'),
        backgroundColor: _background,
        foregroundColor: const Color(0xFF243B3D),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add observation'),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: AppState.revision,
          builder: (context, revision, _) {
            final records = _records;
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF287F83), Color(0xFF235B68)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.child_care, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Observations for',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              widget.childName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${records.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: records.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.visibility_outlined,
                                  size: 54,
                                  color: Colors.blueGrey.shade300,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No observations yet',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Add a note about an activity, interaction or skill you noticed.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black54,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                          itemCount: records.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 9),
                          itemBuilder: (context, index) {
                            final record = records[index];
                            return Card(
                              elevation: 0,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE2F3F1),
                                            borderRadius: BorderRadius.circular(
                                              11,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.visibility_outlined,
                                            color: _primary,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                record.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${record.activityType} • ${_date(record.date)}',
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'edit')
                                              _openEditor(existing: record);
                                            if (value == 'delete')
                                              _delete(record);
                                          },
                                          itemBuilder: (_) => const [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Text('Edit'),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (record.description.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        record.description,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                    const SizedBox(height: 9),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(11),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F8F8),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        record.observation,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          height: 1.45,
                                          color: Color(0xFF35585A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
