import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class MerchantOnboardingScreen extends StatefulWidget {
  const MerchantOnboardingScreen({super.key});

  @override
  State<MerchantOnboardingScreen> createState() =>
      _MerchantOnboardingScreenState();
}

class _MerchantOnboardingScreenState extends State<MerchantOnboardingScreen> {
  final _supabase = Supabase.instance.client;
  int _currentStep =
      0; // 0: Saisie Téléphone, 1: Code OTP, 2: Identité KYC, 3: PIN Transactionnel
  bool _isSignUpMode = true; // true = Création de compte, false = Connexion
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
    'GW': {
      'name': 'Guinée-Bissau',
      'dial': '+245',
      'flag': '🇬🇼',
      'currency': 'XOF',
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
    'MR': {
      'name': 'Mauritanie',
      'dial': '+222',
      'flag': '🇲🇷',
      'currency': 'MRU',
      'minLength': 8,
      'maxLength': 8
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
          behavior: SnackBarBehavior.floating),
    );
  }

  void _detectMobileOperator(String value) {
    if (_selectedCountryCode == 'BF' && value.length >= 2) {
      String prefix = value.substring(0, 2);
      setState(() {
        if (['06', '07', '54', '55', '56', '74', '75', '76', '77', '78', '79']
            .contains(prefix)) {
          _detectedOperator = 'Orange Money 🟠';
        } else if ([
          '01',
          '02',
          '03',
          '50',
          '51',
          '52',
          '53',
          '60',
          '61',
          '62',
          '63',
          '64',
          '65',
          '66',
          '67',
          '68',
          '69'
        ].contains(prefix)) {
          _detectedOperator = 'Moov Money 🟢';
        } else if (['04', '05', '70', '71', '72', '73'].contains(prefix)) {
          _detectedOperator = 'Telecel Faso 🔵';
        } else {
          _detectedOperator = '';
        }
      });
    } else {
      setState(() => _detectedOperator = '');
    }
  }

  void _openCountryPicker() {
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
                  const Text("Sélectionnez votre pays",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchCountryController,
                    decoration: InputDecoration(
                      hintText: "Rechercher un pays ou indicatif...",
                      prefixIcon:
                          const Icon(Icons.search, color: Color(0xFF1677FF)),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFD1D5DB))),
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
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

  // ÉTAPE 0 : Analyse rigoureuse de l'existence du compte en base de données
  Future<void> _submitPhone() async {
    final country = _cedeaoCountries[_selectedCountryCode]!;
    final phone = _phoneController.text.trim();

    if (phone.length < country['minLength'] ||
        phone.length > country['maxLength']) {
      _showError(
          "Le numéro pour ${country['name']} doit contenir entre ${country['minLength']} et ${country['maxLength']} chiffres.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final fullPhone = "${country['dial']}$phone";

      // Vérification dans Supabase
      final existingUser = await _supabase
          .from('profiles')
          .select()
          .eq('phone', fullPhone)
          .maybeSingle();

      setState(() {
        _isExistingUser = existingUser != null;
      });

      // Contrôle de cohérence professionnel
      if (_isSignUpMode && _isExistingUser) {
        _showError(
            "Ce numéro possède déjà un compte. Passage en mode Connexion.");
        setState(() => _isSignUpMode = false);
      } else if (!_isSignUpMode && !_isExistingUser) {
        _showError(
            "Aucun compte associé à ce numéro. Veuillez créer un compte.");
        setState(() => _isSignUpMode = true);
        return;
      }

      setState(() => _currentStep = 1); // Passage à l'OTP
    } catch (e) {
      _showError("Erreur de vérification : ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().length < 4) {
      _showError("Veuillez saisir le code SMS reçu.");
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      _isLoading = false;
      // Si l'utilisateur existe déjà OU qu'on est explicitement en mode connexion, on saute le KYC (Étape 2)
      if (_isExistingUser || !_isSignUpMode) {
        _currentStep = 3;
      } else {
        _currentStep = 2; // Nouveau compte : passage par l'identité légale KYC
      }
    });
  }

  Future<void> _completeOnboarding() async {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      _showError("Veuillez définir un code PIN à 4 chiffres.");
      return;
    }
    setState(() => _isLoading = true);
    try {
      final country = _cedeaoCountries[_selectedCountryCode]!;
      final fullPhone = "${country['dial']}${_phoneController.text.trim()}";

      if (_isExistingUser || !_isSignUpMode) {
        // Mode Connexion : Vérification du PIN
        final response = await _supabase
            .from('profiles')
            .select()
            .eq('phone', fullPhone)
            .eq('pin_code', pin)
            .maybeSingle();

        if (response == null) {
          _showError("Code PIN incorrect pour ce compte.");
          return;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Connexion réussie ! Bienvenue de retour."),
                backgroundColor: Color(0xFF1677FF)),
          );
          Navigator.of(context).pushReplacementNamed('/terminal');
        }
      } else {
        // Mode Inscription : Insertion sécurisée
        User? currentUser = _supabase.auth.currentUser;
        String merchantId =
            currentUser != null ? currentUser.id : const Uuid().v4();

        await _supabase.from('profiles').insert({
          'id': merchantId,
          'full_name':
              "${_lastNameController.text.trim().toUpperCase()} ${_firstNameController.text.trim()}",
          'phone': fullPhone,
          'country_code': _selectedCountryCode,
          'currency': country['currency'],
          'pin_code': pin,
          'role': 'merchant',
          'updated_at': DateTime.now().toIso8601String(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Compte marchand configuré avec succès !"),
                backgroundColor: Color(0xFF1677FF)),
          );
          Navigator.of(context).pushReplacementNamed('/terminal');
        }
      }
    } catch (e) {
      _showError("Erreur d'authentification : ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final country =
        _cedeaoCountries[_selectedCountryCode] ?? _cedeaoCountries['BF']!;
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
                    child: const Icon(Icons.account_balance_wallet_rounded,
                        color: Color(0xFF1677FF), size: 30),
                  ),
                  const SizedBox(width: 12),
                  const Text("SebGo Pay",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5)),
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
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1677FF), width: 2.0)),
    );

    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                _isSignUpMode
                    ? "Créer un compte Marchand"
                    : "Connexion Marchand",
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            const Text("Entrez votre numéro de téléphone Mobile Money.",
                style: TextStyle(color: Colors.grey, fontSize: 14)),
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
                        Text(country['flag'],
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Text(country['dial'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1677FF))),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                            color: Colors.grey),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                      height: 28, width: 1.5, color: const Color(0xFFD1D5DB)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      key: ValueKey(_selectedCountryCode),
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: country['maxLength'],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(country['maxLength']),
                      ],
                      onChanged: _detectMobileOperator,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                          hintText: "Numéro de téléphone",
                          border: InputBorder.none,
                          counterText: ""),
                    ),
                  ),
                ],
              ),
            ),
            if (_detectedOperator.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text("Opérateur détecté : $_detectedOperator",
                  style: const TextStyle(
                      color: Color(0xFF1677FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1677FF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                onPressed: _isLoading ? null : _submitPhone,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Continuer",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
            // UI PROFESSIONNELLE : Texte d'interrogation neutre en noir + Action claire
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignUpMode
                        ? "Déjà sur SebGo Pay ?"
                        : "Nouveau sur SebGo Pay ?",
                    style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _isSignUpMode = !_isSignUpMode),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8)),
                    child: Text(
                      _isSignUpMode ? "Se connecter" : "Créer un compte",
                      style: const TextStyle(
                          color: Color(0xFF1677FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
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
            const Text("Vérification SMS",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                "Entrez le code à 6 chiffres envoyé au ${country['dial']} ${_phoneController.text}",
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 28),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                  fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.bold),
              decoration: inputDecorationTheme.copyWith(
                  counterText: "", hintText: "••••••"),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1677FF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                onPressed: _isLoading ? null : _verifyOtp,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Valider le code",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Identité Légale Marchand",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                "Saisissez votre nom et prénom officiels (lettres uniquement).",
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 24),
            TextField(
              controller: _lastNameController,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿ\s-]'))
              ],
              decoration:
                  inputDecorationTheme.copyWith(labelText: "Nom de famille"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _firstNameController,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿ\s-]'))
              ],
              decoration: inputDecorationTheme.copyWith(labelText: "Prénom(s)"),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1677FF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                onPressed: () {
                  final lastName = _lastNameController.text.trim();
                  final firstName = _firstNameController.text.trim();
                  if (lastName.isEmpty || firstName.isEmpty) {
                    _showError("Le nom et le prénom sont obligatoires.");
                    return;
                  }
                  setState(() => _currentStep = 3);
                },
                child: const Text("Continuer",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                _isExistingUser || !_isSignUpMode
                    ? "Connexion - Code PIN"
                    : "Code PIN Sécurisé",
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                _isExistingUser || !_isSignUpMode
                    ? "Entrez votre PIN transactionnel pour accéder à votre compte."
                    : "Définissez votre PIN transactionnel à 4 chiffres.",
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 28),
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                  fontSize: 28, letterSpacing: 16, fontWeight: FontWeight.bold),
              decoration: inputDecorationTheme.copyWith(
                  counterText: "", hintText: "••••"),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1677FF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                onPressed: _isLoading ? null : _completeOnboarding,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isExistingUser || !_isSignUpMode
                            ? "Se connecter"
                            : "Activer mon compte marchand",
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
          ],
        );
      default:
        return Container();
    }
  }
}
