import '../config/app_config.dart';
import 'api_client.dart';

/// One question from `GET /api/v1/assessment/questionnaire/{child_id}`.
///
/// The backend returns the Supabase `assessment_questions` row unchanged inside
/// the standard `data` envelope. `id`, `domain` and `question_type` are read
/// directly; the wording column is read from `question_text` (with `text` as a
/// tolerated alias).
class AssessmentQuestion {
  const AssessmentQuestion({
    required this.id,
    required this.text,
    required this.domain,
    required this.questionType,
  });

  final String id;
  final String text;
  final String domain;
  final String questionType;

  factory AssessmentQuestion.fromApiData(Map<String, dynamic> data) {
    final id = (data['id'] ?? '').toString();
    final text = _firstText(data, const ['question_text', 'text']);
    final domain = (data['domain'] ?? '').toString();
    final questionType = (data['question_type'] ?? '').toString();

    if (id.isEmpty || text.isEmpty) {
      throw const ApiException(
        0,
        'The questionnaire returned a question without an ID or text.',
      );
    }

    return AssessmentQuestion(
      id: id,
      text: text,
      domain: domain,
      questionType: questionType,
    );
  }

  static String _firstText(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }
}

/// One selectable answer from `assessment_answer_options`.
///
/// The submitted value is always the backend `option_value` (for example
/// `usually`). The visible label comes from `option_label`/`label` when the
/// backend provides one, otherwise it is derived from the value.
class AssessmentAnswerOption {
  const AssessmentAnswerOption({
    required this.value,
    required this.label,
    this.sortOrder,
  });

  final String value;
  final String label;
  final int? sortOrder;

  factory AssessmentAnswerOption.fromApiData(Map<String, dynamic> data) {
    final value = (data['option_value'] ?? '').toString().trim();
    final label = _firstText(data, const ['option_label', 'label']);

    if (value.isEmpty) {
      throw const ApiException(
        0,
        'The questionnaire returned an answer option without a value.',
      );
    }

    final rawSort = data['sort_order'];

    return AssessmentAnswerOption(
      value: value,
      label: label.isEmpty ? _humanize(value) : label,
      sortOrder: rawSort is num ? rawSort.toInt() : null,
    );
  }

  static String _firstText(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  static String _humanize(String value) {
    final words = value.replaceAll('_', ' ').trim();
    if (words.isEmpty) return value;
    return words[0].toUpperCase() + words.substring(1);
  }
}

/// The age-appropriate questionnaire returned by the backend.
class AssessmentQuestionnaire {
  const AssessmentQuestionnaire({
    required this.childId,
    required this.totalMonths,
    required this.ageGroup,
    required this.questions,
    required this.options,
  });

  final String childId;
  final int totalMonths;
  final String ageGroup;
  final List<AssessmentQuestion> questions;
  final List<AssessmentAnswerOption> options;

  /// Preferred display order for the current backend answer values when the
  /// answer options table has no `sort_order` column.
  static const List<String> canonicalOptionOrder = [
    'usually',
    'sometimes',
    'rarely',
    'not_sure',
  ];
}

/// One domain row from the backend-scored result.
class AssessmentDomainResult {
  const AssessmentDomainResult({
    required this.domain,
    this.concernPercentage,
    this.countedQuestions,
  });

  final String domain;
  final double? concernPercentage;
  final int? countedQuestions;
}

/// A parent-concern answer returned by the backend.
///
/// The backend returns only `question_id` and `answer` here, so the question
/// wording is resolved from the loaded questionnaire when available.
class AssessmentParentConcern {
  const AssessmentParentConcern({
    required this.questionId,
    required this.answer,
  });

  final String questionId;
  final String answer;
}

/// The backend-scored result from `POST /api/v1/assessment/submit`.
///
/// Flutter only reads these values; no score or concern level is calculated
/// on the client. Fields the backend did not return stay null and are omitted
/// from the result screen.
class AssessmentResult {
  const AssessmentResult({
    required this.childId,
    required this.concernLevel,
    this.status = '',
    this.concernPercentage,
    this.totalScore,
    this.maximumScore,
    this.countedAnswers,
    this.notSureAnswers,
    this.domains = const [],
    this.parentConcerns = const [],
    this.disclaimer = '',
    this.ageGroup = '',
    this.ageYears,
    this.ageMonths,
    this.totalMonths,
    this.recordedAt,
  });

