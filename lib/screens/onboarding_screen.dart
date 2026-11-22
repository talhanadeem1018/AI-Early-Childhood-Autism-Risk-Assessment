import 'package:flutter/material.dart';

import 'welcome_screen.dart';
import 'auth_screen.dart';
import '../widgets/nurse_mascot.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;

  int currentPage = 0;

  bool get isUrdu => NurtureLanguage.isUrdu;

  List<_OnboardingData> get pages => [
    _OnboardingData(
      icon: Icons.child_care_rounded,
      title: isUrdu ? 'ہر بچے کا اپنا سفر' : 'Every Child Has a Journey',
      description: isUrdu
          ? 'اپنے بچے کی نشوونما کو عمر کے مطابق سمجھیں اور اس کے اہم مراحل کو محفوظ رکھیں۔'
          : 'Understand your child’s development according to their age and keep track of important milestones.',
      color: const Color(0xFF347F83),
    ),
    _OnboardingData(
      icon: Icons.track_changes_rounded,
      title: isUrdu ? 'نشوونما کی نگرانی' : 'Track Development',
      description: isUrdu
          ? 'نشوونما کے مراحل اور روزمرہ کی سرگرمیوں کا ریکارڈ رکھیں۔'
          : 'Record developmental milestones and everyday observations in one place.',
      color: const Color(0xFF8A79B8),
    ),
    _OnboardingData(
      icon: Icons.favorite_rounded,
      title: isUrdu ? 'رہنمائی اور آگاہی' : 'Guidance and Awareness',
      description: isUrdu
          ? 'مفید معلومات حاصل کریں۔ یاد رکھیں، ایپ کی اسکریننگ طبی تشخیص کا متبادل نہیں۔'
          : 'Explore helpful information. Remember, app-based screening is not a medical diagnosis.',
      color: const Color(0xFFE28B75),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  void nextPage() {
    if (currentPage < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      openAuth();
    }
  }

  void openAuth() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) => const AuthScreen(),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingPages = pages;

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F9F9),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 650;

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  compact ? 8 : 15,
                  24,
                  compact ? 14 : 22,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'NurtureSteps',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF235B68),
                          ),
                        ),
                        TextButton(
                          onPressed: openAuth,
                          child: Text(
                            isUrdu ? 'چھوڑیں' : 'Skip',
                            style: const TextStyle(
                              color: Color(0xFF668184),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 2 : 10),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: onboardingPages.length,
                        onPageChanged: (index) {
                          setState(() => currentPage = index);
                        },
                        itemBuilder: (context, index) {
                          final page = onboardingPages[index];

                          return _OnboardingPage(
                            key: ValueKey(index),
                            page: page,
                            index: index,
                            isUrdu: isUrdu,
                            compact: compact,
                          );
                        },
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(onboardingPages.length, (index) {
                        final selected = currentPage == index;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 7,
                          width: selected ? 25 : 7,
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF347F83)
                                : const Color(0xFFD3E2E1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: compact ? 14 : 23),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: nextPage,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currentPage == onboardingPages.length - 1
                                  ? (isUrdu ? 'آگے بڑھیں' : 'Continue')
                                  : (isUrdu ? 'اگلا' : 'Next'),
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
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    super.key,
    required this.page,
    required this.index,
    required this.isUrdu,
    required this.compact,
  });

  final _OnboardingData page;
  final int index;
  final bool isUrdu;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final illustrationSize = compact ? 185.0 : 230.0;
    final innerIllustrationSize = compact ? 142.0 : 175.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: illustrationSize,
                    height: illustrationSize,
                    decoration: BoxDecoration(
                      color: page.color.withValues(alpha: 0.09),
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: innerIllustrationSize,
                          height: innerIllustrationSize,
                          decoration: BoxDecoration(
                            color: page.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (index == 0)
                          NurseMascot(size: compact ? 140 : 175)
                        else
                          Icon(
                            page.icon,
                            size: compact ? 82 : 105,
                            color: page.color,
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: compact ? 22 : 35),
                  Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isUrdu ? 24 : 25,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF235B68),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    page.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.8,
                      color: Color(0xFF708487),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
}
