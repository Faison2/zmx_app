import 'package:flutter/material.dart';
import 'package:zmx/screens/auth/login/login.dart';

import '../../dashboard/dashoard.dart';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // ── Step 1: Credentials ───────────────────────────────────────────────
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // ── Step 2: Personal Info ─────────────────────────────────────────────
  String? _selectedTitle;
  String? _selectedGender;
  String? _selectedNationality;
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _dobController = TextEditingController();
  final _idController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();

  // ── Step 3: Banking Details ───────────────────────────────────────────
  final _zigBankController = TextEditingController();
  final _zigBranchController = TextEditingController();
  final _zigAccountController = TextEditingController();
  final _usdBankController = TextEditingController();
  final _usdBranchController = TextEditingController();
  final _usdAccountController = TextEditingController();

  // ── Step 4: Security Questions ────────────────────────────────────────
  final _maidenNameController = TextEditingController();
  final _favBookController = TextEditingController();
  final _roadController = TextEditingController();

  final List<String> _titles = ['Mr', 'Mrs', 'Ms', 'Dr', 'Prof'];
  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _nationalities = ['Zimbabwean', 'South African', 'Zambian', 'Botswanan', 'Other'];

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _dobController.dispose();
    _idController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _zigBankController.dispose();
    _zigBranchController.dispose();
    _zigAccountController.dispose();
    _usdBankController.dispose();
    _usdBranchController.dispose();
    _usdAccountController.dispose();
    _maidenNameController.dispose();
    _favBookController.dispose();
    _roadController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image ──────────────────────────────────────
          Image.asset('assets/images/splash.png', fit: BoxFit.cover),

          // ── Dark overlay ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.55),
                  Colors.black.withOpacity(0.45),
                  Colors.black.withOpacity(0.60),
                ],
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: _prevStep,
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 0, 0),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ),

                // Logo
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Image.asset('assets/images/logo.png',
                      height: 70, fit: BoxFit.contain),
                ),

                // SIGN UP title
                const Text(
                  'SIGN UP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 8),

                // Step indicator dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final isActive = i == _currentStep;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF2DB144)
                            : Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 12),

                // ── Pages ─────────────────────────────────────────
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1(),
                      _buildStep2(),
                      _buildStep3(),
                      _buildStep4(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // STEP 1 — Log in Credentials
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          const Text(
            'Log in Credentials',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _emailController,
            hint: 'Email Address',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _passwordController,
            hint: 'Password',
            obscure: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: Colors.white70,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _confirmPasswordController,
            hint: 'Confirm Password',
            obscure: _obscureConfirm,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                color: Colors.white70,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          const SizedBox(height: 32),
          _buildBottomButtons(
            showBack: true,
            nextLabel: 'Continue',
            onNext: _nextStep,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // STEP 2 — Personal Information
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          // Title + Gender row
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  hint: 'Title',
                  value: _selectedTitle,
                  items: _titles,
                  onChanged: (v) => setState(() => _selectedTitle = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  hint: 'Gender',
                  value: _selectedGender,
                  items: _genders,
                  onChanged: (v) => setState(() => _selectedGender = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildTextField(controller: _nameController, hint: 'Name'),
          const SizedBox(height: 14),
          _buildTextField(controller: _surnameController, hint: 'Surname'),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _dobController,
            hint: 'Date Of Birth',
            keyboardType: TextInputType.datetime,
            suffixIcon: const Icon(Icons.calendar_today_rounded,
                color: Colors.white70, size: 18),
          ),
          const SizedBox(height: 14),
          _buildDropdown(
            hint: 'Nationality',
            value: _selectedNationality,
            items: _nationalities,
            onChanged: (v) => setState(() => _selectedNationality = v),
          ),
          const SizedBox(height: 14),
          _buildTextField(controller: _idController, hint: 'ID Number'),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _mobileController,
            hint: 'Mobile Number',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          _buildTextField(controller: _addressController, hint: 'Address'),
          const SizedBox(height: 32),
          _buildBottomButtons(
            showBack: false,
            nextLabel: 'Continue',
            onNext: _nextStep,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // STEP 3 — Banking Details
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Banking Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          // ZiG section
          Text(
            'ZiG Banking Details',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          _buildTextField(controller: _zigBankController, hint: 'Bank'),
          const SizedBox(height: 12),
          _buildTextField(controller: _zigBranchController, hint: 'Branch'),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _zigAccountController,
            hint: 'Bank Account',
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 22),

          // USD section
          Text(
            'USD Banking Details',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          _buildTextField(controller: _usdBankController, hint: 'Bank'),
          const SizedBox(height: 12),
          _buildTextField(controller: _usdBranchController, hint: 'Branch'),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _usdAccountController,
            hint: 'Bank Account',
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 32),
          _buildBottomButtons(
            showBack: true,
            nextLabel: 'Continue',
            onNext: _nextStep,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // STEP 4 — Security Questions
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          const Text(
            'Security Questions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _maidenNameController,
            hint: "Mother's maiden name",
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _favBookController,
            hint: 'Favourite book',
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _roadController,
            hint: 'Road you grew up on',
          ),
          const SizedBox(height: 32),
          _buildBottomButtons(
            showBack: true,
            nextLabel: 'SIGN UP',
            isLastStep: true,
            onNext: () {
              // TODO: submit registration
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Reusable Widgets
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
            color: const Color(0xFFD4A017).withOpacity(0.7), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
          TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 15),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
            color: const Color(0xFFD4A017).withOpacity(0.7), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.65), fontSize: 15)),
          icon: const Icon(Icons.arrow_drop_down_rounded,
              color: Colors.white70),
          dropdownColor: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(16),
          style: const TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildBottomButtons({
    required bool showBack,
    required String nextLabel,
    required VoidCallback onNext,
    bool isLastStep = false,
  }) {
    return Row(
      children: [
        if (showBack) ...[
          Expanded(
            child: GestureDetector(
              onTap: _prevStep,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A017),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4A017).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Text(
                  'Back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: GestureDetector(
            onTap: onNext,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2DB144),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2DB144).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                nextLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}