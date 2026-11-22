import 'package:flutter/material.dart';

import '../services/assessment_service.dart';

/// Displays the backend-scored assessment result.
///
/// Every value shown here comes from `POST /api/v1/assessment/submit`. Missing
/// optional fields are omitted rather than filled with invented content, and
/// no score or concern level is computed on the client.
class AssessmentResultScreen extends StatelessWidget {
  const AssessmentResultScreen({
    super.key,
    required this.childName,
    required this.result,
    this.questionTexts = const {},
    this.backLabel = 'Back to dashboard',
  });

  final String childName;
  final AssessmentResult result;

  /// Label for the bottom action; history details use `Back`.
  final String backLabel;

  /// Question wording keyed by question ID, used to label parent concerns.
  final Map<String, String> questionTexts;

  static const Color primary = Color(0xFF347F83);
  static const Color dark = Color(0xFF235B68);
  static const Color background = Color(0xFFF3F8F8);

  String get _levelLabel {
    switch (result.concernLevel.toLowerCase()) {
      case 'low':
        return 'Low concern';
      case 'moderate':
        return 'Moderate concern';
      case 'high':
        return 'High concern';
      default:
        return _titleCase(result.concernLevel);
    }
  }

  Color get _levelColor {
    switch (result.concernLevel.toLowerCase()) {
      case 'low':
        return const Color(0xFF2F7D5D);
      case 'moderate':
        return const Color(0xFFB7791F);
      case 'high':
        return const Color(0xFFB44747);
      default:
        return primary;
    }
  }

  static String _titleCase(String value) {
    final words = value.replaceAll('_', ' ').trim();
    if (words.isEmpty) return value;
    return words[0].toUpperCase() + words.substring(1);
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1);
  }

  String get _ageLine {
    final parts = <String>[];

    if (result.ageGroup.isNotEmpty) parts.add(result.ageGroup);

    if (result.totalMonths != null) {
      parts.add('${result.totalMonths} months');
    } else if (result.ageYears != null) {
      final years = result.ageYears!;
      final months = result.ageMonths ?? 0;
      parts.add(months == 0 ? '$years years' : '$years years, $months months');
    }

    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: dark,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Assessment Result',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  const SizedBox(height: 14),
                  _concernCard(),
                  if (result.domains.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _domainsCard(),
                  ],
                  if (result.parentConcerns.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _parentConcernsCard(),
                  ],
                  const SizedBox(height: 14),
                  _disclaimerCard(),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      key: const Key('result-back'),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.dashboard_rounded, size: 19),
                      label: Text(backLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final ageLine = _ageLine;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE5F3F1), Color(0xFFF4FAF9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6EAE7)),
      ),
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.assignment_turned_in_rounded,
              color: primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            childName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: dark,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (ageLine.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              ageLine,
              style: const TextStyle(color: primary, fontSize: 13),
            ),
          ],
          if (result.recordedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Completed ${_formatDate(result.recordedAt!)}',
              style: const TextStyle(color: Color(0xFF718588), fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _concernCard() {
    final color = _levelColor;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3ECEC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Developmental concern level',
            style: TextStyle(
              color: Color(0xFF526B6D),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Text(
              _levelLabel,
              key: const Key('result-concern-level'),
              style: TextStyle(
                color: color,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (result.concernPercentage != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Concern percentage',
                    style: const TextStyle(
                      color: Color(0xFF526B6D),
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  '${_formatNumber(result.concernPercentage!)}%',
                  key: const Key('result-percentage'),
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: (result.concernPercentage! / 100).clamp(0.0, 1.0),
                minHeight: 8,
                color: color,
                backgroundColor: const Color(0xFFE8EEEE),
              ),
            ),
          ],
          if (result.totalScore != null && result.maximumScore != null) ...[
            const SizedBox(height: 14),
            _infoRow(
              'Score',
              '${result.totalScore} / ${result.maximumScore}',
              key: const Key('result-score'),
            ),
          ],
          if (result.countedAnswers != null || result.notSureAnswers != null) ...[
            const SizedBox(height: 8),
            _infoRow(
              'Answers counted / not sure',
              '${result.countedAnswers ?? '–'} / ${result.notSureAnswers ?? '–'}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Key? key}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF526B6D), fontSize: 12),
          ),
        ),
        Text(
          value,
          key: key,
          style: const TextStyle(
            color: dark,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _domainsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3ECEC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Domain results',
            style: TextStyle(
              color: dark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Percentages are calculated by the assessment service.',
            style: TextStyle(color: Color(0xFF718588), fontSize: 11),
          ),
          const SizedBox(height: 12),
          for (final domain in result.domains)
            Padding(
              key: Key('result-domain-${domain.domain}'),
              padding: const EdgeInsets.only(bottom: 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _titleCase(domain.domain),
                          style: const TextStyle(
                            color: dark,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (domain.concernPercentage != null)
                        Text(
                          '${_formatNumber(domain.concernPercentage!)}%',
                          style: const TextStyle(
                            color: primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: domain.concernPercentage == null
                          ? 0
                          : (domain.concernPercentage! / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      color: primary,
                      backgroundColor: const Color(0xFFE8EEEE),
                    ),
                  ),
                  if (domain.countedQuestions != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${domain.countedQuestions} questions counted',
                      style: const TextStyle(
                        color: Color(0xFF82999A),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _parentConcernsCard() {
    return Container(
      key: const Key('result-parent-concerns'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3ECEC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your reported concerns',
            style: TextStyle(
              color: dark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          for (final concern in result.parentConcerns)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    questionTexts[concern.questionId] ??
                        'Question ${concern.questionId}',
                    style: const TextStyle(
                      color: dark,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Answer: ${_titleCase(concern.answer)}',
                    style: const TextStyle(
                      color: primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _disclaimerCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF3F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result.disclaimer.isNotEmpty) ...[
                  Text(
                    result.disclaimer,
                    key: const Key('result-disclaimer'),
                    style: const TextStyle(
                      color: Color(0xFF45666B),
                      fontSize: 11,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const Text(
                  'This result supports developmental monitoring and early '
                  'identification of concerns. It is not a diagnosis of autism '
                  'and does not replace an evaluation by a qualified '
                  'professional.',
                  style: TextStyle(
                    color: Color(0xFF45666B),
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} $hour:$minute';
  }
}
