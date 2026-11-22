import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// ============================================================
// CHILD PROFILE RECORD
// ============================================================

class ChildProfileRecord {
  final String id;
  final String childName;
  final DateTime dateOfBirth;
  final String gender;
  final String parentName;
  final String parentEmail;
  final String relationship;
  final String phone;
  final DateTime createdAt;

  const ChildProfileRecord({
    required this.id,
    required this.childName,
    required this.dateOfBirth,
    required this.gender,
    required this.parentName,
    required this.parentEmail,
    required this.relationship,
    required this.phone,
    required this.createdAt,
  });

  int ageInMonthsAt([DateTime? at]) {
    final now = at ?? DateTime.now();
    var months =
        (now.year - dateOfBirth.year) * 12 + now.month - dateOfBirth.month;
    if (now.day < dateOfBirth.day) months--;
    return months;
  }

  int get ageInMonths => ageInMonthsAt();

  int get ageYears => ageInMonths ~/ 12;

  int get remainingAgeMonths => ageInMonths % 12;

  ChildProfileRecord copyWith({
    String? childName,
    DateTime? dateOfBirth,
    String? gender,
    String? parentName,
    String? parentEmail,
    String? relationship,
    String? phone,
  }) {
    return ChildProfileRecord(
      id: id,
      childName: childName ?? this.childName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      parentName: parentName ?? this.parentName,
      parentEmail: parentEmail ?? this.parentEmail,
      relationship: relationship ?? this.relationship,
      phone: phone ?? this.phone,
      createdAt: createdAt,
    );
  }
}

// ============================================================
// ASSESSMENT RECORD
// ============================================================

class AssessmentRecord {
  final String id;
  final String childName;
  final DateTime date;
  final Map<String, Map<String, int>> results;
  final Map<String, String> notes;

  const AssessmentRecord({
    this.id = '',
    required this.childName,
    required this.date,
    required this.results,
    required this.notes,
  });
}

// ============================================================
// MILESTONE RECORDS
// ============================================================

class MilestoneRecord {
  final String id;
  final String childName;
  final String milestoneTitle;
  final String category;
  final String ageRange;
  final String status;
  final String observation;
  final DateTime updatedAt;

  const MilestoneRecord({
    required this.id,
    required this.childName,
    required this.milestoneTitle,
    required this.category,
    required this.ageRange,
    required this.status,
    this.observation = '',
    required this.updatedAt,
  });

