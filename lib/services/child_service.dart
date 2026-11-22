import '../config/app_config.dart';
import 'api_client.dart';

/// A child record returned by `GET/POST /api/v1/children/`.
///
/// The backend stores these rows in Supabase and returns them unchanged inside
/// the standard `{success, message, data}` envelope, so only the columns that
/// the child screen needs are read here.
class ApiChild {
  const ApiChild({
    required this.id,
    required this.childName,
    required this.dateOfBirth,
    this.gender = '',
    this.createdAt,
  });

  final String id;
  final String childName;
  final DateTime dateOfBirth;
  final String gender;
  final DateTime? createdAt;

  factory ApiChild.fromApiData(Map<String, dynamic> data) {
    final id = (data['id'] ?? '').toString();
    final name = (data['child_name'] ?? '').toString();
    final dateOfBirth = parseApiDate(data['date_of_birth']);

    if (id.isEmpty || name.isEmpty || dateOfBirth == null) {
      throw const ApiException(
        0,
        'The server returned an incomplete child profile.',
      );
    }

    return ApiChild(
      id: id,
      childName: name,
      dateOfBirth: dateOfBirth,
      gender: (data['gender'] ?? '').toString(),
      createdAt: parseApiDate(data['created_at']),
    );
  }
}

/// Reads a backend date value and keeps only the calendar date.
///
/// The API accepts/returns a plain `YYYY-MM-DD` date, but Supabase may include
/// a time component on `created_at`, so both forms are handled.
DateTime? parseApiDate(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;

  final parsed = DateTime.tryParse(value.trim());
  if (parsed == null) return null;

  return DateTime(parsed.year, parsed.month, parsed.day);
}

/// Formats a date for the `date_of_birth` field the backend expects
/// (`datetime.date`, JSON encoded as `YYYY-MM-DD`).
String formatApiDate(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

/// Whole months between [dateOfBirth] and [now], counting a month only after
/// the same day-of-month has been reached.
int ageInMonths(DateTime dateOfBirth, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  var months = (reference.year - dateOfBirth.year) * 12 +
      reference.month -
      dateOfBirth.month;

  if (reference.day < dateOfBirth.day) months--;

  return months < 0 ? 0 : months;
}

/// Human-readable age such as `18 months old` or `2 years, 3 months old`.
String formatAgeLabel(DateTime dateOfBirth, {DateTime? now}) {
  final months = ageInMonths(dateOfBirth, now: now);
  final years = months ~/ 12;
  final remainingMonths = months % 12;

  if (years == 0) return '$months months old';
  if (remainingMonths == 0) return '$years years old';
  return '$years years, $remainingMonths months old';
}

/// Returns the date [months] months before [reference], clamping the day when
/// the target month is shorter (e.g. 31 Mar -> 28/29 Feb).
DateTime subtractMonths(DateTime reference, int months) {
  final target = DateTime(reference.year, reference.month - months, 1);
  final lastDay = DateTime(target.year, target.month + 1, 0).day;
  final day = reference.day > lastDay ? lastDay : reference.day;

  return DateTime(target.year, target.month, day);
}

/// The gender values allowed by the `children_gender_check` database
/// constraint. The API stores these codes, not the labels shown in the UI.
const List<String> childGenderValues = <String>[
  'male',
  'female',
  'prefer_not_to_say',
];

/// Converts a stored gender code into the label shown in the UI.
/// Unknown values (e.g. legacy locally saved labels) are returned unchanged.
String genderDisplayLabel(String value) {
  switch (value.trim().toLowerCase()) {
    case 'male':
      return 'Male';
    case 'female':
      return 'Female';
    case 'prefer_not_to_say':
      return 'Prefer not to say';
    default:
      return value;
  }
}

/// Child profile operations through the existing FastAPI children module.
class ChildService {
  ChildService({required ApiClient api}) : _api = api;

  final ApiClient _api;

  Future<List<ApiChild>> fetchChildren() async {
    final response = await _api.get('${AppConfig.apiPrefix}/children/');
    final data = response['data'];

    if (data is! List) {
      throw const ApiException(
        0,
        'The server returned an unexpected children list.',
      );
    }

    return data
        .whereType<Map>()
        .map((item) => ApiChild.fromApiData(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<ApiChild> createChild({
    required String childName,
    required DateTime dateOfBirth,
    String? gender,
  }) async {
    final body = <String, dynamic>{
      'child_name': childName,
      'date_of_birth': formatApiDate(dateOfBirth),
    };

    if (gender != null && gender.isNotEmpty) {
      body['gender'] = gender;
    }

    final response = await _api.post(
      '${AppConfig.apiPrefix}/children/',
      body: body,
    );

    final data = response['data'];

    if (data is! Map) {
      throw const ApiException(
        0,
        'The server returned an unexpected child profile.',
      );
    }

    return ApiChild.fromApiData(Map<String, dynamic>.from(data));
  }
}