  final String childId;
  final String concernLevel;
  final String status;
  final double? concernPercentage;
  final int? totalScore;
  final int? maximumScore;
  final int? countedAnswers;
  final int? notSureAnswers;
  final List<AssessmentDomainResult> domains;
  final List<AssessmentParentConcern> parentConcerns;
  final String disclaimer;
  final String ageGroup;
  final int? ageYears;
  final int? ageMonths;
  final int? totalMonths;

  /// Client time the result was received (the submit response does not include
  /// the saved history row's timestamp). History entries use the backend
  /// `created_at`; it is null only when the API omitted the timestamp.
  final DateTime? recordedAt;

  factory AssessmentResult.fromApiData(
    Map<String, dynamic> data, {
    DateTime? recordedAt,
  }) {
    final concernLevel = (data['concern_level'] ?? '').toString().trim();

    if (concernLevel.isEmpty) {
      throw const ApiException(
        0,
        'The server returned an assessment result without a concern level.',
      );
    }

    final age = data['age'] is Map
        ? Map<String, dynamic>.from(data['age'] as Map)
        : const <String, dynamic>{};

    final rawDomains = data['domains'];
    final domains = <AssessmentDomainResult>[];

    if (rawDomains is Map) {
      for (final entry in rawDomains.entries) {
        final value = entry.value is Map
            ? Map<String, dynamic>.from(entry.value as Map)
            : const <String, dynamic>{};

        domains.add(
          AssessmentDomainResult(
            domain: entry.key.toString(),
            concernPercentage: _toDouble(value['concern_percentage']),
            countedQuestions: _toInt(value['counted_questions']),
          ),
        );
      }
    }

    final rawConcerns = data['parent_concerns'];
    final concerns = <AssessmentParentConcern>[];

    if (rawConcerns is List) {
      for (final item in rawConcerns.whereType<Map>()) {
        final questionId = (item['question_id'] ?? '').toString();
        final answer = (item['answer'] ?? '').toString();

        if (questionId.isNotEmpty) {
          concerns.add(
            AssessmentParentConcern(questionId: questionId, answer: answer),
          );
        }
      }
    }

    return AssessmentResult(
      childId: (data['child_id'] ?? '').toString(),
      concernLevel: concernLevel,
      status: (data['status'] ?? '').toString(),
      concernPercentage: _toDouble(data['concern_percentage']),
      totalScore: _toInt(data['total_score']),
      maximumScore: _toInt(data['maximum_score']),
      countedAnswers: _toInt(data['counted_answers']),
      notSureAnswers: _toInt(data['not_sure_answers']),
      domains: domains,
      parentConcerns: concerns,
      disclaimer: (data['disclaimer'] ?? '').toString(),
      ageGroup: (age['age_group'] ?? '').toString(),
      ageYears: _toInt(age['age_years']),
      ageMonths: _toInt(age['age_months']),
      totalMonths: _toInt(age['total_months']),
      recordedAt: recordedAt,
    );
  }

  static double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _toInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

/// One saved row from `GET /api/v1/assessment/history/{child_id}`.
class AssessmentHistoryEntry {
  const AssessmentHistoryEntry({
    required this.id,
    required this.childId,
    required this.result,
    this.createdAt,
    this.answers = const {},
  });

  final String id;
  final String childId;
  final DateTime? createdAt;
  final AssessmentResult result;
  final Map<String, String> answers;
}

/// Questionnaire operations for Module 1.
///
/// The backend chooses the age band from the child's stored date of birth, so
/// this client only sends the child ID and never an age group or question list.
class AssessmentService {
  AssessmentService({required ApiClient api}) : _api = api;

  final ApiClient _api;

