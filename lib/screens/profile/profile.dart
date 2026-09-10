import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name         = '';
  String _cds          = '';
  String _email        = '';
  String _phone        = '';
  String _brokerName   = '';
  String _broker       = '';
  String _pin          = '';
  String _hasCompany   = '';
  String _accountType  = '';

  // ── Live client details (from getAllDetails) ────────────────────────────
  String? _cashBank;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final cds   = prefs.getString('user_cds')  ?? '-';
    final token = prefs.getString('user_token') ?? '';
    setState(() {
      _name        = prefs.getString('user_name')         ?? '-';
      _cds         = cds;
      _email       = prefs.getString('user_email')        ?? '-';
      _phone       = prefs.getString('user_phone')        ?? '-';
      _brokerName  = prefs.getString('user_brokerName')   ?? '-';
      _broker      = prefs.getString('user_broker')       ?? 'NONE';
      _pin         = prefs.getString('user_pin')          ?? '-';
      _hasCompany  = prefs.getString('user_has_company')  ?? '-';
      _accountType = prefs.getString('user_account_type') ?? '-';
    });
    await _fetchClientDetails(cds, token);
  }

  // ── Client details (name, mobile, bank) straight from ctrade ───────────
  Future<void> _fetchClientDetails(String cds, String token) async {
    if (cds.isEmpty || cds == '-') return;
    setState(() => _isLoadingDetails = true);
    try {
      final uri = Uri.parse(
        'https://myapi.zmx.co.zw/api/legacy/ctrade/getAllDetails'
            '?cdsNumber=$cds',
      );
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final details = Map<String, dynamic>.from(data[0]);
          final forenames = details['Forenames']?.toString() ?? '';
          final surname   = details['Surname']?.toString()   ?? '';
          final fullName  = '$forenames $surname'.trim();
          setState(() {
            if (fullName.isNotEmpty) _name = fullName;
            _cds      = details['CDS_Number']?.toString() ?? _cds;
            _phone    = details['Mobile']?.toString()     ?? _phone;
            _cashBank = details['Cash_Bank']?.toString();
          });
        }
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFAF6EE), Color(0xFFEDE4D0)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 24),
                      _buildBasicInfoCard(),
                      const SizedBox(height: 16),
                      _buildAccountInfoCard(),
                      const SizedBox(height: 16),
                      _buildBankingInfoCard(),
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

  // ── Top Bar ───────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF1A1A1A), size: 18),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'My Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  // ── Profile Header ────────────────────────────────────────────────────
  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD4A017), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    color: const Color(0xFF2DB144).withOpacity(0.15),
                    child: const Icon(Icons.person_rounded,
                        color: Color(0xFF2DB144), size: 48),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4A017),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4A017).withOpacity(0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.edit_rounded,
                      color: Colors.white, size: 13),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Dynamic name ──────────────────────────────────
              Text(
                _name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              // ── Dynamic CDS ───────────────────────────────────
              Text(
                _cds,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              // ── Account type badge ────────────────────────────
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2DB144).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _accountType == 'i' ? 'Individual Account' : 'Corporate Account',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF2DB144),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Basic Information ─────────────────────────────────────────────────
  Widget _buildBasicInfoCard() {
    return _infoCard(
      title: 'Basic Information',
      children: [
        _infoRow('Email',  _email),
        _infoRow('Mobile', _phone),
        _infoRow('CDS No', _cds),
      ],
    );
  }

  // ── Account Information ───────────────────────────────────────────────
  Widget _buildAccountInfoCard() {
    return _infoCard(
      title: 'Account Information',
      children: [
        _infoRow('Broker Name',   _brokerName.isNotEmpty ? _brokerName : 'NONE'),
        _infoRow('Broker',        _broker.isNotEmpty     ? _broker     : 'NONE'),
        _infoRow('Account Type',  _accountType == 'i' ? 'Individual' : 'Corporate'),
        _infoRow('Has Company',   _hasCompany == 'true' ? 'Yes' : 'No'),
        _infoRow('Trading PIN',   _pin.replaceAll(RegExp(r'.'), '•')), // masked
      ],
    );
  }

  // ── Banking Information ───────────────────────────────────────────────
  Widget _buildBankingInfoCard() {
    return _infoCard(
      title: 'Banking Information',
      children: [
        _infoRow(
          'Cash Bank',
          _isLoadingDetails
              ? '…'
              : (_cashBank?.isNotEmpty == true ? _cashBank! : '—'),
        ),
      ],
    );
  }

  // ── Reusable card shell ───────────────────────────────────────────────
  Widget _infoCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4A017),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4A017).withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.edit_rounded,
                      color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Divider(
                color: const Color(0xFFD4A017).withOpacity(0.4),
                height: 20,
                thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

}