import 'package:flutter/material.dart';

import '../app_state.dart';
import '../services/api_client.dart';
import '../services/session_service.dart';
import 'local_child_profile_screen.dart';
import 'welcome_screen.dart';

enum AuthMode { login, signup }

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.session,
    this.initialMode = AuthMode.login,
  });

  final SessionService? session;
  final AuthMode initialMode;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const Color primary = Color(0xFF347F83);
  static const Color dark = Color(0xFF235B68);
  static const Color muted = Color(0xFF657D80);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final SessionService _session;
  late AuthMode _mode;

  bool _submitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  String? _successMessage;

  bool get _isUrdu => NurtureLanguage.isUrdu;

  bool get _isSignup => _mode == AuthMode.signup;

  String _t(String english, String urdu) => _isUrdu ? urdu : english;

  @override
  void initState() {
    super.initState();
    _session = widget.session ?? SessionService.instance;
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode(AuthMode mode) {
    if (_submitting || mode == _mode) return;

    setState(() {
      _mode = mode;
      _errorMessage = null;
      _successMessage = null;
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();

    if (email.isEmpty) {
      return _t('Enter your email address.', 'اپنا ای میل درج کریں۔');
    }

    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(email)) {
      return _t('Enter a valid email address.', 'درست ای میل درج کریں۔');
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return _t('Enter your password.', 'اپنا پاس ورڈ درج کریں۔');
    }

    if (password.length < 8) {
      return _t(
        'Password must be at least 8 characters.',
        'پاس ورڈ کم از کم 8 حروف کا ہونا چاہیے۔',
      );
    }

    if (password.length > 72) {
      return _t(
        'Password must be 72 characters or fewer.',
        'پاس ورڈ 72 حروف سے زیادہ نہیں ہو سکتا۔',
      );
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!_isSignup) return null;

    if ((value ?? '').isEmpty) {
      return _t('Re-enter your password.', 'اپنا پاس ورڈ دوبارہ درج کریں۔');
    }

    if (value != _passwordController.text) {
      return _t('Passwords do not match.', 'پاس ورڈ ایک جیسے نہیں ہیں۔');
    }

    return null;
  }

  String _messageFor(ApiException error) {
    if (_isSignup && error.statusCode == 400) {
      return 'Registration could not be completed. This email may already be in use, or the details may be invalid. If you already have an account, log in instead.';
    }

    if (!_isSignup && error.statusCode == 401) {
      return 'Incorrect email or password. If you just signed up, verify your email before logging in.';
    }

    if (error.statusCode == 422) {
      return error.message;
    }

    if (error.statusCode >= 500) {
      return 'The server could not complete the request. Please try again later.';
    }

    return error.message;
  }

  Future<void> _submit() async {
    if (_submitting) return;

    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isSignup) {
        final result = await _session.auth.register(
          email: email,
          password: password,
        );

        if (!mounted) return;

        setState(() {
          _successMessage = result.emailVerificationRequired
              ? 'Account created for ${result.email}. Check your email and verify your address before logging in.'
              : 'Account created for ${result.email}. You can now log in.';
          _mode = AuthMode.login;
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
      } else {
        await _session.login(email: email, password: password);

        if (!mounted) return;

        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = _messageFor(error));
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Something went wrong. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F8F8),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF4F8F8),
          title: Text(
            _isUrdu ? 'والدین کا اکاؤنٹ' : 'Parent / Guardian Account',
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.family_restroom_rounded,
                            size: 54,
                            color: primary,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _isSignup
                                ? _t(
                                    'Create your parent account',
                                    'اپنا والدین اکاؤنٹ بنائیں',
                                  )
                                : _t('Welcome back', 'خوش آمدید'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: dark,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isSignup
                                ? _t(
                                    'Sign up with your email to keep your child’s records connected to your account.',
                                    'اپنے بچے کے ریکارڈ کو اکاؤنٹ سے جوڑنے کے لیے ای میل سے سائن اپ کریں۔',
                                  )
                                : _t(
                                    'Log in to continue to your NurtureSteps account.',
                                    'اپنے NurtureSteps اکاؤنٹ میں جانے کے لیے لاگ ان کریں۔',
                                  ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: muted, height: 1.5),
                          ),
                          const SizedBox(height: 20),
                          _buildModeSelector(),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 14),
                            _buildMessage(
                              message: _errorMessage!,
                              isSuccess: false,
                            ),
                          ],
                          if (_successMessage != null) ...[
                            const SizedBox(height: 14),
                            _buildMessage(
                              message: _successMessage!,
                              isSuccess: true,
                            ),
                          ],
                          const SizedBox(height: 18),
                          TextFormField(
                            key: const Key('auth-email'),
                            controller: _emailController,
                            enabled: !_submitting,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: InputDecoration(
                              labelText: _t('Email address', 'ای میل'),
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            key: const Key('auth-password'),
                            controller: _passwordController,
                            enabled: !_submitting,
                            obscureText: _obscurePassword,
                            enableSuggestions: false,
                            autocorrect: false,
                            textInputAction: _isSignup
                                ? TextInputAction.next
                                : TextInputAction.done,
                            autofillHints: [
                              _isSignup
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            decoration: InputDecoration(
                              labelText: _t('Password', 'پاس ورڈ'),
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                key: const Key('auth-password-toggle'),
                                tooltip: _obscurePassword
                                    ? _t('Show password', 'پاس ورڈ دکھائیں')
                                    : _t('Hide password', 'پاس ورڈ چھپائیں'),
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: _validatePassword,
                            onFieldSubmitted: _isSignup
                                ? null
                                : (_) => _submit(),
                          ),
                          if (_isSignup) ...[
                            const SizedBox(height: 15),
                            TextFormField(
                              key: const Key('auth-confirm-password'),
                              controller: _confirmPasswordController,
                              enabled: !_submitting,
                              obscureText: _obscureConfirmPassword,
                              enableSuggestions: false,
                              autocorrect: false,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.newPassword],
                              decoration: InputDecoration(
                                labelText: _t(
                                  'Confirm password',
                                  'پاس ورڈ کی تصدیق',
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock_reset_outlined,
                                ),
                                suffixIcon: IconButton(
                                  key: const Key('auth-confirm-toggle'),
                                  tooltip: _obscureConfirmPassword
                                      ? _t('Show password', 'پاس ورڈ دکھائیں')
                                      : _t('Hide password', 'پاس ورڈ چھپائیں'),
                                  onPressed: () {
                                    setState(
                                      () => _obscureConfirmPassword =
                                          !_obscureConfirmPassword,
                                    );
                                  },
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: _validateConfirmPassword,
                              onFieldSubmitted: (_) => _submit(),
                            ),
                          ],
                          const SizedBox(height: 22),
                          FilledButton(
                            key: const Key('auth-submit'),
                            onPressed: _submitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                            child: _submitting
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        _isSignup
                                            ? _t(
                                                'Creating account...',
                                                'اکاؤنٹ بنایا جا رہا ہے...',
                                              )
                                            : _t(
                                                'Logging in...',
                                                'لاگ ان ہو رہا ہے...',
                                              ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    _isSignup
                                        ? _t('Create account', 'اکاؤنٹ بنائیں')
                                        : _t('Log in', 'لاگ ان'),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                          ),
                          const SizedBox(height: 9),
                          TextButton(
                            key: const Key('auth-switch-mode'),
                            onPressed: _submitting
                                ? null
                                : () => _switchMode(
                                    _isSignup
                                        ? AuthMode.login
                                        : AuthMode.signup,
                                  ),
                            child: Text(
                              _isSignup
                                  ? _t(
                                      'Already have an account? Log in',
                                      'پہلے سے اکاؤنٹ ہے؟ لاگ ان کریں',
                                    )
                                  : _t(
                                      'New here? Create an account',
                                      'نئے ہیں؟ اکاؤنٹ بنائیں',
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _t(
                      'Passwords are sent only to the NurtureSteps server and are never saved on this device.',
                      'پاس ورڈ صرف NurtureSteps سرور کو بھیجا جاتا ہے اور اس ڈیوائس پر محفوظ نہیں ہوتا۔',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF829497),
                      fontSize: 11,
                      height: 1.5,
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

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              key: const Key('auth-mode-login'),
              label: _t('Log in', 'لاگ ان'),
              selected: !_isSignup,
              onTap: () => _switchMode(AuthMode.login),
            ),
          ),
          Expanded(
            child: _ModeButton(
              key: const Key('auth-mode-signup'),
              label: _t('Sign up', 'سائن اپ'),
              selected: _isSignup,
              onTap: () => _switchMode(AuthMode.signup),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage({required String message, required bool isSuccess}) {
    final color = isSuccess ? const Color(0xFF2F7D5D) : const Color(0xFFB44747);

    return Container(
      key: Key(isSuccess ? 'auth-success' : 'auth-error'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess ? const Color(0xFFEAF7F0) : const Color(0xFFFDEEEE),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isSuccess ? const Color(0xFFC9E9D8) : const Color(0xFFF2CFCF),
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
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: selected ? Colors.white : const Color(0xFF587477),
        backgroundColor: selected
            ? const Color(0xFF347F83)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class ParentConsentRecord {
  ParentConsentRecord({
    required this.parentName,
    required this.parentEmail,
    required this.acceptedAt,
    required this.generalConsent,
    required this.privacyAcknowledged,
    required this.screeningAcknowledged,
  });

  final String parentName;
  final String parentEmail;
  final DateTime acceptedAt;
  final bool generalConsent;
  final bool privacyAcknowledged;
  final bool screeningAcknowledged;

  static ParentConsentRecord? latest;
}

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({
    super.key,
    required this.parentName,
    required this.parentEmail,
  });

  final String parentName;
  final String parentEmail;

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  @override
  void initState() {
    super.initState();
    final saved = AppState.parentConsent;
    if (saved != null) {
      ParentConsentRecord.latest = ParentConsentRecord(
        parentName: (saved['parentName'] ?? '').toString(),
        parentEmail: (saved['parentEmail'] ?? '').toString(),
        acceptedAt:
            DateTime.tryParse((saved['acceptedAt'] ?? '').toString()) ??
            DateTime.now(),
        generalConsent: saved['generalConsent'] == true,
        privacyAcknowledged: saved['privacyAcknowledged'] == true,
        screeningAcknowledged: saved['screeningAcknowledged'] == true,
      );
    }
  }

  static const Color primary = Color(0xFF347F83);
  static const Color dark = Color(0xFF235B68);
  static const Color background = Color(0xFFF4F8F8);
  static const Color muted = Color(0xFF657D80);

  bool generalConsent = true;
  bool privacyAcknowledged = true;
  bool screeningAcknowledged = true;

  bool isSubmitting = false;

  bool get isUrdu => NurtureLanguage.isUrdu;

  bool get canContinue => !isSubmitting;

  void acceptConsent() {
    if (!canContinue) return;

    setState(() => isSubmitting = true);

    final acceptedAt = DateTime.now();
    ParentConsentRecord.latest = ParentConsentRecord(
      parentName: widget.parentName,
      parentEmail: widget.parentEmail,
      acceptedAt: acceptedAt,
      generalConsent: generalConsent,
      privacyAcknowledged: privacyAcknowledged,
      screeningAcknowledged: screeningAcknowledged,
    );
    AppState.saveParentConsent({
      'parentName': widget.parentName,
      'parentEmail': widget.parentEmail,
      'acceptedAt': acceptedAt.toIso8601String(),
      'generalConsent': generalConsent,
      'privacyAcknowledged': privacyAcknowledged,
      'screeningAcknowledged': screeningAcknowledged,
    });

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LocalChildProfileScreen(
          parentName: widget.parentName,
          parentEmail: widget.parentEmail,
        ),
      ),
    );
  }

  void declineConsent() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 360 ? 15.0 : 20.0;

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: dark),
          title: Text(
            isUrdu ? 'والدین کی اجازت' : 'Parent / Guardian Consent',
            style: const TextStyle(
              color: dark,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 650),
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        16,
                        horizontalPadding,
                        25,
                      ),
                      children: [
                        _buildHeader(),

                        const SizedBox(height: 23),

                        _buildSection(
                          icon: Icons.folder_shared_outlined,
                          title: isUrdu
                              ? '1۔ کون سی معلومات لی جا سکتی ہیں؟'
                              : '1. Information We May Collect',
                          description: isUrdu
                              ? 'بچے کا نام، تاریخِ پیدائش، نشوونما کے مراحل، سوالنامے کے جوابات اور والدین کی درج کردہ سرگرمیوں کے مشاہدات۔'
                              : 'The app may ask for the child’s name, date of birth, developmental milestone records, questionnaire responses, and observations entered by the parent or caregiver.',
                        ),

                        _buildSection(
                          icon: Icons.track_changes_outlined,
                          title: isUrdu
                              ? '2۔ معلومات کا مقصد'
                              : '2. Why This Information Is Used',
                          description: isUrdu
                              ? 'یہ معلومات بچے کی نشوونما کی نگرانی، ریکارڈ رکھنے اور والدین کو تعلیمی رہنمائی فراہم کرنے کے لیے استعمال ہوں گی۔'
                              : 'This information is intended to support developmental monitoring, maintain records, and provide educational guidance to parents and caregivers.',
                        ),

                        _buildSection(
                          icon: Icons.lock_outline,
                          title: isUrdu
                              ? '3۔ رازداری اور موجودہ پروٹوٹائپ'
                              : '3. Privacy and Current Prototype',
                          description: isUrdu
                              ? 'موجودہ پروٹوٹائپ میں مستقل سرور یا آن لائن ڈیٹابیس منسلک نہیں ہے۔ ریکارڈ فی الحال ایپ کے عارضی سیشن میں رکھا جاتا ہے۔ ایپ بند ہونے پر یہ ریکارڈ محفوظ رہنے کی ضمانت نہیں۔'
                              : 'This prototype currently has no connected online database or server. Records are held temporarily in the app session and are not guaranteed to remain after the app closes.',
                        ),

                        _buildSection(
                          icon: Icons.health_and_safety_outlined,
                          title: isUrdu
                              ? '4۔ اسکریننگ کی حدود'
                              : '4. Screening Limitations',
                          description: isUrdu
                              ? 'ایپ کی معلومات اور اسکریننگ طبی تشخیص نہیں ہیں۔ یہ آٹزم یا کسی دوسری بیماری کی تصدیق نہیں کرتیں۔ خدشات کی صورت میں مستند ڈاکٹر یا ماہر سے رابطہ کریں۔'
                              : 'App information and screening are not a medical diagnosis. They cannot confirm autism or any other condition. If you have concerns about your child’s development, consult a qualified healthcare professional.',
                        ),

                        _buildSection(
                          icon: Icons.mic_none_outlined,
                          title: isUrdu
                              ? '5۔ کیمرہ اور مائیکروفون'
                              : '5. Camera and Microphone',
                          description: isUrdu
                              ? 'اگر مستقبل میں کسی فیچر کو کیمرہ یا مائیکروفون درکار ہوا تو اس کی اجازت الگ سے مانگی جائے گی۔'
                              : 'If a future feature requires camera or microphone access, the app will request that permission separately when needed.',
                        ),

                        const SizedBox(height: 17),

                        _buildAcknowledgementHeader(),

                        const SizedBox(height: 12),

                        _consentTile(
                          value: generalConsent,
                          onChanged: (value) {
                            setState(() {
                              generalConsent = value;
                            });
                          },
                          title: isUrdu
                              ? 'میں بچے کا والدین یا قانونی سرپرست ہوں اور بچے کی معلومات درج کرنے کی اجازت دیتا/دیتی ہوں۔'
                              : 'I am the child’s parent or legal guardian, and I authorize entering the child’s information into this app.',
                          icon: Icons.family_restroom,
                        ),

                        _consentTile(
                          value: privacyAcknowledged,
                          onChanged: (value) {
                            setState(() {
                              privacyAcknowledged = value;
                            });
                          },
                          title: isUrdu
                              ? 'میں نے معلومات کے استعمال اور موجودہ پروٹوٹائپ کی رازداری سے متعلق وضاحت پڑھ اور سمجھ لی ہے۔'
                              : 'I have read and understood the information-use and privacy explanation for this prototype.',
                          icon: Icons.privacy_tip_outlined,
                        ),

                        _consentTile(
                          value: screeningAcknowledged,
                          onChanged: (value) {
                            setState(() {
                              screeningAcknowledged = value;
                            });
                          },
                          title: isUrdu
                              ? 'میں سمجھتا/سمجھتی ہوں کہ اسکریننگ تشخیص نہیں اور ضرورت پڑنے پر ماہر سے رجوع کرنا چاہیے۔'
                              : 'I understand that screening is not a diagnosis and that professional advice may be needed.',
                          icon: Icons.medical_information_outlined,
                        ),

                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF3F3),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.schedule_outlined,
                                color: primary,
                                size: 19,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  isUrdu
                                      ? 'اجازت دینے کی تاریخ اور وقت ریکارڈ کیا جائے گا۔'
                                      : 'The date and time of consent will be recorded.',
                                  style: const TextStyle(
                                    color: dark,
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE5F3F1), Color(0xFFF4FAF9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD6EAE7)),
      ),
      child: Column(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.shield_outlined, size: 39, color: primary),
          ),
          const SizedBox(height: 15),
          Text(
            isUrdu
                ? 'آپ کے بچے کی حفاظت اور رازداری اہم ہے'
                : 'Your Child’s Safety Comes First',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              height: 1.4,
              fontWeight: FontWeight.w800,
              color: dark,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            isUrdu
                ? 'بچے کی معلومات درج کرنے سے پہلے براہِ کرم درج ذیل معلومات پڑھیں۔'
                : 'Please review how this app handles child information before creating a child profile.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, height: 1.7, color: muted),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE6EEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4F2),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: primary, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: dark,
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.start,
            style: const TextStyle(fontSize: 12.5, height: 1.75, color: muted),
          ),
        ],
      ),
    );
  }

  Widget _buildAcknowledgementHeader() {
    return Row(
      children: [
        const Icon(Icons.fact_check_outlined, color: primary, size: 23),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            isUrdu ? 'آپ کی تصدیق' : 'Your Acknowledgements',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: dark,
            ),
          ),
        ),
        Text(
          '${[generalConsent, privacyAcknowledged, screeningAcknowledged].where((v) => v).length}/3',
          style: const TextStyle(
            color: primary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _consentTile({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String title,
    required IconData icon,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: value ? const Color(0xFFEDF7F4) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: value ? primary : const Color(0xFFE1EAEA),
          width: value ? 1.4 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: (checked) {
          onChanged(checked ?? false);
        },
        activeColor: primary,
        checkColor: Colors.white,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        dense: false,
        secondary: Icon(
          icon,
          color: value ? primary : const Color(0xFF829497),
          size: 21,
        ),
        title: Text(
          title,
          textAlign: TextAlign.start,
          style: const TextStyle(
            fontSize: 12,
            height: 1.65,
            color: Color(0xFF45666B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 13, 20, 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5EEEE))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 51,
                child: FilledButton.icon(
                  onPressed: canContinue ? acceptConsent : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    disabledBackgroundColor: const Color(0xFFDCE7E7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    isUrdu ? 'اجازت دیں اور جاری رکھیں' : 'Agree and Continue',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              TextButton(
                onPressed: declineConsent,
                child: Text(
                  isUrdu ? 'اجازت نہیں دینی' : 'Decline Consent',
                  style: const TextStyle(
                    color: Color(0xFF9A5555),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