  Future<AssessmentQuestionnaire> fetchQuestionnaire(String childId) async {
    final response = await _api.get(
      '${AppConfig.apiPrefix}/assessment/questionnaire/$childId',
    );

    final data = response['data'];

    if (data is! Map) {
      throw const ApiException(
        0,
        'The server returned an unexpected questionnaire.',
      );
    }

    final map = Map<String, dynamic>.from(data);
    final age = map['age'] is Map
        ? Map<String, dynamic>.from(map['age'] as Map)
        : const <String, dynamic>{};

    final rawQuestions = map['questions'];
    final rawOptions = map['answer_options'];

    if (rawQuestions is! List || rawQuestions.isEmpty) {
      throw const ApiException(
        0,
        'No questionnaire questions were returned for this child.',
      );
    }

    if (rawOptions is! List || rawOptions.isEmpty) {
      throw const ApiException(
        0,
        'No answer options were returned for this questionnaire.',
      );
    }

    final questions = rawQuestions
        .whereType<Map>()
        .map(
          (item) => AssessmentQuestion.fromApiData(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();

    final options = rawOptions
        .whereType<Map>()
        .map(
          (item) => AssessmentAnswerOption.fromApiData(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();

    if (questions.isEmpty || options.isEmpty) {
      throw const ApiException(
        0,
        'The questionnaire response was empty or invalid.',
      );
    }

    options.sort(_compareOptions);

    final totalMonths = age['total_months'] is num
        ? (age['total_months'] as num).toInt()
        : 0;

    return AssessmentQuestionnaire(
      childId: (map['child_id'] ?? childId).toString(),
      totalMonths: totalMonths,
      ageGroup: (age['age_group'] ?? '').toString(),
      questions: questions,
      options: options,
    );
  }

  /// Submits the full answer map and returns the backend-scored result.
  ///
  /// The backend requires an answer for every question in the child's age
  /// band and performs all scoring; this client never computes a score.
  Future<AssessmentResult> submitAssessment({
    required String childId,
    required Map<String, String> answers,
  }) async {
    final response = await _api.post(
      '${AppConfig.apiPrefix}/assessment/submit',
      body: {'child_id': childId, 'answers': answers},
    );

    final data = response['data'];

    if (data is! Map) {
      throw const ApiException(
        0,
        'The server returned an unexpected assessment result.',
      );
    }

    return AssessmentResult.fromApiData(
      Map<String, dynamic>.from(data),
      recordedAt: DateTime.now(),
    );
  }

  /// Loads the selected child's saved assessments.
  ///
  /// The backend returns `assessment_history` rows (`select("*")`) newest
  /// first and already filtered by child ID. The list is sorted again here so
  /// display order does not depend on the response order.
  Future<List<AssessmentHistoryEntry>> fetchHistory(String childId) async {
    final response = await _api.get(
      '${AppConfig.apiPrefix}/assessment/history/$childId',
    );

    final data = response['data'];

    if (data is! List) {
      throw const ApiException(
        0,
        'The server returned an unexpected assessment history.',
      );
    }

    final entries = <AssessmentHistoryEntry>[];

    for (final item in data.whereType<Map>()) {
      final row = Map<String, dynamic>.from(item);
      final createdAt = _parseTimestamp(row['created_at']);

      final resultData = Map<String, dynamic>.from(row)
        ..['age'] = {
          'age_years': row['age_years'],
          'age_months': row['age_months'],
          'total_months': row['total_months'],
          'age_group': row['age_group'],
        };

      final answers = <String, String>{};
      final rawAnswers = row['answers'];
      if (rawAnswers is Map) {
        for (final entry in rawAnswers.entries) {
          answers[entry.key.toString()] = entry.value.toString();
        }
      }

      entries.add(
        AssessmentHistoryEntry(
          id: (row['id'] ?? '').toString(),
          childId: (row['child_id'] ?? childId).toString(),
          createdAt: createdAt,
          result: AssessmentResult.fromApiData(
            resultData,
            recordedAt: createdAt,
          ),
          answers: answers,
        ),
      );
    }

    entries.sort((a, b) {
      final aTime = a.createdAt;
      final bTime = b.createdAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return entries;
  }

  static DateTime? _parseTimestamp(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim())?.toLocal();
  }

  int _compareOptions(AssessmentAnswerOption a, AssessmentAnswerOption b) {
    if (a.sortOrder != null && b.sortOrder != null) {
      return a.sortOrder!.compareTo(b.sortOrder!);
    }

    final order = AssessmentQuestionnaire.canonicalOptionOrder;
    final indexA = order.indexOf(a.value);
    final indexB = order.indexOf(b.value);

    if (indexA >= 0 && indexB >= 0) return indexA.compareTo(indexB);
    if (indexA >= 0) return -1;
    if (indexB >= 0) return 1;

    return a.value.compareTo(b.value);
  }
}
