import 'package:flutter/material.dart';

import '../app_state.dart';
import '../services/api_client.dart';
import '../services/child_service.dart';
import '../services/session_service.dart';
import 'dashboard_screen.dart';
import 'welcome_screen.dart';

/// Child profile selection and creation backed by the FastAPI children API.
///
/// Parent ownership is enforced by the backend from the bearer token, so this
/// screen never sends a parent ID. All children come from
/// `GET /api/v1/children/`; nothing is invented locally.
class ChildProfileScreen extends StatefulWidget {
  const ChildProfileScreen({
    super.key,
    required this.session,
    this.parentName = '',
    this.parentEmail = '',
    this.onLogout,
  });

  final SessionService session;
  final String parentName;
  final String parentEmail;
  final Future<void> Function()? onLogout;

  static const int minAgeMonths = 0;
  static const int maxAgeMonths = 60;

  static const Color primary = Color(0xFF347F83);
  static const Color dark = Color(0xFF235B68);
  static const Color background = Color(0xFFF4F8F8);
  static const Color muted = Color(0xFF718588);

  static String? validateChildName(String? value) {
    final name = (value ?? '').trim();

    if (name.isEmpty) return 'Please enter the child’s name';
    if (name.length > 100) return 'Name must be 100 characters or fewer';

    return null;
  }

  static String? validateDateOfBirth(DateTime? value, {DateTime? now}) {
    if (value == null) return 'Please select the child’s date of birth';

    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final dob = DateUtils.dateOnly(value);

    if (dob.isAfter(today)) {
      return 'A future date of birth is not allowed';
    }

    final months = ageInMonths(dob, now: today);

    if (months < minAgeMonths || months > maxAgeMonths) {
      return 'This app supports children aged 0 to 60 months only';
    }

    return null;
  }

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  late final ChildService _children;

  List<ApiChild> _items = const [];
  bool _loading = true;
  bool _creating = false;
  String? _loadError;
  String? _formError;
  String? _successMessage;
  DateTime? _dateOfBirth;
  String? _gender;

  bool get _isUrdu => NurtureLanguage.isUrdu;

  String _t(String english, String urdu) => _isUrdu ? urdu : english;

  DateTime get _today => DateUtils.dateOnly(DateTime.now());

  DateTime get _earliestDate =>
      subtractMonths(_today, ChildProfileScreen.maxAgeMonths);

