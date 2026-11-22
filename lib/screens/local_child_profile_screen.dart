import 'package:flutter/material.dart';

import '../app_state.dart';
import 'welcome_screen.dart';
import 'dashboard_screen.dart';

class LocalChildProfileScreen extends StatefulWidget {
  const LocalChildProfileScreen({
    super.key,
    required this.parentName,
    required this.parentEmail,
  });

  final String parentName;
  final String parentEmail;

  @override
  State<LocalChildProfileScreen> createState() => _LocalLocalChildProfileScreenState();
}

class _LocalLocalChildProfileScreenState extends State<LocalChildProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _childNameController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime? selectedDateOfBirth;
  String? selectedGender;
  String? selectedRelationship;

  bool isCreating = false;

  bool get isUrdu => NurtureLanguage.isUrdu;

  DateTime get today => DateUtils.dateOnly(DateTime.now());

  int calculateAgeInMonths(DateTime dob) {
    final now = today;
    int months = (now.year - dob.year) * 12 + now.month - dob.month;

    if (now.day < dob.day) {
      months--;
    }

    return months;
  }

  String formatAge(DateTime dob) {
    final months = calculateAgeInMonths(dob);
    final years = months ~/ 12;
    final remainingMonths = months % 12;

    if (isUrdu) {
      return '$years سال، $remainingMonths ماہ';
    }

    if (years == 0) return '$months months old';

    if (remainingMonths == 0) {
      return '$years years old';
    }

    return '$years years, $remainingMonths months old';
  }

  Future<void> chooseDateOfBirth() async {
    final now = today;

    final initialDate =
        selectedDateOfBirth ?? DateTime(now.year - 2, now.month, now.day);

    final firstDate = DateTime(now.year - 6, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? now : initialDate,
      firstDate: firstDate,
      lastDate: now,
      helpText: isUrdu
          ? 'بچے کی تاریخ پیدائش منتخب کریں'
          : 'Select Child Date of Birth',
      cancelText: isUrdu ? 'منسوخ' : 'Cancel',
      confirmText: isUrdu ? 'منتخب کریں' : 'Select',
      builder: (context, child) {
        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF347F83),
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
      selectedDateOfBirth = DateUtils.dateOnly(picked);
    });
  }

  String? validateChildName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return isUrdu ? 'بچے کا نام درج کریں' : 'Please enter child name';
    }

    if (value.trim().length < 2) {
      return isUrdu ? 'درست نام درج کریں' : 'Enter a valid name';
    }

    return null;
  }

  String? validatePhone(String? value) {
    final phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return isUrdu ? 'فون نمبر درج کریں' : 'Please enter phone number';
    }

    final digits = phone.replaceAll(RegExp(r'[\s+\-()]'), '');

    if (!RegExp(r'^\d{10,15}$').hasMatch(digits)) {
      return isUrdu ? 'درست فون نمبر درج کریں' : 'Enter a valid phone number';
    }

    return null;
  }

  String? validateGender(String? value) {
    if (value == null || value.isEmpty) {
      return isUrdu ? 'جنس منتخب کریں' : 'Please select gender';
    }
    return null;
  }

  String? validateRelationship(String? value) {
    if (value == null || value.isEmpty) {
      return isUrdu ? 'رشتہ منتخب کریں' : 'Please select relationship';
    }
    return null;
  }

  Future<void> createProfile() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (selectedDateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUrdu
                ? 'بچے کی تاریخ پیدائش منتخب کریں'
                : 'Please select the child’s date of birth',
          ),
        ),
      );
      return;
    }

    final dob = selectedDateOfBirth!;
    final ageMonths = calculateAgeInMonths(dob);

    if (dob.isAfter(today)) {
      showError(
        isUrdu
            ? 'مستقبل کی تاریخ پیدائش قابل قبول نہیں۔'
            : 'A future date of birth is not allowed.',
      );
      return;
    }

    if (ageMonths < 12 || ageMonths >= 72) {
      showError(
        isUrdu
            ? 'اس ایپ کے لیے بچے کی عمر 12 سے 71 ماہ ہونی چاہیے۔'
            : 'This app supports children aged 12 to 71 months only.',
      );
      return;
    }

    setState(() => isCreating = true);

    final childName = _childNameController.text.trim();
    final profile = ChildProfileRecord(
      id: AppState.createId(),
      childName: childName,
      dateOfBirth: dob,
      gender: selectedGender!,
      parentName: widget.parentName,
      parentEmail: widget.parentEmail,
      relationship: selectedRelationship!,
      phone: _phoneController.text.trim(),
      createdAt: DateTime.now(),
    );

    final saved = AppState.addChildProfile(profile);

    if (!mounted) return;

    setState(() => isCreating = false);

    if (!saved) {
      showError(
        isUrdu
            ? 'اس نام اور تاریخ پیدائش کی پروفائل پہلے سے موجود ہے۔'
            : 'A profile with this child name and date of birth already exists.',
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          childName: childName,
          dateOfBirth: dob,
          gender: selectedGender!,
          parentName: widget.parentName,
          parentEmail: widget.parentEmail,
          relationship: selectedRelationship!,
          phone: _phoneController.text.trim(),
        ),
      ),
    );
  }

  void showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _childNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F8F8),
        appBar: AppBar(
          title: Text(
            isUrdu ? 'بچے کی پروفائل' : 'Child Profile',
            style: const TextStyle(
              color: Color(0xFF235B68),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF347F83).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.child_care_rounded,
                            size: 45,
                            color: Color(0xFF347F83),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isUrdu
                                ? 'اپنے بچے کی پروفائل بنائیں'
                                : 'Create Your Child’s Profile',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF235B68),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            isUrdu
                                ? 'درست معلومات درج کریں تاکہ عمر کے مطابق نشوونما کی نگرانی کی جا سکے۔'
                                : 'Enter accurate information to support age-appropriate developmental monitoring.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.6,
                              color: Color(0xFF718588),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    Container(
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
                            _label(isUrdu ? 'بچے کا نام' : 'Child Name'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _childNameController,
                              validator: validateChildName,
                              textCapitalization: TextCapitalization.words,
                              decoration: _decoration(
                                isUrdu
                                    ? 'بچے کا نام درج کریں'
                                    : 'Enter child name',
                                Icons.person_outline_rounded,
                              ),
                            ),

                            const SizedBox(height: 19),

                            _label(isUrdu ? 'تاریخ پیدائش' : 'Date of Birth'),
                            const SizedBox(height: 8),

                            InkWell(
                              onTap: chooseDateOfBirth,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 17,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FBFB),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFDCE8E8),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_month_rounded,
                                      color: Color(0xFF347F83),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        selectedDateOfBirth == null
                                            ? (isUrdu
                                                  ? 'تاریخ منتخب کریں'
                                                  : 'Select date of birth')
                                            : '${selectedDateOfBirth!.day.toString().padLeft(2, '0')}/${selectedDateOfBirth!.month.toString().padLeft(2, '0')}/${selectedDateOfBirth!.year}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: selectedDateOfBirth == null
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

                            if (selectedDateOfBirth != null) ...[
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
                                      color: Color(0xFF347F83),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '${isUrdu ? 'موجودہ عمر:' : 'Current age:'} ${formatAge(selectedDateOfBirth!)}',
                                        style: const TextStyle(
                                          color: Color(0xFF235B68),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 19),

                            _label(isUrdu ? 'جنس' : 'Gender'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: selectedGender,
                              validator: validateGender,
                              decoration: _decoration(
                                isUrdu ? 'جنس منتخب کریں' : 'Select gender',
                                Icons.wc_rounded,
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'Male',
                                  child: Text(isUrdu ? 'لڑکا' : 'Male'),
                                ),
                                DropdownMenuItem(
                                  value: 'Female',
                                  child: Text(isUrdu ? 'لڑکی' : 'Female'),
                                ),
                                DropdownMenuItem(
                                  value: 'Other',
                                  child: Text(isUrdu ? 'دیگر' : 'Other'),
                                ),
                                DropdownMenuItem(
                                  value: 'Prefer not to say',
                                  child: Text(
                                    isUrdu
                                        ? 'بتانا نہیں چاہتے'
                                        : 'Prefer not to say',
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => selectedGender = value);
                              },
                            ),

                            const SizedBox(height: 19),

                            _label(
                              isUrdu ? 'بچے سے رشتہ' : 'Relationship to Child',
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: selectedRelationship,
                              validator: validateRelationship,
                              decoration: _decoration(
                                isUrdu
                                    ? 'رشتہ منتخب کریں'
                                    : 'Select relationship',
                                Icons.family_restroom_rounded,
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'Mother',
                                  child: Text(isUrdu ? 'والدہ' : 'Mother'),
                                ),
                                DropdownMenuItem(
                                  value: 'Father',
                                  child: Text(isUrdu ? 'والد' : 'Father'),
                                ),
                                DropdownMenuItem(
                                  value: 'Guardian',
                                  child: Text(isUrdu ? 'سرپرست' : 'Guardian'),
                                ),
                                DropdownMenuItem(
                                  value: 'Other',
                                  child: Text(isUrdu ? 'دیگر' : 'Other'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => selectedRelationship = value);
                              },
                            ),

                            const SizedBox(height: 19),

                            _label(
                              isUrdu
                                  ? 'والدین کا فون نمبر'
                                  : 'Parent Phone Number',
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _phoneController,
                              validator: validatePhone,
                              keyboardType: TextInputType.phone,
                              decoration: _decoration(
                                isUrdu
                                    ? 'فون نمبر درج کریں'
                                    : 'e.g. 03XXXXXXXXX',
                                Icons.phone_outlined,
                              ),
                            ),

                            const SizedBox(height: 25),

                            SizedBox(
                              height: 54,
                              child: FilledButton(
                                onPressed: isCreating ? null : createProfile,
                                child: isCreating
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            isUrdu
                                                ? 'پروفائل بنائیں'
                                                : 'Create Child Profile',
                                          ),
                                          const SizedBox(width: 9),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 19,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      isUrdu
                          ? 'اس ایپ میں 12 سے 71 ماہ کے بچوں کی نشوونما کی نگرانی کی جاتی ہے۔'
                          : 'NurtureSteps currently supports developmental monitoring for children aged 12–71 months.',
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
          ),
        ),
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
