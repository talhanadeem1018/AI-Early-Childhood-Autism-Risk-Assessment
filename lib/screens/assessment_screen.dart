import 'package:flutter/material.dart';

import '../app_state.dart';
import '../services/api_client.dart';
import '../services/assessment_service.dart';
import '../services/session_service.dart';
import '../widgets/nurse_mascot.dart';
import 'assessment_result_screen.dart';

/// Module 1 questionnaire backed by
/// `GET /api/v1/assessment/questionnaire/{child_id}`.
///
/// The backend chooses the age band from the child's stored date of birth and
/// returns the question wording, IDs, domains and answer options. This screen
/// only collects answers against the returned question IDs; scoring and result
/// screens are Step 6.
class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({
    super.key,
    required this.childName,
    required this.dateOfBirth,
    this.childId,
    this.session,
  });

  final String childName;
  final DateTime dateOfBirth;

  /// Backend child ID. Falls back to the currently selected backend child.
  final String? childId;

  final SessionService? session;

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  static const Color primary = Color(0xFF347F83);
  static const Color dark = Color(0xFF235B68);
  static const Color background = Color(0xFFF3F8F8);

  late final SessionService _session;
  late final AssessmentService _service;

  String? _childId;
  AssessmentQuestionnaire? _questionnaire;
  List<AssessmentQuestion> _questions = const [];
  List<AssessmentAnswerOption> _options = const [];

  final Map<String, String> _answers = {};

  int _currentQuestionIndex = 0;
  bool _loading = true;
  bool _missingChild = false;
  bool _submitting = false;
  String? _error;
  String? _submitError;

  AssessmentQuestion? get _currentQuestion {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) {
      return null;
    }
    return _questions[_currentQuestionIndex];
  }

  bool get _isLastQuestion =>
      _questions.isNotEmpty && _currentQuestionIndex == _questions.length - 1;

  bool get _isFirstQuestion => _currentQuestionIndex == 0;

  int get _totalQuestions => _questions.length;

  int get _answeredCount =>
      _questions.where((question) => _answers[question.id] != null).length;

  double get _currentProgress =>
      _totalQuestions == 0 ? 0 : (_currentQuestionIndex + 1) / _totalQuestions;

  String? get _selectedAnswer {
    final question = _currentQuestion;
    return question == null ? null : _answers[question.id];
  }

  @override
  void initState() {
    super.initState();

    _session = widget.session ?? SessionService.instance;
    _service = AssessmentService(api: _session.api);
    _childId = widget.childId ?? AppState.selectedChildProfile?.id;

    if (_childId == null || _childId!.trim().isEmpty) {
      _loading = false;
      _missingChild = true;
      return;
    }

    _loadQuestionnaire();
  }

  String _messageFor(ApiException error) {
    if (error.statusCode == 401) {
      return 'Your session has expired. Please log in again.';
    }

    if (error.statusCode >= 500) {
      return 'The server could not load the questionnaire. Please try again.';
    }

    return error.message;
  }

  Future<void> _loadQuestionnaire() async {
    final childId = _childId;

    if (childId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final questionnaire = await _service.fetchQuestionnaire(childId);

      if (!mounted) return;

      final draft = AppState.assessmentDraftFor(childId);
      final restored = <String, String>{};

      for (final question in questionnaire.questions) {
        final value = draft[question.id];
        if (value != null &&
            questionnaire.options.any((option) => option.value == value)) {
          restored[question.id] = value;
        }
      }

      setState(() {
        _questionnaire = questionnaire;
        _questions = questionnaire.questions;
        _options = questionnaire.options;
        _answers
          ..clear()
          ..addAll(restored);
        _currentQuestionIndex = 0;
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
        _error = 'Something went wrong while loading the questionnaire.';
        _loading = false;
      });
    }
  }

  void _selectAnswer(String value) {
    final question = _currentQuestion;
    if (question == null) return;

    setState(() {
      _answers[question.id] = value;
    });

    final childId = _childId;
    if (childId != null) {
      AppState.saveAssessmentDraft(childId, _answers);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _nextQuestion() {
    if (_selectedAnswer == null) {
      _showMessage('Please select an answer before continuing.');
      return;
    }

    if (_isLastQuestion) {
      _finishQuestionnaire();
      return;
    }

    setState(() => _currentQuestionIndex++);
  }

  void _previousQuestion() {
    if (_isFirstQuestion) return;
    setState(() => _currentQuestionIndex--);
  }

  String _messageForSubmission(ApiException error) {
    if (error.statusCode == 401) {
      return 'Your session has expired. Please log in again and try again.';
    }

    if (error.statusCode == 422) {
      return error.message;
    }

    if (error.statusCode >= 500) {
      return 'The server could not score the assessment. Please try again.';
    }

    return error.message;
  }

  Future<void> _finishQuestionnaire() async {
    if (_submitting) return;

    if (_answeredCount != _totalQuestions) {
      _showMessage(
        'Please answer all $_totalQuestions questions before submitting.',
      );
      return;
    }

    final childId = _childId;

    if (childId == null || childId.trim().isEmpty) {
      _showMessage('Select a child profile before submitting.');
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final result = await _service.submitAssessment(
        childId: childId,
        answers: Map<String, String>.from(_answers),
      );

      if (!mounted) return;

      AppState.clearAssessmentDraft(childId);
      AppState.notifyAssessmentHistoryChanged();

      final questionTexts = <String, String>{
        for (final question in _questions) question.id: question.text,
      };

      setState(() => _submitting = false);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AssessmentResultScreen(
            childName: widget.childName,
            result: result,
            questionTexts: questionTexts,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = _messageForSubmission(error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError =
            'Something went wrong while submitting the assessment. '
            'Your answers are still here; please try again.';
      });
    }
  }

  Future<void> _confirmExit() async {
    if (_submitting) return;

    if (_answers.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Leave assessment?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Your answers stay saved as a draft for this app session, but they '
          'have not been submitted for scoring.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Continue assessment'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFAA5B50),
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      Navigator.pop(context);
    }
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
          'Development Assessment',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          tooltip: 'Exit assessment',
          icon: const Icon(Icons.close_rounded),
          onPressed: _submitting ? null : _confirmExit,
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_missingChild) return _missingChildView();
    if (_loading) return _loadingView();
    if (_error != null) return _errorView();

    final question = _currentQuestion;
    if (question == null) return _emptyView();

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 650;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(18, compact ? 3 : 10, 18, 18),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _progressHeader(),
                        SizedBox(height: compact ? 7 : 14),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: _questionContent(
                            question,
                            compact,
                            key: ValueKey(question.id),
                          ),
                        ),
                        if (_submitError != null) ...[
                          const SizedBox(height: 12),
                          _submitErrorBanner(),
                        ],
                        const SizedBox(height: 15),
                        _supportMessage(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        _navigationBar(),
      ],
    );
  }

  Widget _loadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const NurseMascot(size: 120),
          const SizedBox(height: 16),
          const CircularProgressIndicator(color: primary),
          const SizedBox(height: 14),
          const Text(
            'Loading questionnaire...',
            style: TextStyle(color: Color(0xFF526B6D), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 46,
                color: Color(0xFF718588),
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                key: const Key('assessment-error'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB44747), height: 1.5),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('assessment-retry'),
                onPressed: _loadQuestionnaire,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NurseMascot(size: 120),
            const SizedBox(height: 15),
            const Text(
              'No questions available for this child',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: dark,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The questionnaire for this age group could not be loaded. '
              'Check the child’s date of birth and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('assessment-retry'),
              onPressed: _loadQuestionnaire,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _missingChildView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.child_care_rounded,
                size: 46,
                color: primary,
              ),
              const SizedBox(height: 12),
              const Text(
                'Select a child profile before starting the assessment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: dark,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressHeader() {
    final ageGroup = _questionnaire?.ageGroup ?? '';
    final totalMonths = _questionnaire?.totalMonths;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE5EEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.childName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: dark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F3F1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Question ${_currentQuestionIndex + 1} of $_totalQuestions',
                  key: const Key('assessment-progress-label'),
                  style: const TextStyle(
                    color: primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: _currentProgress,
              minHeight: 8,
              color: primary,
              backgroundColor: const Color(0xFFE8EEEE),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ageGroup.isEmpty
                    ? 'Age-based questionnaire'
                    : '$ageGroup${totalMonths == null ? '' : ' • $totalMonths months'}',
                style: const TextStyle(color: Colors.black54, fontSize: 10),
              ),
              Text(
                '$_answeredCount answered',
                style: const TextStyle(
                  color: primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _questionContent(
    AssessmentQuestion question,
    bool compact, {
    required Key key,
  }) {
    final selected = _answers[question.id];

    return Container(
      key: key,
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFEDF7F6)],
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFFE1ECEB)),
        boxShadow: [
          BoxShadow(
            color: dark.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          NurseMascot(size: compact ? 105 : 135),
          SizedBox(height: compact ? 4 : 10),
          if (question.domain.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFE4F2F0),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                _domainLabel(question.domain),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const SizedBox(height: 17),
          Text(
            'Question ${_currentQuestionIndex + 1}',
            style: const TextStyle(
              color: Color(0xFF82999A),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            question.text,
            key: const Key('assessment-question-text'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF243B40),
              fontSize: compact ? 18 : 21,
              height: 1.45,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Choose the answer that best describes your child.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < _options.length; i++) ...[
            if (i > 0) const SizedBox(height: 9),
            _answerOption(_options[i], selected: selected == _options[i].value),
          ],
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: selected == null
                ? const Text(
                    'Choose one answer to continue.',
                    key: ValueKey('unanswered'),
                    style: TextStyle(color: Colors.black45, fontSize: 11),
                  )
                : Row(
                    key: ValueKey(selected),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 15,
                        color: primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_optionLabel(selected)} selected',
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

  String _optionLabel(String value) {
    for (final option in _options) {
      if (option.value == value) return option.label;
    }
    return value;
  }

  String _domainLabel(String domain) {
    final words = domain.replaceAll('_', ' ').trim();
    if (words.isEmpty) return domain;
    return words[0].toUpperCase() + words.substring(1);
  }

  Color _optionColor(String value) {
    switch (value) {
      case 'usually':
        return const Color(0xFF287F67);
      case 'sometimes':
        return const Color(0xFF347F83);
      case 'rarely':
        return const Color(0xFFB66C4D);
      case 'not_sure':
        return const Color(0xFF81709B);
      default:
        return primary;
    }
  }

  IconData _optionIcon(String value) {
    switch (value) {
      case 'usually':
        return Icons.check_circle_rounded;
      case 'sometimes':
        return Icons.timelapse_rounded;
      case 'rarely':
        return Icons.schedule_rounded;
      case 'not_sure':
        return Icons.help_rounded;
      default:
        return Icons.radio_button_checked;
    }
  }

  Widget _answerOption(
    AssessmentAnswerOption option, {
    required bool selected,
  }) {
    final color = _optionColor(option.value);

    return Material(
      color: selected ? color.withValues(alpha: 0.10) : Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        key: Key('answer-${option.value}'),
        borderRadius: BorderRadius.circular(15),
        onTap: () => _selectAnswer(option.value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? color : const Color(0xFFE5ECEC),
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 37,
                width: 37,
                decoration: BoxDecoration(
                  color: selected ? color : color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  _optionIcon(option.value),
                  color: selected ? Colors.white : color,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.label,
                  style: TextStyle(
                    color: selected ? color : dark,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: selected
                    ? Icon(
                        Icons.check_circle_rounded,
                        key: const ValueKey('selected'),
                        color: color,
                        size: 23,
                      )
                    : const Icon(
                        Icons.circle_outlined,
                        key: ValueKey('unselected'),
                        color: Color(0xFFD2DEDE),
                        size: 23,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _submitErrorBanner() {
    return Container(
      key: const Key('assessment-submit-error'),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFDEEEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF2CFCF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFB44747),
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _submitError!,
              style: const TextStyle(
                color: Color(0xFFB44747),
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
          TextButton(
            key: const Key('assessment-submit-retry'),
            onPressed: _submitting ? null : _finishQuestionnaire,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Widget _supportMessage() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1F1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: primary, size: 19),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Answer according to what you have observed. These questions '
              'support developmental monitoring; they are not a diagnosis.',
              style: TextStyle(
                fontSize: 10,
                height: 1.55,
                color: Color(0xFF45666B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navigationBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 12, 17, 13),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE6EEEE))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            SizedBox(
              width: 104,
              height: 49,
              child: OutlinedButton.icon(
                key: const Key('assessment-previous'),
                onPressed: _isFirstQuestion || _submitting
                    ? null
                    : _previousQuestion,
                icon: const Icon(Icons.arrow_back_rounded, size: 17),
                label: const Text('Previous', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: dark,
                  side: const BorderSide(color: Color(0xFFD8E5E5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 49,
                child: FilledButton(
                  key: const Key('assessment-next'),
                  onPressed: _submitting ? null : _nextQuestion,
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: _submitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 9),
                            Text(
                              'Submitting...',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLastQuestion ? 'Finish' : 'Next',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Icon(
                              _isLastQuestion
                                  ? Icons.flag_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
