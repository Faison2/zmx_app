import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zmx/screens/auth/login/login.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // ── Bank data from API ─────────────────────────────────────────────
  List<Map<String, String>> _banks = [];
  bool _loadingBanks = false;

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
  String? _selectedIdType;
  String? _selectedOccupation;
  String? _selectedIndustry;
  String? _selectedPepStatus;
  final _forenamesController = TextEditingController();
  final _surnameController = TextEditingController();
  final _middlenameController = TextEditingController();
  final _initialsController = TextEditingController();
  final _dobController = TextEditingController();
  final _idController = TextEditingController();
  final _mobileController = TextEditingController();
  final _telController = TextEditingController();
  final _add1Controller = TextEditingController();
  final _add2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _taxController = TextEditingController();

  // ── Step 3: Banking Details ───────────────────────────────────────────
  String? _selectedZigBank;
  final _zigBranchController = TextEditingController();
  final _zigAccountController = TextEditingController();
  String? _selectedUsdBank;
  final _usdBranchController = TextEditingController();
  final _usdAccountController = TextEditingController();
  String? _selectedMobileMoney;
  final _mobileMoneyNumberController = TextEditingController();

  // ── Step 4: Security Questions ────────────────────────────────────────
  final _maidenNameController = TextEditingController();
  final _favBookController = TextEditingController();
  final _roadController = TextEditingController();

  // ── Dropdown Options ──────────────────────────────────────────────────
  final List<String> _titles = ['Mr', 'Mrs', 'Ms', 'Dr', 'Prof'];
  final List<Map<String, String>> _genders = [
    {'label': 'Male', 'value': 'M'},
    {'label': 'Female', 'value': 'F'},
    {'label': 'Other', 'value': 'O'},
  ];
  final List<String> _nationalities = [
    'Zimbabwean', 'South African', 'Zambian', 'Botswanan', 'Other'
  ];
  final List<String> _idTypes = ['NID', 'PASSPORT', 'DRIVER_LICENSE'];
  final List<String> _occupations = [
    'Accountant', 'Engineer', 'Teacher', 'Doctor', 'Lawyer',
    'Business Owner', 'Student', 'Retired', 'Other'
  ];
  final List<String> _industries = [
    'Finance', 'Agriculture', 'Mining', 'Manufacturing', 'Retail',
    'Education', 'Health', 'Technology', 'Construction', 'Other'
  ];
  final List<String> _pepStatuses = ['YES', 'NO'];
  final List<String> _mobileMoneyOptions = ['EcoCash', 'OneMoney', 'Telecash'];

  @override
  void initState() {
    super.initState();
    _fetchBanks();
  }

  // ── Fetch Banks ───────────────────────────────────────────────────────
  Future<void> _fetchBanks() async {
    setState(() => _loadingBanks = true);
    try {
      final response = await http
          .get(Uri.parse('https://system.zmx.co.zw/ZMX-API/Subscriber'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _banks = data
              .map<Map<String, String>>((e) => {
            'code': (e['Code'] as String).trim(),
            'name': (e['Name'] as String).trim(),
          })
              .toList();
        });
      }
    } catch (e) {
      // Silently fail — user will see empty dropdown with retry option
    } finally {
      setState(() => _loadingBanks = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _forenamesController.dispose();
    _surnameController.dispose();
    _middlenameController.dispose();
    _initialsController.dispose();
    _dobController.dispose();
    _idController.dispose();
    _mobileController.dispose();
    _telController.dispose();
    _add1Controller.dispose();
    _add2Controller.dispose();
    _cityController.dispose();
    _taxController.dispose();
    _zigBranchController.dispose();
    _zigAccountController.dispose();
    _usdBranchController.dispose();
    _usdAccountController.dispose();
    _mobileMoneyNumberController.dispose();
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

  // ── Register API Call ─────────────────────────────────────────────────
  Future<void> _submitRegistration() async {
    setState(() => _isLoading = true);

    final body = {
      "password": _passwordController.text.trim(),
      "accountsClientsWeb": {
        "accountType": "i",
        "surname": _surnameController.text.trim(),
        "middlename": _middlenameController.text.trim(),
        "forenames": _forenamesController.text.trim(),
        "initials": _initialsController.text.trim(),
        "title": _selectedTitle ?? "",
        "iDNoPP": _idController.text.trim(),
        "iDtype": _selectedIdType ?? "NID",
        "nationality": _selectedNationality ?? "",
        "dob": _dobController.text.trim(),
        "gender": _selectedGender ?? "",
        "add1": _add1Controller.text.trim(),
        "add2": _add2Controller.text.trim(),
        "add3": _cityController.text.trim(),
        "add4": "",
        "country": "Zimbabwe",
        "city": _cityController.text.trim(),
        "tel": _telController.text.trim(),
        "mobile": _mobileController.text.trim(),
        "email": _emailController.text.trim(),
        "category": "C",
        "custodian": null,
        "tradingStatus": "DEALING ALLOWED",
        "industry": _selectedIndustry ?? "",
        "tax": _taxController.text.trim(),
        "divBank": _selectedZigBank ?? "",
        "divBranch": _zigBranchController.text.trim(),
        "divAccountNo": _zigAccountController.text.trim(),
        "cashBank": _selectedZigBank ?? "",
        "cashBranch": _zigBranchController.text.trim(),
        "cashAccountNo": _zigAccountController.text.trim(),
        "usdCashBranch": _usdBranchController.text.trim(),
        "usdCashBank": _selectedUsdBank ?? "",
        "usdCashAccount": _usdAccountController.text.trim(),
        "attachedDocuments": "",
        "accountState": "ACTIVE",
        "comments": "",
        "divPayee": "${_forenamesController.text.trim()} ${_surnameController.text.trim()}",
        "settlementPayee": "${_forenamesController.text.trim()} ${_surnameController.text.trim()}",
        "accountclass": "RETAIL",
        "idnopp2": "",
        "idtype2": "",
        "clientImage2": "",
        "documents2": "",
        "isin": "",
        "companyCode": "",
        "mobileMoney": _selectedMobileMoney ?? "",
        "mobileNumber": _mobileMoneyNumberController.text.trim(),
        "sttupdate": false,
        "currency": "USD",
        "tradingPlatform": "ZMX",
        "sourceName": "MOBILE", // hardcoded
        "client_occupation": _selectedOccupation ?? "",
        "industry_of_profession": _selectedIndustry ?? "",
        "pep_status": _selectedPepStatus ?? "NO",
      }
    };

    try {
      final response = await http
          .post(
        Uri.parse('https://ussd.zmx.co.zw/v1/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 30));

      final responseData = jsonDecode(response.body);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.statusCode == 200 && responseData['status'] == true) {
        _showSuccessDialog(responseData['cdsNumber'] ?? '');
      } else {
        _showErrorSnackbar(
            responseData['message'] ?? 'Registration failed. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackbar('Network error. Please check your connection.');
    }
  }

  void _showSuccessDialog(String cdsNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle_rounded,
                color: Color(0xFF2DB144), size: 60),
            SizedBox(height: 12),
            Text('Account Created!',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your CDS Account Number:',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 14)),
            const SizedBox(height: 6),
            Text(cdsNumber,
                style: const TextStyle(
                    color: Color(0xFFD4A017),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Text('Please save your CDS number for future reference.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.55), fontSize: 13)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2DB144),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              },
              child: const Text('Proceed to Login',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Date Picker ───────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF2DB144),
            surface: Color(0xFF2D2D2D),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _dobController.text =
      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/splash.png', fit: BoxFit.cover),
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
          SafeArea(
            child: Column(
              children: [
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
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Image.asset('assets/images/logo.png',
                      height: 70, fit: BoxFit.contain),
                ),
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
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF2DB144)),
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
          _buildStepTitle('Log in Credentials'),
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
          _buildStepTitle('Personal Information'),
          const SizedBox(height: 16),

          // Title + Gender
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  hint: 'Title',
                  value: _selectedTitle,
                  items: _titles.map((e) => {'label': e, 'value': e}).toList(),
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

          // Name + Surname
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                    controller: _forenamesController, hint: 'First Name'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                    controller: _surnameController, hint: 'Surname'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildTextField(
              controller: _middlenameController, hint: 'Middle Name (Optional)'),
          const SizedBox(height: 14),
          _buildTextField(
              controller: _initialsController, hint: 'Initials (e.g. J.P.D)'),
          const SizedBox(height: 14),

          // DOB
          GestureDetector(
            onTap: _pickDate,
            child: AbsorbPointer(
              child: _buildTextField(
                controller: _dobController,
                hint: 'Date of Birth (YYYY-MM-DD)',
                keyboardType: TextInputType.datetime,
                suffixIcon: const Icon(Icons.calendar_today_rounded,
                    color: Colors.white70, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Nationality
          _buildDropdown(
            hint: 'Nationality',
            value: _selectedNationality,
            items: _nationalities
                .map((e) => {'label': e, 'value': e})
                .toList(),
            onChanged: (v) => setState(() => _selectedNationality = v),
          ),
          const SizedBox(height: 14),

          // ID Type + ID Number
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  hint: 'ID Type',
                  value: _selectedIdType,
                  items: _idTypes
                      .map((e) => {'label': e, 'value': e})
                      .toList(),
                  onChanged: (v) => setState(() => _selectedIdType = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                    controller: _idController, hint: 'ID Number'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Mobile + Tel
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _mobileController,
                  hint: 'Mobile Number',
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _telController,
                  hint: 'Tel (Optional)',
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildTextField(controller: _add1Controller, hint: 'Address Line 1'),
          const SizedBox(height: 14),
          _buildTextField(
              controller: _add2Controller, hint: 'Address Line 2 (Optional)'),
          const SizedBox(height: 14),
          _buildTextField(controller: _cityController, hint: 'City'),
          const SizedBox(height: 14),
          _buildTextField(
              controller: _taxController, hint: 'Tax Number (Optional)'),
          const SizedBox(height: 14),

          // Occupation
          _buildDropdown(
            hint: 'Occupation',
            value: _selectedOccupation,
            items: _occupations
                .map((e) => {'label': e, 'value': e})
                .toList(),
            onChanged: (v) => setState(() => _selectedOccupation = v),
          ),
          const SizedBox(height: 14),

          // Industry
          _buildDropdown(
            hint: 'Industry',
            value: _selectedIndustry,
            items: _industries
                .map((e) => {'label': e, 'value': e})
                .toList(),
            onChanged: (v) => setState(() => _selectedIndustry = v),
          ),
          const SizedBox(height: 14),

          // PEP Status
          _buildDropdown(
            hint: 'PEP Status',
            value: _selectedPepStatus,
            items: _pepStatuses
                .map((e) => {'label': e, 'value': e})
                .toList(),
            onChanged: (v) => setState(() => _selectedPepStatus = v),
          ),

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
          Center(child: _buildStepTitle('Banking Details')),
          const SizedBox(height: 16),

          if (_loadingBanks)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Color(0xFF2DB144),
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('Loading banks...',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13)),
                  ],
                ),
              ),
            ),

          if (!_loadingBanks && _banks.isEmpty)
            Center(
              child: TextButton.icon(
                onPressed: _fetchBanks,
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFFD4A017)),
                label: const Text('Retry loading banks',
                    style: TextStyle(color: Color(0xFFD4A017))),
              ),
            ),

          // ZiG section
          _buildSectionLabel('ZiG Banking Details'),
          const SizedBox(height: 10),
          _buildBankDropdown(
            hint: 'ZiG Bank',
            value: _selectedZigBank,
            onChanged: (v) => setState(() => _selectedZigBank = v),
          ),
          const SizedBox(height: 12),
          _buildTextField(controller: _zigBranchController, hint: 'Branch'),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _zigAccountController,
            hint: 'Account Number',
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 22),

          // USD section
          _buildSectionLabel('USD Banking Details'),
          const SizedBox(height: 10),
          _buildBankDropdown(
            hint: 'USD Bank',
            value: _selectedUsdBank,
            onChanged: (v) => setState(() => _selectedUsdBank = v),
          ),
          const SizedBox(height: 12),
          _buildTextField(controller: _usdBranchController, hint: 'Branch'),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _usdAccountController,
            hint: 'Account Number',
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 22),

          // Mobile Money section
          _buildSectionLabel('Mobile Money'),
          const SizedBox(height: 10),
          _buildDropdown(
            hint: 'Mobile Money Provider',
            value: _selectedMobileMoney,
            items: _mobileMoneyOptions
                .map((e) => {'label': e, 'value': e})
                .toList(),
            onChanged: (v) => setState(() => _selectedMobileMoney = v),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _mobileMoneyNumberController,
            hint: 'Mobile Money Number',
            keyboardType: TextInputType.phone,
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
          _buildStepTitle('Security Questions'),
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
            onNext: _submitRegistration,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Reusable Widgets
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildStepTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withOpacity(0.75),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

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

  /// Generic dropdown — items must have 'label' and 'value' keys
  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<Map<String, String>> items,
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
              .map((e) =>
              DropdownMenuItem(value: e['value'], child: Text(e['label']!)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// Bank dropdown — built from fetched API data, displays Name, sends Code
  Widget _buildBankDropdown({
    required String hint,
    required String? value,
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
          hint: Text(
            _loadingBanks ? 'Loading banks...' : hint,
            style: TextStyle(
                color: Colors.white.withOpacity(0.65), fontSize: 15),
          ),
          icon: const Icon(Icons.arrow_drop_down_rounded,
              color: Colors.white70),
          dropdownColor: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(16),
          style: const TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
          items: _banks
              .map((bank) => DropdownMenuItem(
            value: bank['code'],
            child: Text(
              bank['name']!,
              overflow: TextOverflow.ellipsis,
            ),
          ))
              .toList(),
          onChanged: _loadingBanks ? null : onChanged,
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
            onTap: _isLoading ? null : onNext,
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
              child: _isLoading && isLastStep
                  ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                ),
              )
                  : Text(
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