  @override
  void initState() {
    super.initState();
    _children = ChildService(api: widget.session.api);
    _loadChildren();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _messageFor(ApiException error) {
    if (error.statusCode == 401) {
      return 'Your session has expired. Please log in again.';
    }

    if (error.statusCode >= 500) {
      return 'The server could not complete the request. Please try again.';
    }

    return error.message;
  }

  Future<void> _loadChildren() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final items = await _children.fetchChildren();

      if (!mounted) return;

      setState(() {
        _items = items;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = _messageFor(error);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Something went wrong while loading your children.';
        _loading = false;
      });
    }
  }

  Future<void> _chooseDateOfBirth() async {
    final initial = _dateOfBirth ?? subtractMonths(_today, 24);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(_earliestDate) ? _earliestDate : initial,
      firstDate: _earliestDate,
      lastDate: _today,
      helpText: _t(
        'Select Child Date of Birth',
        'بچے کی تاریخ پیدائش منتخب کریں',
      ),
      cancelText: _t('Cancel', 'منسوخ'),
      confirmText: _t('Select', 'منتخب کریں'),
      builder: (context, child) {
        return Directionality(
          textDirection: _isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: ChildProfileScreen.primary,
                onPrimary: Colors.white,
                surface: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked == null || !mounted) return;

    setState(() {
      _dateOfBirth = DateUtils.dateOnly(picked);
      _formError = null;
    });
  }

  Future<void> _createChild() async {
    if (_creating) return;

    FocusScope.of(context).unfocus();

    final nameError = ChildProfileScreen.validateChildName(_nameController.text);
    final dateError = ChildProfileScreen.validateDateOfBirth(_dateOfBirth);

    if (!(_formKey.currentState?.validate() ?? false) ||
        nameError != null ||
        dateError != null) {
      setState(() => _formError = dateError ?? nameError);
      return;
    }

    setState(() {
      _creating = true;
      _formError = null;
      _successMessage = null;
    });

    try {
      final created = await _children.createChild(
        childName: _nameController.text.trim(),
        dateOfBirth: _dateOfBirth!,
        gender: _gender,
      );

      // Refresh from the server so the list reflects the backend row exactly.
      final refreshed = await _children.fetchChildren();

      if (!mounted) return;

      setState(() {
        _items = refreshed;
        _creating = false;
        _successMessage = _t(
          '${created.childName} was added to your account.',
          '${created.childName} آپ کے اکاؤنٹ میں شامل ہو گیا۔',
        );
        _nameController.clear();
        _dateOfBirth = null;
        _gender = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _formError = _messageFor(error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _formError = 'Something went wrong while creating the profile.';
      });
    }
  }

  void _openChild(ApiChild child) {
    final parentName = widget.parentName.trim().isEmpty
        ? 'Parent'
        : widget.parentName.trim();

    final profile = ChildProfileRecord(
      id: child.id,
      childName: child.childName,
      dateOfBirth: child.dateOfBirth,
      gender: child.gender.isEmpty
          ? 'Not specified'
          : genderDisplayLabel(child.gender),
      parentName: parentName,
      parentEmail: widget.parentEmail,
      relationship: '',
      phone: '',
      createdAt: child.createdAt ?? DateTime.now(),
    );

    AppState.rememberBackendChild(profile);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          childName: profile.childName,
          dateOfBirth: profile.dateOfBirth,
          gender: profile.gender,
          parentName: profile.parentName,
          parentEmail: profile.parentEmail,
          relationship: profile.relationship,
          phone: profile.phone,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: ChildProfileScreen.background,
        appBar: AppBar(
          title: Text(
            _t('Child Profile', 'بچے کی پروفائل'),
            style: const TextStyle(
              color: ChildProfileScreen.dark,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            if (widget.onLogout != null)
              IconButton(
                key: const Key('auth-logout'),
                tooltip: _t('Log out', 'لاگ آؤٹ'),
                onPressed: () => widget.onLogout?.call(),
                icon: const Icon(
                  Icons.logout_rounded,
                  color: ChildProfileScreen.dark,
                ),
              ),
          ],
        ),
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: ChildProfileScreen.primary),
            const SizedBox(height: 14),
            Text(
              _t('Loading your children...', 'آپ کے بچوں کی معلومات لوڈ ہو رہی ہیں...'),
              style: const TextStyle(
                color: ChildProfileScreen.muted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 46,
                  color: ChildProfileScreen.muted,
                ),
                const SizedBox(height: 12),
                Text(
                  _loadError!,
                  key: const Key('children-error'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFB44747),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('children-retry'),
                  onPressed: _loadChildren,
                  child: Text(_t('Try again', 'دوبارہ کوشش کریں')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              if (_items.isEmpty) _buildEmptyState() else _buildChildList(),
              const SizedBox(height: 20),
              _buildCreateForm(),
              const SizedBox(height: 15),
              Text(
                _t(
                  'NurtureSteps currently supports children aged 0–60 months.',
                  'NurtureSteps فی الحال 0 سے 60 ماہ کے بچوں کی معاونت کرتا ہے۔',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: Color(0xFF829497),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ChildProfileScreen.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.child_care_rounded,
            size: 45,
            color: ChildProfileScreen.primary,
          ),
          const SizedBox(height: 12),
          Text(
            _t('Your Children', 'آپ کے بچے'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: ChildProfileScreen.dark,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            widget.parentEmail.isEmpty
                ? _t(
                    'Select a child or add a new profile to continue.',
                    'جاری رکھنے کے لیے بچہ منتخب کریں یا نئی پروفائل بنائیں۔',
                  )
                : widget.parentEmail,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: ChildProfileScreen.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      key: const Key('children-empty'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3ECEC)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.person_add_alt_1_rounded,
            color: ChildProfileScreen.primary,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            _t(
              'No child profiles yet. Create your first profile below.',
              'ابھی کوئی پروفائل نہیں۔ نیچے پہلی پروفائل بنائیں۔',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ChildProfileScreen.muted,
              height: 1.5,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _t('Select a child', 'بچہ منتخب کریں'),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: ChildProfileScreen.dark,
          ),
        ),
        const SizedBox(height: 10),
        for (final child in _items) ...[
          _childCard(child),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _childCard(ApiChild child) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: Key('child-card-${child.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openChild(child),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE3ECEC)),
          ),
          child: Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4F2),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.child_care_rounded,
                  color: ChildProfileScreen.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.childName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: ChildProfileScreen.dark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${formatAgeLabel(child.dateOfBirth)}'
                      '${child.gender.isEmpty ? '' : '  •  ${genderDisplayLabel(child.gender)}'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: ChildProfileScreen.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF789294),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3ECEC)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _t('Create Child Profile', 'بچے کی پروفائل بنائیں'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: ChildProfileScreen.dark,
              ),
            ),
            const SizedBox(height: 16),
            if (_successMessage != null) ...[
              _messageBox(_successMessage!, isSuccess: true),
              const SizedBox(height: 14),
            ],
            if (_formError != null) ...[
              _messageBox(_formError!, isSuccess: false),
              const SizedBox(height: 14),
            ],
            _label(_t('Child Name', 'بچے کا نام')),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('child-name'),
              controller: _nameController,
              enabled: !_creating,
              validator: ChildProfileScreen.validateChildName,
              textCapitalization: TextCapitalization.words,
              maxLength: 100,
              decoration: _decoration(
                _t('Enter child name', 'بچے کا نام درج کریں'),
                Icons.person_outline_rounded,
              ),
            ),
            const SizedBox(height: 12),
            _label(_t('Date of Birth', 'تاریخ پیدائش')),
            const SizedBox(height: 8),
            InkWell(
              key: const Key('child-dob'),
              onTap: _creating ? null : _chooseDateOfBirth,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 17,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDCE8E8)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: ChildProfileScreen.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _dateOfBirth == null
                            ? _t('Select date of birth', 'تاریخ منتخب کریں')
                            : '${_dateOfBirth!.day.toString().padLeft(2, '0')}/'
                                  '${_dateOfBirth!.month.toString().padLeft(2, '0')}/'
                                  '${_dateOfBirth!.year}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _dateOfBirth == null
                              ? const Color(0xFF849698)
                              : const Color(0xFF365F65),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF789294),
                    ),
                  ],
                ),
              ),
            ),
            if (_dateOfBirth != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5F3),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.accessibility_new_rounded,
                      color: ChildProfileScreen.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_t('Current age:', 'موجودہ عمر:')} '
                        '${formatAgeLabel(_dateOfBirth!)}',
                        key: const Key('child-age'),
                        style: const TextStyle(
                          color: ChildProfileScreen.dark,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 17),
            _label(_t('Gender (optional)', 'جنس (اختیاری)')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: const Key('child-gender'),
              initialValue: _gender,
              decoration: _decoration(
                _t('Select gender', 'جنس منتخب کریں'),
                Icons.wc_rounded,
              ),
              items: [
                DropdownMenuItem(
                  value: 'male',
                  child: Text(_t('Male', 'لڑکا')),
                ),
                DropdownMenuItem(
                  value: 'female',
                  child: Text(_t('Female', 'لڑکی')),
                ),
                DropdownMenuItem(
                  value: 'prefer_not_to_say',
                  child: Text(_t('Prefer not to say', 'بتانا نہیں چاہتے')),
                ),
              ],
              onChanged: _creating
                  ? null
                  : (value) => setState(() => _gender = value),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 54,
              child: FilledButton(
                key: const Key('child-submit'),
                onPressed: _creating ? null : _createChild,
                child: _creating
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.2,
                        ),
                      )
                    : Text(_t('Create Child Profile', 'پروفائل بنائیں')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageBox(String message, {required bool isSuccess}) {
    final color = isSuccess
        ? const Color(0xFF2F7D5D)
        : const Color(0xFFB44747);

    return Container(
      key: Key(isSuccess ? 'child-success' : 'child-form-error'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess
            ? const Color(0xFFEAF7F0)
            : const Color(0xFFFDEEEE),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isSuccess
              ? const Color(0xFFC9E9D8)
              : const Color(0xFFF2CFCF),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSuccess
                ? Icons.check_circle_outline_rounded
                : Icons.error_outline_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF365F65),
      ),
    );
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF789294)),
    );
  }
}