  MilestoneRecord copyWith({
    String? status,
    String? observation,
    DateTime? updatedAt,
  }) {
    return MilestoneRecord(
      id: id,
      childName: childName,
      milestoneTitle: milestoneTitle,
      category: category,
      ageRange: ageRange,
      status: status ?? this.status,
      observation: observation ?? this.observation,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class MilestoneHistoryRecord {
  final String id;
  final String childName;
  final String milestoneTitle;
  final String category;
  final String previousStatus;
  final String newStatus;
  final String observation;
  final DateTime date;

  const MilestoneHistoryRecord({
    required this.id,
    required this.childName,
    required this.milestoneTitle,
    required this.category,
    required this.previousStatus,
    required this.newStatus,
    required this.observation,
    required this.date,
  });
}

// ============================================================
// SCREEN TIME RECORD
// ============================================================

class ScreenTimeRecord {
  final String id;
  final String childName;
  final String device;
  final String activity;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final bool supervised;
  final String notes;
  final DateTime recordedAt;

  const ScreenTimeRecord({
    required this.id,
    required this.childName,
    required this.device,
    required this.activity,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.supervised,
    this.notes = '',
    required this.recordedAt,
  });
}

// ============================================================
// ACTIVITY OBSERVATION RECORD
// ============================================================

class ActivityObservationRecord {
  final String id;
  final String childName;
  final String activityType;
  final String title;
  final String description;
  final String observation;
  final DateTime date;
  final DateTime recordedAt;

  const ActivityObservationRecord({
    required this.id,
    required this.childName,
    required this.activityType,
    required this.title,
    this.description = '',
    required this.observation,
    required this.date,
    required this.recordedAt,
  });
}

// ============================================================
// CAMERA / VIDEO ANALYSIS RECORD
// ============================================================

class VideoAnalysisRecord {
  final String id;
  final String childName;
  final String filePath;
  final String fileName;
  final int durationSeconds;
  final DateTime recordedAt;
  final String source;
  final String notes;
  final String status;
  final String analysisSummary;

  const VideoAnalysisRecord({
    required this.id,
    required this.childName,
    required this.filePath,
    required this.fileName,
    required this.durationSeconds,
    required this.recordedAt,
    required this.source,
    this.notes = '',
    this.status = 'Pending',
    this.analysisSummary = '',
  });

  VideoAnalysisRecord copyWith({
    String? filePath,
    String? fileName,
    int? durationSeconds,
    DateTime? recordedAt,
    String? source,
    String? notes,
    String? status,
    String? analysisSummary,
  }) {
    return VideoAnalysisRecord(
      id: id,
      childName: childName,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      recordedAt: recordedAt ?? this.recordedAt,
      source: source ?? this.source,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      analysisSummary: analysisSummary ?? this.analysisSummary,
    );
  }
}

// ============================================================
// NOTIFICATION RECORD
// ============================================================

class AppNotification {
  final String id;
  final String childName;
  final String message;
  final String type;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.childName,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      childName: childName,
      message: message,
      type: type,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

// ============================================================
// CENTRAL APP STATE
// ============================================================

class AppState {
  AppState._();

  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static const String _storageKey = 'nurturesteps_local_state_v1';
  static bool _isInitialized = false;
  static Future<void> _saveQueue = Future<void>.value();

  /// Loads all saved NurtureSteps records before the first screen is shown.
  /// Safe to call once from main(); repeated calls do not reload/overwrite state.
  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final storageFile = File('${directory.path}/$_storageKey.json');
      final raw = await storageFile.exists()
          ? await storageFile.readAsString()
          : null;
      if (raw != null && raw.isNotEmpty) {
        final root = Map<String, dynamic>.from(jsonDecode(raw) as Map);

        childProfiles
          ..clear()
          ..addAll(_decodeList(root['childProfiles'], _childFromJson));
        selectedChildProfileId = root['selectedChildProfileId'] as String?;
        final savedConsent = root['parentConsent'];
        parentConsent = savedConsent is Map
            ? Map<String, dynamic>.from(savedConsent)
            : null;

        assessmentRecords
          ..clear()
          ..addAll(_decodeList(root['assessmentRecords'], _assessmentFromJson));
        milestoneItems
          ..clear()
          ..addAll(_decodeList(root['milestoneItems'], _milestoneFromJson));
        milestoneHistory
          ..clear()
          ..addAll(
            _decodeList(root['milestoneHistory'], _milestoneHistoryFromJson),
          );
        screenTimeItems
          ..clear()
          ..addAll(_decodeList(root['screenTimeItems'], _screenTimeFromJson));
        activityObservations
          ..clear()
          ..addAll(
            _decodeList(root['activityObservations'], _activityFromJson),
          );
        videoAnalysisRecords
          ..clear()
          ..addAll(_decodeList(root['videoAnalysisRecords'], _videoFromJson));
        notificationRecords
          ..clear()
          ..addAll(
            _decodeList(root['notificationRecords'], _notificationFromJson),
          );

        notifications
          ..clear()
          ..addAll(
            (root['notifications'] as List<dynamic>? ?? const [])
                .whereType<String>(),
          );
        milestoneRecords = milestoneItems.length;
        completedMilestones = milestoneItems
            .where((item) => item.status == 'Achieved')
            .length;
        screenTimeRecords = screenTimeItems.length;

        if (selectedChildProfileId != null &&
            !childProfiles.any((p) => p.id == selectedChildProfileId)) {
          selectedChildProfileId = childProfiles.isEmpty
              ? null
              : childProfiles.first.id;
        }
      }
    } catch (error, stackTrace) {
      // A damaged/older local snapshot must not prevent the app from opening.
      debugPrint('NurtureSteps local data could not be fully restored: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isInitialized = true;
      revision.value++;
    }
  }

  /// Waits until all queued local writes have completed (useful for tests).
  static Future<void> flushPersistence() => _saveQueue;

  static List<T> _decodeList<T>(
    dynamic value,
    T Function(Map<String, dynamic>) decode,
  ) {
    if (value is! List) return <T>[];
    return value
        .whereType<Map>()
        .map((item) => decode(Map<String, dynamic>.from(item)))
        .toList();
  }

  static DateTime _readDate(dynamic value) => DateTime.parse(value as String);
  static String _writeDate(DateTime value) => value.toIso8601String();

  static Map<String, dynamic> _childToJson(ChildProfileRecord r) => {
    'id': r.id,
    'childName': r.childName,
    'dateOfBirth': _writeDate(r.dateOfBirth),
    'gender': r.gender,
    'parentName': r.parentName,
    'parentEmail': r.parentEmail,
    'relationship': r.relationship,
    'phone': r.phone,
    'createdAt': _writeDate(r.createdAt),
  };
  static ChildProfileRecord _childFromJson(Map<String, dynamic> j) =>
      ChildProfileRecord(
        id: j['id'] as String,
        childName: j['childName'] as String,
        dateOfBirth: _readDate(j['dateOfBirth']),
        gender: j['gender'] as String,
        parentName: j['parentName'] as String,
        parentEmail: j['parentEmail'] as String,
        relationship: j['relationship'] as String,
        phone: j['phone'] as String,
        createdAt: _readDate(j['createdAt']),
      );

  static Map<String, dynamic> _assessmentToJson(AssessmentRecord r) => {
    'id': r.id,
    'childName': r.childName,
    'date': _writeDate(r.date),
    'results': r.results.map((k, v) => MapEntry(k, v)),
    'notes': r.notes,
  };
  static AssessmentRecord _assessmentFromJson(
    Map<String, dynamic> j,
  ) => AssessmentRecord(
    id: (j['id'] ?? createId()).toString(),
    childName: j['childName'] as String,
    date: _readDate(j['date']),
    results: (j['results'] as Map).map(
      (k, v) => MapEntry(
        k.toString(),
        Map<String, int>.from(
          (v as Map).map((a, b) => MapEntry(a.toString(), (b as num).toInt())),
        ),
      ),
    ),
    notes: Map<String, String>.from(
      (j['notes'] as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
    ),
  );

  static Map<String, dynamic> _milestoneToJson(MilestoneRecord r) => {
    'id': r.id,
    'childName': r.childName,
    'milestoneTitle': r.milestoneTitle,
    'category': r.category,
    'ageRange': r.ageRange,
    'status': r.status,
    'observation': r.observation,
    'updatedAt': _writeDate(r.updatedAt),
  };
  static MilestoneRecord _milestoneFromJson(Map<String, dynamic> j) =>
      MilestoneRecord(
        id: j['id'] as String,
        childName: j['childName'] as String,
        milestoneTitle: j['milestoneTitle'] as String,
        category: j['category'] as String,
        ageRange: j['ageRange'] as String,
        status: j['status'] as String,
        observation: (j['observation'] ?? '') as String,
        updatedAt: _readDate(j['updatedAt']),
      );

  static Map<String, dynamic> _milestoneHistoryToJson(
    MilestoneHistoryRecord r,
  ) => {
    'id': r.id,
    'childName': r.childName,
    'milestoneTitle': r.milestoneTitle,
    'category': r.category,
    'previousStatus': r.previousStatus,
    'newStatus': r.newStatus,
    'observation': r.observation,
    'date': _writeDate(r.date),
  };
  static MilestoneHistoryRecord _milestoneHistoryFromJson(
    Map<String, dynamic> j,
  ) => MilestoneHistoryRecord(
    id: j['id'] as String,
    childName: j['childName'] as String,
    milestoneTitle: j['milestoneTitle'] as String,
    category: j['category'] as String,
    previousStatus: j['previousStatus'] as String,
    newStatus: j['newStatus'] as String,
    observation: (j['observation'] ?? '') as String,
    date: _readDate(j['date']),
  );

  static Map<String, dynamic> _screenTimeToJson(ScreenTimeRecord r) => {
    'id': r.id,
    'childName': r.childName,
    'device': r.device,
    'activity': r.activity,
    'date': _writeDate(r.date),
    'startTime': _writeDate(r.startTime),
    'endTime': _writeDate(r.endTime),
    'durationMinutes': r.durationMinutes,
    'supervised': r.supervised,
    'notes': r.notes,
    'recordedAt': _writeDate(r.recordedAt),
  };
  static ScreenTimeRecord _screenTimeFromJson(Map<String, dynamic> j) =>
      ScreenTimeRecord(
        id: j['id'] as String,
        childName: j['childName'] as String,
        device: j['device'] as String,
        activity: j['activity'] as String,
        date: _readDate(j['date']),
        startTime: _readDate(j['startTime']),
        endTime: _readDate(j['endTime']),
        durationMinutes: (j['durationMinutes'] as num).toInt(),
        supervised: j['supervised'] as bool,
        notes: (j['notes'] ?? '') as String,
        recordedAt: _readDate(j['recordedAt']),
      );

  static Map<String, dynamic> _activityToJson(ActivityObservationRecord r) => {
    'id': r.id,
    'childName': r.childName,
    'activityType': r.activityType,
    'title': r.title,
    'description': r.description,
    'observation': r.observation,
    'date': _writeDate(r.date),
    'recordedAt': _writeDate(r.recordedAt),
  };
  static ActivityObservationRecord _activityFromJson(Map<String, dynamic> j) =>
      ActivityObservationRecord(
        id: j['id'] as String,
        childName: j['childName'] as String,
        activityType: j['activityType'] as String,
        title: j['title'] as String,
        description: (j['description'] ?? '') as String,
        observation: j['observation'] as String,
        date: _readDate(j['date']),
        recordedAt: _readDate(j['recordedAt']),
      );

  static Map<String, dynamic> _videoToJson(VideoAnalysisRecord r) => {
    'id': r.id,
    'childName': r.childName,
    'filePath': r.filePath,
    'fileName': r.fileName,
    'durationSeconds': r.durationSeconds,
    'recordedAt': _writeDate(r.recordedAt),
    'source': r.source,
    'notes': r.notes,
    'status': r.status,
    'analysisSummary': r.analysisSummary,
  };
  static VideoAnalysisRecord _videoFromJson(Map<String, dynamic> j) =>
      VideoAnalysisRecord(
        id: j['id'] as String,
        childName: j['childName'] as String,
        filePath: j['filePath'] as String,
        fileName: j['fileName'] as String,
        durationSeconds: (j['durationSeconds'] as num).toInt(),
        recordedAt: _readDate(j['recordedAt']),
        source: j['source'] as String,
        notes: (j['notes'] ?? '') as String,
        status: (j['status'] ?? 'Pending') as String,
        analysisSummary: (j['analysisSummary'] ?? '') as String,
      );

  static Map<String, dynamic> _notificationToJson(AppNotification r) => {
    'id': r.id,
    'childName': r.childName,
    'message': r.message,
    'type': r.type,
    'createdAt': _writeDate(r.createdAt),
    'isRead': r.isRead,
  };
  static AppNotification _notificationFromJson(Map<String, dynamic> j) =>
      AppNotification(
        id: j['id'] as String,
        childName: j['childName'] as String,
        message: j['message'] as String,
        type: j['type'] as String,
        createdAt: _readDate(j['createdAt']),
        isRead: j['isRead'] as bool? ?? false,
      );

  static void _scheduleSave() {
    _saveQueue = _saveQueue.then((_) => _writeSnapshot()).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      debugPrint('NurtureSteps local save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    });
  }

  static Future<void> _writeSnapshot() async {
    final directory = await getApplicationDocumentsDirectory();
    final storageFile = File('${directory.path}/$_storageKey.json');
    final temporaryFile = File('${storageFile.path}.tmp');
    final snapshot = <String, dynamic>{
      'childProfiles': childProfiles.map(_childToJson).toList(),
      'selectedChildProfileId': selectedChildProfileId,
      'parentConsent': parentConsent,
      'assessmentRecords': assessmentRecords.map(_assessmentToJson).toList(),
      'milestoneItems': milestoneItems.map(_milestoneToJson).toList(),
      'milestoneHistory': milestoneHistory
          .map(_milestoneHistoryToJson)
          .toList(),
      'screenTimeItems': screenTimeItems.map(_screenTimeToJson).toList(),
      'activityObservations': activityObservations
          .map(_activityToJson)
          .toList(),
      'videoAnalysisRecords': videoAnalysisRecords.map(_videoToJson).toList(),
      'notificationRecords': notificationRecords
          .map(_notificationToJson)
          .toList(),
      'notifications': notifications,
    };
    await temporaryFile.writeAsString(jsonEncode(snapshot), flush: true);
    if (await storageFile.exists()) {
      await storageFile.delete();
    }
    await temporaryFile.rename(storageFile.path);
  }

  // App records are held in memory while the app is running and persisted
  // locally on this device using a local JSON file. No cloud service
  // or remote database is used. DOB is stored once; age is calculated live.
  static final List<ChildProfileRecord> childProfiles = [];
  static String? selectedChildProfileId;
  static Map<String, dynamic>? parentConsent;

  static void saveParentConsent(Map<String, dynamic> consent) {
    parentConsent = Map<String, dynamic>.from(consent);
    _changed();
  }

  static ChildProfileRecord? get selectedChildProfile {
    final id = selectedChildProfileId;
    if (id == null) return null;
    for (final profile in childProfiles) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  static List<ChildProfileRecord> get allChildProfiles =>
      List.unmodifiable(childProfiles);

  static ChildProfileRecord? childProfileById(String id) {
    for (final profile in childProfiles) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  static ChildProfileRecord? childProfileFor(String childName) {
    for (final profile in childProfiles) {
      if (profile.childName == childName) return profile;
    }
    return null;
  }

  static bool addChildProfile(ChildProfileRecord profile) {
    final duplicate = childProfiles.any(
      (item) =>
          item.id == profile.id ||
          (item.childName.trim().toLowerCase() ==
                  profile.childName.trim().toLowerCase() &&
              item.dateOfBirth.year == profile.dateOfBirth.year &&
              item.dateOfBirth.month == profile.dateOfBirth.month &&
              item.dateOfBirth.day == profile.dateOfBirth.day),
    );
    if (duplicate) return false;

    final age = profile.ageInMonths;
    if (profile.dateOfBirth.isAfter(DateTime.now()) || age < 12 || age >= 72) {
      return false;
    }

    childProfiles.add(profile);
    // The profile just created becomes the active child immediately.
    selectedChildProfileId = profile.id;
    _insertNotification(
      'A child profile was created for ${profile.childName}.',
      childName: profile.childName,
      type: 'Child Profile',
    );
    _changed();
    return true;
  }

  // IDs of children that came from the backend in this app run. Used to pick
  // backend history over the legacy local prototype records.
  static final Set<String> _backendChildIds = <String>{};

  /// Remembers a child that was loaded from the backend and makes it active.
  ///
  /// Backend profiles carry the real server ID and are authoritative, so they
  /// are not filtered by the legacy local age rule in [addChildProfile].
  static void rememberBackendChild(ChildProfileRecord profile) {
    final index = childProfiles.indexWhere((item) => item.id == profile.id);

    if (index >= 0) {
      childProfiles[index] = profile;
    } else {
      childProfiles.add(profile);
    }

    _backendChildIds.add(profile.id);
    selectedChildProfileId = profile.id;
    _changed();
  }

  static bool isBackendChild(String? childId) {
    return childId != null && _backendChildIds.contains(childId);
  }

  /// Notifies listeners that backend assessment history changed (for example
  /// after a successful submission) so history views can refresh.
  static final ValueNotifier<int> assessmentHistoryRevision =
      ValueNotifier<int>(0);

  static void notifyAssessmentHistoryChanged() {
    assessmentHistoryRevision.value++;
  }

  static bool selectChildProfile(String profileId) {
    if (!childProfiles.any((profile) => profile.id == profileId)) {
      return false;
    }
    if (selectedChildProfileId == profileId) return true;
    selectedChildProfileId = profileId;
    _changed();
    return true;
  }

  static bool updateChildProfile(ChildProfileRecord updatedProfile) {
    final index = childProfiles.indexWhere(
      (profile) => profile.id == updatedProfile.id,
    );
    if (index < 0) return false;

    final age = updatedProfile.ageInMonths;
    if (updatedProfile.dateOfBirth.isAfter(DateTime.now()) ||
        age < 12 ||
        age >= 72) {
      return false;
    }

    childProfiles[index] = updatedProfile;
    _insertNotification(
      'The child profile for ${updatedProfile.childName} was updated.',
      childName: updatedProfile.childName,
      type: 'Child Profile',
    );
    _changed();
    return true;
  }

  static bool deleteChildProfile(String profileId) {
    final index = childProfiles.indexWhere(
      (profile) => profile.id == profileId,
    );
    if (index < 0) return false;

    final removed = childProfiles.removeAt(index);
    // Existing feature records are associated by childName for compatibility.
    // Do not cascade-delete them: names may be shared and history should not
    // be silently destroyed by removing a profile card.
    if (selectedChildProfileId == profileId) {
      selectedChildProfileId = childProfiles.isEmpty
          ? null
          : childProfiles.first.id;
    }
    _insertNotification(
      'The child profile for ${removed.childName} was removed.',
      childName: removed.childName,
      type: 'Child Profile',
    );
    _changed();
    return true;
  }

  static final List<AssessmentRecord> assessmentRecords = [];

  static final List<MilestoneRecord> milestoneItems = [];
  static final List<MilestoneHistoryRecord> milestoneHistory = [];

  static final List<ScreenTimeRecord> screenTimeItems = [];

  static final List<ActivityObservationRecord> activityObservations = [];

  // Camera recordings and selected videos, linked to a child.
  static final List<VideoAnalysisRecord> videoAnalysisRecords = [];

  static final List<AppNotification> notificationRecords = [];

  // Legacy notification list retained for compatibility.
  static final List<String> notifications = [];

  static int milestoneRecords = 0;
  static int completedMilestones = 0;
  static int screenTimeRecords = 0;

  static String createId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  // Notify listeners once after a complete state operation.
  static void _changed() {
    revision.value++;
    if (_isInitialized) _scheduleSave();
  }

  // Add a notification without triggering a separate rebuild.
  // The calling operation is responsible for calling _changed().
  static void _insertNotification(
    String message, {
    String childName = '',
    String type = 'General',
  }) {
    notifications.insert(0, message);

    notificationRecords.insert(
      0,
      AppNotification(
        id: createId(),
        childName: childName,
        message: message,
        type: type,
        createdAt: DateTime.now(),
      ),
    );

    if (notifications.length > 300) {
      notifications.removeRange(300, notifications.length);
    }

    if (notificationRecords.length > 300) {
      notificationRecords.removeRange(300, notificationRecords.length);
    }
  }

  // ==========================================================
  // ASSESSMENT DRAFTS
  // ==========================================================

  // In-memory only: the backend has no draft endpoint, so unfinished
  // questionnaire answers survive leaving and re-entering the screen during
  // the current app run, but not an app restart.
  static final Map<String, Map<String, String>> _assessmentDrafts = {};

  static Map<String, String> assessmentDraftFor(String childId) {
    return Map<String, String>.from(_assessmentDrafts[childId] ?? const {});
  }

  static void saveAssessmentDraft(
    String childId,
    Map<String, String> answers,
  ) {
    _assessmentDrafts[childId] = Map<String, String>.from(answers);
  }

  static void clearAssessmentDraft(String childId) {
    _assessmentDrafts.remove(childId);
  }

  // ==========================================================
  // ASSESSMENTS
  // ==========================================================

  static void addAssessment(AssessmentRecord record) {
    assessmentRecords.insert(0, record);

    _insertNotification(
      'A new developmental assessment was recorded for ${record.childName}.',
      childName: record.childName,
      type: 'Assessment',
    );

    _changed();
  }

  static List<AssessmentRecord> assessmentsFor(String childName) {
    return assessmentRecords
        .where((record) => record.childName == childName)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ==========================================================
  // MILESTONES
  // ==========================================================

  static List<MilestoneRecord> milestonesFor(String childName) {
    return milestoneItems
        .where((record) => record.childName == childName)
        .toList();
  }

  static List<MilestoneHistoryRecord> milestoneHistoryFor(String childName) {
    return milestoneHistory
        .where((record) => record.childName == childName)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Seeds the age-appropriate milestone list without creating artificial
  /// history entries or user notifications. Existing records are preserved.
  static void ensureMilestones(List<MilestoneRecord> records) {
    var changed = false;
    for (final record in records) {
      final exists = milestoneItems.any(
        (item) =>
            item.childName == record.childName &&
            item.milestoneTitle == record.milestoneTitle,
      );
      if (!exists) {
        milestoneItems.add(record);
        changed = true;
      }
    }
    if (changed) {
      _updateMilestoneCounts();
      _changed();
    }
  }

  static void addMilestone(MilestoneRecord record) {
    final index = milestoneItems.indexWhere(
      (item) =>
          item.childName == record.childName &&
          item.milestoneTitle == record.milestoneTitle,
    );

    if (index >= 0) {
      updateMilestone(record);
      return;
    }

    milestoneItems.add(record);

    milestoneHistory.insert(
      0,
      MilestoneHistoryRecord(
        id: createId(),
        childName: record.childName,
        milestoneTitle: record.milestoneTitle,
        category: record.category,
        previousStatus: 'Not Recorded',
        newStatus: record.status,
        observation: record.observation,
        date: record.updatedAt,
      ),
    );

    _updateMilestoneCounts();

    _insertNotification(
      'A milestone was recorded for ${record.childName}: ${record.milestoneTitle}.',
      childName: record.childName,
      type: 'Milestone',
    );

    _changed();
  }

  static void updateMilestone(MilestoneRecord updatedRecord) {
    final index = milestoneItems.indexWhere(
      (item) => item.id == updatedRecord.id,
    );

    if (index < 0) {
      final fallbackIndex = milestoneItems.indexWhere(
        (item) =>
            item.childName == updatedRecord.childName &&
            item.milestoneTitle == updatedRecord.milestoneTitle,
      );

      if (fallbackIndex < 0) return;

      final oldRecord = milestoneItems[fallbackIndex];
      milestoneItems[fallbackIndex] = updatedRecord;

      _addMilestoneHistory(oldRecord, updatedRecord);
    } else {
      final oldRecord = milestoneItems[index];
      milestoneItems[index] = updatedRecord;

      _addMilestoneHistory(oldRecord, updatedRecord);
    }

    _updateMilestoneCounts();

    _insertNotification(
      'Milestone status updated for ${updatedRecord.childName}: ${updatedRecord.milestoneTitle}.',
      childName: updatedRecord.childName,
      type: 'Milestone',
    );

    _changed();
  }

  static void _addMilestoneHistory(
    MilestoneRecord oldRecord,
    MilestoneRecord newRecord,
  ) {
    milestoneHistory.insert(
      0,
      MilestoneHistoryRecord(
        id: createId(),
        childName: newRecord.childName,
        milestoneTitle: newRecord.milestoneTitle,
        category: newRecord.category,
        previousStatus: oldRecord.status,
        newStatus: newRecord.status,
        observation: newRecord.observation,
        date: newRecord.updatedAt,
      ),
    );
  }

  static void deleteMilestone(String id) {
    final index = milestoneItems.indexWhere((item) => item.id == id);
    if (index < 0) return;

    final childName = milestoneItems[index].childName;
    milestoneItems.removeAt(index);

    _updateMilestoneCounts();

    _insertNotification(
      'A milestone record was removed for $childName.',
      childName: childName,
      type: 'Milestone',
    );

    _changed();
  }

  static void _updateMilestoneCounts() {
    milestoneRecords = milestoneItems.length;
    completedMilestones = milestoneItems
        .where((item) => item.status == 'Achieved')
        .length;
  }

  static void updateMilestoneCounts({
    required int total,
    required int completed,
  }) {
    // Retained for compatibility with older screens. Record-backed counts
    // remain the source of truth whenever milestone records exist.
    if (milestoneItems.isEmpty) {
      milestoneRecords = total;
      completedMilestones = completed;
    } else {
      _updateMilestoneCounts();
    }
    _changed();
  }

  // ==========================================================
  // SCREEN TIME
  // ==========================================================

  static List<ScreenTimeRecord> screenTimeFor(String childName) {
    return screenTimeItems
        .where((record) => record.childName == childName)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  static void addScreenTime(ScreenTimeRecord record) {
    // A new record must have its own ID.
    // Prevent accidental insertion of the same ID twice.
    final duplicate = screenTimeItems.any((item) => item.id == record.id);

    if (duplicate) return;

    screenTimeItems.add(record);
    screenTimeRecords = screenTimeItems.length;

    _insertNotification(
      'A screen-time record was added for ${record.childName}.',
      childName: record.childName,
      type: 'Screen Time',
    );

    // One revision update for the record and its notification.
    _changed();
  }

  static void updateScreenTime(ScreenTimeRecord updatedRecord) {
    final index = screenTimeItems.indexWhere(
      (record) => record.id == updatedRecord.id,
    );

    if (index < 0) return;

    screenTimeItems[index] = updatedRecord;

    _insertNotification(
      'A screen-time record was updated for ${updatedRecord.childName}.',
      childName: updatedRecord.childName,
      type: 'Screen Time',
    );

    screenTimeRecords = screenTimeItems.length;

    _changed();
  }

  static void deleteScreenTime(String id) {
    final index = screenTimeItems.indexWhere((record) => record.id == id);

    if (index < 0) return;

    final childName = screenTimeItems[index].childName;
    screenTimeItems.removeAt(index);
    screenTimeRecords = screenTimeItems.length;

    _insertNotification(
      'A screen-time record was deleted for $childName.',
      childName: childName,
      type: 'Screen Time',
    );

    _changed();
  }

  // Compatibility method for older screens.
  static void addScreenTimeRecord() {
    screenTimeRecords++;
    _changed();
  }

  // ==========================================================
  // ACTIVITY OBSERVATIONS
  // ==========================================================

  static List<ActivityObservationRecord> observationsFor(String childName) {
    return activityObservations
        .where((record) => record.childName == childName)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static void addActivityObservation(ActivityObservationRecord record) {
    activityObservations.insert(0, record);

    _insertNotification(
      'A new activity observation was recorded for ${record.childName}.',
      childName: record.childName,
      type: 'Activity Observation',
    );

    _changed();
  }

  static void updateActivityObservation(
    ActivityObservationRecord updatedRecord,
  ) {
    final index = activityObservations.indexWhere(
      (record) => record.id == updatedRecord.id,
    );

    if (index < 0) return;

    activityObservations[index] = updatedRecord;

    _insertNotification(
      'An activity observation was updated for ${updatedRecord.childName}.',
      childName: updatedRecord.childName,
      type: 'Activity Observation',
    );

    _changed();
  }

  static void deleteActivityObservation(String id) {
    final index = activityObservations.indexWhere((record) => record.id == id);

    if (index < 0) return;

    final childName = activityObservations[index].childName;
    activityObservations.removeAt(index);

    _insertNotification(
      'An activity observation was deleted for $childName.',
      childName: childName,
      type: 'Activity Observation',
    );

    _changed();
  }

  // ==========================================================
  // CAMERA / VIDEO ANALYSIS RECORDS
  // ==========================================================

  static List<VideoAnalysisRecord> videoAnalysesFor(String childName) {
    return videoAnalysisRecords
        .where((record) => record.childName == childName)
        .toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
  }

  static void addVideoAnalysis(VideoAnalysisRecord record) {
    final duplicate = videoAnalysisRecords.any((item) => item.id == record.id);

    if (duplicate) return;

    videoAnalysisRecords.insert(0, record);

    _insertNotification(
      'A video was added for ${record.childName}.',
      childName: record.childName,
      type: 'Video Analysis',
    );

    _changed();
  }

  static void updateVideoAnalysis(VideoAnalysisRecord updatedRecord) {
    final index = videoAnalysisRecords.indexWhere(
      (record) => record.id == updatedRecord.id,
    );

    if (index < 0) return;

    videoAnalysisRecords[index] = updatedRecord;

    _insertNotification(
      'A video record was updated for ${updatedRecord.childName}.',
      childName: updatedRecord.childName,
      type: 'Video Analysis',
    );

    _changed();
  }

  static void deleteVideoAnalysis(String id) {
    final index = videoAnalysisRecords.indexWhere((record) => record.id == id);

    if (index < 0) return;

    final childName = videoAnalysisRecords[index].childName;
    videoAnalysisRecords.removeAt(index);

    _insertNotification(
      'A video record was removed for $childName.',
      childName: childName,
      type: 'Video Analysis',
    );

    _changed();
  }

  // ==========================================================
  // NOTIFICATIONS
  // ==========================================================

  static void addNotification(
    String message, {
    String childName = '',
    String type = 'General',
  }) {
    _insertNotification(message, childName: childName, type: type);

    _changed();
  }

  static List<AppNotification> notificationsFor(String childName) {
    return notificationRecords
        .where(
          (record) => record.childName.isEmpty || record.childName == childName,
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static void markNotificationRead(String id) {
    final index = notificationRecords.indexWhere((record) => record.id == id);

    if (index < 0) return;

    notificationRecords[index] = notificationRecords[index].copyWith(
      isRead: true,
    );

    _changed();
  }

  static void markAllNotificationsRead(String childName) {
    for (var i = 0; i < notificationRecords.length; i++) {
      final record = notificationRecords[i];

      if (record.childName == childName && !record.isRead) {
        notificationRecords[i] = record.copyWith(isRead: true);
      }
    }

    _changed();
  }

  // ==========================================================
  // DASHBOARD HELPERS
  // ==========================================================

  static int unreadNotificationCountFor(String childName) {
    return notificationRecords
        .where(
          (record) =>
              (record.childName.isEmpty || record.childName == childName) &&
              !record.isRead,
        )
        .length;
  }

  static int totalScreenTimeMinutesFor(String childName) {
    return screenTimeItems
        .where((record) => record.childName == childName)
        .fold<int>(0, (total, record) => total + record.durationMinutes);
  }

  static int completedMilestoneCountFor(String childName) =>
      completedMilestonesFor(childName);

  static int assessmentCountFor(String childName) {
    return assessmentRecords
        .where((record) => record.childName == childName)
        .length;
  }

  static int completedMilestonesFor(String childName) {
    return milestoneItems
        .where(
          (record) =>
              record.childName == childName && record.status == 'Achieved',
        )
        .length;
  }

  static int totalMilestonesFor(String childName) {
    return milestoneItems
        .where((record) => record.childName == childName)
        .length;
  }

  static int screenTimeRecordCountFor(String childName) {
    return screenTimeItems
        .where((record) => record.childName == childName)
        .length;
  }

  static int videoAnalysisCountFor(String childName) {
    return videoAnalysisRecords
        .where((record) => record.childName == childName)
        .length;
  }

  static int activityObservationCountFor(String childName) {
    return activityObservations
        .where((record) => record.childName == childName)
        .length;
  }
}
