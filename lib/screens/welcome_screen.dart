import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../widgets/nurse_mascot.dart';
import 'auth_screen.dart';
import 'onboarding_screen.dart';

class NurtureLanguage {
  NurtureLanguage._();

  static String current = 'en';

  static bool get isUrdu => current == 'ur';
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.session});

  final SessionService? session;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String selectedLanguage = NurtureLanguage.current == 'ur' ? 'ur' : 'en';

  bool get isUrdu => selectedLanguage == 'ur';

  void selectLanguage(String language) {
    setState(() {
      selectedLanguage = language;
      NurtureLanguage.current = language;
    });
  }

  void openAuth(AuthMode mode) {
    NurtureLanguage.current = selectedLanguage;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthScreen(session: widget.session, initialMode: mode),
      ),
    );
  }

  void continueToApp() {
    NurtureLanguage.current = selectedLanguage;

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) =>
            const OnboardingScreen(),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF3FAF9), Color(0xFFEAF5F4), Color(0xFFF8FAFC)],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 700;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 18,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 36,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 43,
                              height: 43,
                              decoration: BoxDecoration(
                                color: const Color(0xFF347F83),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: Colors.white,
                                size: 25,
                              ),
                            ),
                            const SizedBox(width: 11),
                            const Text(
                              'NurtureSteps',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                                color: Color(0xFF235B68),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: compact ? 12 : 25),

                        NurseMascot(size: compact ? 145 : 190),

                        SizedBox(height: compact ? 8 : 17),

                        Text(
                          isUrdu
                              ? 'بچوں کی نشوونما کا خیال'
                              : 'Every Little Step Matters',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isUrdu ? 25 : 27,
                            height: 1.3,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF235B68),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          isUrdu
                              ? 'اپنے بچے کی نشوونما کو سمجھیں، اہم سنگِ میل دیکھیں اور ہر قدم پر رہنمائی حاصل کریں۔'
                              : 'Understand your child’s development, track important milestones, and get guidance at every step.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.7,
                            color: Color(0xFF687F83),
                          ),
                        ),

                        SizedBox(height: compact ? 20 : 30),

                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(color: const Color(0xFFDDEAE9)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _LanguageButton(
                                  title: 'English',
                                  selected: selectedLanguage == 'en',
                                  onTap: () => selectLanguage('en'),
                                ),
                              ),
                              Expanded(
                                child: _LanguageButton(
                                  title: 'اردو',
                                  selected: selectedLanguage == 'ur',
                                  onTap: () => selectLanguage('ur'),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: continueToApp,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isUrdu ? 'شروع کریں' : 'Get Started',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 9),
                                Icon(
                                  isUrdu
                                      ? Icons.arrow_back_rounded
                                      : Icons.arrow_forward_rounded,
                                  size: 19,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                key: const Key('welcome-login'),
                                onPressed: () => openAuth(AuthMode.login),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF347F83),
                                  side: const BorderSide(
                                    color: Color(0xFFBBDCD9),
                                  ),
                                ),
                                child: Text(isUrdu ? 'لاگ ان' : 'Log in'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                key: const Key('welcome-signup'),
                                onPressed: () => openAuth(AuthMode.signup),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF347F83),
                                  side: const BorderSide(
                                    color: Color(0xFFBBDCD9),
                                  ),
                                ),
                                child: Text(
                                  isUrdu ? 'اکاؤنٹ بنائیں' : 'Create account',
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        Text(
                          isUrdu
                              ? 'والدین اور دیکھ بھال کرنے والوں کے لیے'
                              : 'Designed for parents and caregivers',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF829598),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF347F83) : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : const Color(0xFF587477),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
