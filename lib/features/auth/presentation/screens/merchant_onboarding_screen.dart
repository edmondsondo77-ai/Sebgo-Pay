 import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MerchantOnboardingScreen extends StatefulWidget {
  const MerchantOnboardingScreen({super.key});

  @override
  State<MerchantOnboardingScreen> createState() =>
      _MerchantOnboardingScreenState();
}

class _MerchantOnboardingScreenState extends State<MerchantOnboardingScreen> {
  final _supabase = Supabase.instance.client;
  int _currentStep = 0; // 0: Téléphone, 1: OTP, 2: KYC (si nouveau), 3: PIN
  bool _isSignUpMode = true;
  bool _isLoading = false;
  bool _isExistingUser = false;

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _pinController = TextEditingController();
  final _searchCountryController = TextEditingController();

  String _selectedCountryCode = 'BF';
  String _searchQuery = '';
  String _detectedOperator = '';

  // 🌍 Liste exhaustive des 15 pays membres de la CEDEAO (Afrique de l'Ouest)
  final Map<String, Map<String, dynamic>> _cedeaoCountries = {
    'BF': {
      'name': 'Burkina Faso',
      'dial': '+226',
      'flag': '🇧🇫',
      'currency': 'XOF',
      'minLength': 8,
      'maxLength': 8
    },
    'CI': {
      'name': "Côte d'Ivoire",
      'dial': '+225',
      'flag': '🇨🇮',
      'currency': 'XOF',
      'minLength': 10,
      'maxLength': 10
    },
    'SN': {
      'name': 'Sénégal',
      'dial': '+221',
      'flag': '🇸🇳',
      'currency': 'XOF',
      'minLength': 9,
      'maxLength': 9
    },
    'ML': {
      'name': 'Mali',
      'dial': '+223',
      'flag': '🇲🇱',
      'currency': 'XOF',
      'minLength': 8,
      'maxLength': 8
    },
    'BJ': {
      'name': 'Bénin',
      'dial': '+229',
      'flag': '🇧🇯',
      'currency': 'XOF',
      'minLength': 8,
      'maxLength': 8
    },
    'TG': {
      'name': 'Togo',
      'dial': '+228',
      'flag': '🇹🇬',
      'currency': 'XOF',
      'minLength': 8,
      'maxLength': 8
    },
    'NE': {
      'name': 'Niger',
      'dial': '+227',
      'flag': '🇳🇪',
      'currency': 'XOF',
      'minLength': 8,
      'maxLength': 8
    },
    'GW': {
      'name': 'Guinée-Bissau',
      'dial': '+245',
      'flag': '🇬🇼',
      'currency': 'XOF',
      'minLength': 7,
      'maxLength': 7
    },
    'GH': {
      'name': 'Ghana',
      'dial': '+233',
      'flag': '🇬🇭',
      'currency': 'GHS',
      'minLength': 9,
      'maxLength': 9
    },
    'NG': {
      'name': 'Nigeria',
      'dial': '+234',
      'flag': '🇳🇬',
      'currency': 'NGN',
      'minLength': 10,
      'maxLength': 10
    },
    'GN': {
      'name': 'Guinée',
      'dial': '+224',
      'flag': '🇬🇳',
      'currency': 'GNF',
      'minLength': 9,
      'maxLength': 9
    },
    'GM': {
      'name': 'Gambie',
      'dial': '+220',
      'flag': '🇬🇲',
      'currency': 'GMD',
      'minLength': 7,
      'maxLength': 7
    },
    'LR': {
      'name': 'Libéria',
      'dial': '+231',
      'flag': '🇱🇷',
      'currency': 'LRD',
      'minLength': 7,
      'maxLength': 8
    },
    'SL': {
      'name': 'Sierra Leone',
      'dial': '+232',
      'flag': '🇸🇱',
      'currency': 'SLL',
      'minLength': 8,
      'maxLength': 8
    },
    'CV': {
      'name': 'Cap-Vert',
      'dial': '+238',
      'flag': '🇨🇻',
      'currency': 'CVE',
      'minLength': 7,
      'maxLength': 7
    },
  };

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _pinController.dispose();
    _searchCountryController.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _detectMobileOperator(String value) {
    if (_selectedCountryCode == 'BF' && value.length >= 2) {
      String prefix = value.substring(0, 2);
      setState(() {
        if (['06', '07', '54', '55', '56', '74', '75', '76', '77', '78', '79'].contains(prefix)) {
          _detectedOperator = 'Orange Money🟠';
        } else if (['01', '02', '03', '50', '51', '52', '53', '60', '61', '62', '63', '64', '65', '66', '67', '68', '69'].contains(prefix)) {
          _detectedOperator = 'Moov Money🟢';
        } else if (['04', '05', '70', '71', '72', '73'].contains(prefix)) {
          _detectedOperator = 'Telecel Faso🔵';
        } else {
          _detectedOperator = '';
        }
      });
    } else {
      setState(() => _detectedOperator = '');
    }
  }

  void _openCountryPicker() {
    _searchQuery = '';
    _searchCountryController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredCountries = _cedeaoCountries.entries.where((e) {
              final name = e.value['name'].toString().toLowerCase();
              final dial = e.value['dial'].toString().toLowerCase();
              return name.contains(_searchQuery.toLowerCase()) ||
                  dial.contains(_searchQuery.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  const Text("Sélectionnez votre pays (CEDEAO)",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchCountryController,
                    decoration: InputDecoration(
                      hintText: "Rechercher un pays ou indicatif...",
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF1677FF)),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF1677FF), width: 2)),
                    ),
                    onChanged: (val) => setModalState(() => _searchQuery = val),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredCountries.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entry = filteredCountries[index];
                        final data = entry.value;
                        return ListTile(
                          leading: Text(data['flag'],
                              style: const TextStyle(fontSize: 28)),
                          title: Text(data['name'],
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          trailing: Text(data['dial'],
                              style: const TextStyle(
                                  color: Color(0xFF1677FF),
                                  fontWeight: FontWeight.bold)),
                          onTap: () {
                            setState(() {
                              _selectedCountryCode = entry.key;
                              _phoneController.clear();
                              _detectedOperator = '';
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// ÉTAPE 0 : Envoi réel du code OTP via Supabase Auth
  Future<void> _submitPhone() async {
    final country = _cedeaoCountries[_selectedCountryCode]!;
    final phone = _phoneController.text.trim();
    if (phone.length < country['minLength'] || phone.length > country['maxLength']) {
      _showError("Numéro invalide pour ${country['name']} (entre ${country['minLength']} et ${country['maxLength']} chiffres).");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final fullPhone = "${country['dial']}$phone";

      final existingUser = await _supabase
          .from('profiles')
          .select()
          .eq('phone', fullPhone)
          .maybeSingle();

      _isExistingUser = existingUser != null;

      if (_isSignUpMode && _isExistingUser) {
        _showError("Ce numéro possède déjà un compte. Passage en mode Connexion.");
        _isSignUpMode = false;
      } else if (!_isSignUpMode && !_isExistingUser) {
        _showError("Aucun compte associé à ce numéro. Veuillez créer un compte.");
        _isSignUpMode = true;
        return;
      }

      await _supabase.auth.signInWithOtp(
        phone: fullPhone,
      );

      setState(() => _currentStep = 1);
    } catch (e) {
      _showError("Erreur d'envoi OTP : ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ÉTAPE 1 : Validation cryptographique de l'OTP par Supabase
  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      _showError("Veuillez saisir le code SMS à 6 chiffres.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final country = _cedeaoCountries[_selectedCountryCode]!;
      final fullPhone = "${country['dial']}${_phoneController.text.trim()}";

      final AuthResponse res = await _supabase.auth.verifyOTP(
        type: OtpType.sms,
        token: otp,
        phone: fullPhone,
      );

      if (res.session == null) {
        _showError("Code OTP incorrect ou expiré.");
        return;
      }

      setState(() {
        if (_isExistingUser || !_isSignUpMode) {
          _currentStep = 3;
        } else {
          _currentStep = 2;
        }
      });
    } catch (e) {
      _showError("Code OTP invalide ou expiré.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ÉTAPE FINALISATION : Enregistrement du Profil lié au VRAI user.id (auth.uid())
  Future<void> _completeOnboarding() async {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      _showError("Veuillez définir un code PIN à 4 chiffres.");
      return;
    }

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      _showError("Session expirée. Veuillez réessayer la validation SMS.");
      setState(() => _currentStep = 0);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final country = _cedeaoCountries[_selectedCountryCode]!;
      final fullPhone = "${country['dial']}${_phoneController.text.trim()}";

      if (_isExistingUser || !_isSignUpMode) {
        final response = await _supabase
            .from('profiles')
            .select()
            .eq('id', currentUser.id)
            .eq('pin_code', pin)
            .maybeSingle();

        if (response == null) {
          _showError("Code PIN incorrect.");
          return;
        }
      } else {
        await _supabase.from('profiles').upsert({
          'id': currentUser.id,
          'full_name': "${_lastNameController.text.trim().toUpperCase()} ${_firstNameController.text.trim()}",
          'phone': fullPhone,
          'country_code': _selectedCountryCode,
          'currency': country['currency'],
          'pin_code': pin,
          'role': 'merchant',
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/terminal', (route) => false);
      }
    } catch (e) {
      _showError("Erreur d'enregistrement : ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final country = _cedeaoCountries[_selectedCountryCode] ?? _cedeaoCountries['BF']!;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                onPressed: () => setState(() => _currentStep--),
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1677FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF1677FF), size: 30),
                  ),
                  const SizedBox(width: 12),
                  const Text("SebGo Pay", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildStepContent(country),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(Map<String, dynamic> country) {
    final inputDecorationTheme = InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1677FF), width: 2.0)),
    );

    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isSignUpMode ? "Créer un compte Marchand" : "Connexion Marchand", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            const Text("Entrez votre numéro de téléphone Mobile Money.", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: _openCountryPicker,
                    child: Row(
                      children: [
                        Text(country['flag'], style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Text(country['dial'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1677FF))),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(height: 28, width: 1.5, color: const Color(0xFFD1D5DB)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: country['maxLength'],
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: _detectMobileOperator,
                      decoration: const InputDecoration(hintText: "Numéro de téléphone", border: InputBorder.none, counterText: ""),
                    ),
                  ),
                ],
              ),
            ),
            if (_detectedOperator.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text("Opérateur détecté : $_detectedOperator", style: const TextStyle(color: Color(0xFF1677FF), fontWeight: FontWeight.bold, fontSize: 13)),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1677FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: _isLoading ? null : _submitPhone,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Envoyer le code SMS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isSignUpMode ? "Déjà sur SebGo Pay ?" : "Nouveau sur SebGo Pay ?", style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500)),
                  TextButton(
                    onPressed: () => setState(() => _isSignUpMode = !_isSignUpMode),
                    child: Text(_isSignUpMode ? "Se connecter" : "Créer un compte", style: const TextStyle(color: Color(0xFF1677FF), fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            ),
          ],
        );

      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Vérification SMS", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Entrez le code à 6 chiffres envoyé par SMS au ${country['dial']} ${_phoneController.text}", style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 28),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.bold),
              decoration: inputDecorationTheme.copyWith(counterText: "", hintText: "••••••"),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1677FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: _isLoading ? null : _verifyOtp,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Valider le code OTP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Identité Légale Marchand", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Saisissez votre nom et prénom officiels.", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 24),
            TextField(controller: _lastNameController, decoration: inputDecorationTheme.copyWith(labelText: "Nom de famille")),
            const SizedBox(height: 16),
            TextField(controller: _firstNameController, decoration: inputDecorationTheme.copyWith(labelText: "Prénom(s)")),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1677FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () {
                  if (_lastNameController.text.trim().isEmpty || _firstNameController.text.trim().isEmpty) {
                    _showError("Le nom et le prénom sont obligatoires.");
                    return;
                  }
                  setState(() => _currentStep = 3);
                },
                child: const Text("Continuer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        );

      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isExistingUser || !_isSignUpMode ? "Connexion - Code PIN" : "Code PIN Sécurisé", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Saisissez votre code PIN transactionnel à 4 chiffres.", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 28),
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 28, letterSpacing: 16, fontWeight: FontWeight.bold),
              decoration: inputDecorationTheme.copyWith(counterText: "", hintText: "••••"),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1677FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: _isLoading ? null : _completeOnboarding,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isExistingUser || !_isSignUpMode ? "Se connecter" : "Activer mon compte", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}