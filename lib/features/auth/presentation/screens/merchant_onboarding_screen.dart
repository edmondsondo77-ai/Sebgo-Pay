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

  int _currentStep = 0; // 0: Téléphone, 1: OTP, 2: Identité Civile, 3: Code PIN
  bool _isLoading = false;

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _pinController = TextEditingController();

  String _selectedCountryCode = 'BF'; // Burkina Faso par défaut

  // 🌍 COUVERTURE COMPLÈTE ET EXHAUSTIVE DES 16 PAYS DE LA CEDEAO
  final Map<String, Map<String, dynamic>> _cedeaoCountries = {
    'BF': {
      'name': 'Burkina Faso',
      'dial': '+226',
      'currency': 'XOF',
      'minLength': 8,
      'maxLength': 8
    },
    'CI': {
      'name': "Côte d'Ivoire",
      'dial': '+225',
      'currency': 'XOF',
      'minLength': 10,
      'maxLength': 10
    },
    'SN': {
      'name': 'Sénégal',
      'dial': '+221',
      'currency': 'XOF',
      'minLength': 9,
      'maxLength': 9
    },
    'ML': {
      'name': 'Mali',
      'dial': '+223',
      'currency': 'XOF',
      'minLength': 8,
      'maxLength': 8
    },
    'BJ': {
      'name': 'Bénin',
      'dial': '+229',
      'currency': 'XOF',
      'minLength': 8,
      'maxLength': 8
    },
    'TG': {
      'name': 'Togo',
      'dial': '+228',
      'currency': 'XOF',
      'minLength': 8,
      'maxLength': 8
    },
    'NE': {
      'name': 'Niger',
      'dial': '+227',
      'currency': 'XOF',
      'minLength': 8,
      'maxLength': 8
    },
    'GH': {
      'name': 'Ghana',
      'dial': '+233',
      'currency': 'GHS',
      'minLength': 9,
      'maxLength': 9
    },
    'NG': {
      'name': 'Nigeria',
      'dial': '+234',
      'currency': 'NGN',
      'minLength': 10,
      'maxLength': 10
    },
    'GN': {
      'name': 'Guinée',
      'dial': '+224',
      'currency': 'GNF',
      'minLength': 9,
      'maxLength': 9
    },
    'GM': {
      'name': 'Gambie',
      'dial': '+220',
      'currency': 'GMD',
      'minLength': 7,
      'maxLength': 7
    },
    'GW': {
      'name': 'Guinée-Bissau',
      'dial': '+245',
      'currency': 'XOF',
      'minLength': 7,
      'maxLength': 7
    },
    'LR': {
      'name': 'Libéria',
      'dial': '+231',
      'currency': 'LRD',
      'minLength': 7,
      'maxLength': 8
    },
    'SL': {
      'name': 'Sierra Leone',
      'dial': '+232',
      'currency': 'SLL',
      'minLength': 8,
      'maxLength': 8
    },
    'CV': {
      'name': 'Cap-Vert',
      'dial': '+238',
      'currency': 'CVE',
      'minLength': 7,
      'maxLength': 7
    },
    'MR': {
      'name': 'Mauritanie',
      'dial': '+222',
      'currency': 'XOF',
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
    super.dispose();
  }

  // ÉTAPE 1 : Validation rigoureuse du numéro selon le routage du pays choisi
  Future<void> _requestOtp() async {
    final phone = _phoneController.text.trim();
    final countryInfo = _cedeaoCountries[_selectedCountryCode]!;
    final int minLen = countryInfo['minLength'];
    final int maxLen = countryInfo['maxLength'];

    if (phone.isEmpty || phone.length < minLen || phone.length > maxLen) {
      _showError(
          "Numéro invalide pour ${countryInfo['name']} (attendu : $minLen à $maxLen chiffres).");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Future.delayed(
          const Duration(seconds: 1)); // Simulation d'envoi SMS OTP
      setState(() => _currentStep = 1);
    } catch (e) {
      _showError("Erreur lors de l'envoi du code SMS.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      _showError("Veuillez entrer le code de validation reçu par SMS.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _currentStep = 2);
    } catch (e) {
      _showError("Code OTP incorrect ou expiré.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeRegistration() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final pin = _pinController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      _showError(
          "Le nom et le prénom sont obligatoires pour la conformité Mobile Money.");
      return;
    }
    if (pin.length < 4) {
      _showError(
          "Veuillez définir un code PIN transactionnel sécurisé à 4 ou 6 chiffres.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      final countryInfo = _cedeaoCountries[_selectedCountryCode]!;
      final fullPhoneNumber =
          "${countryInfo['dial']}${_phoneController.text.trim()}";

      if (user != null) {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'full_name': '$lastName $firstName',
          'phone': fullPhoneNumber,
          'country_code': _selectedCountryCode,
          'currency': countryInfo['currency'],
          'role': 'merchant',
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Compte marchand configuré avec succès !"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      _showError("Erreur lors de l'enregistrement du profil.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final countryInfo = _cedeaoCountries[_selectedCountryCode]!;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.security_rounded,
                          size: 48, color: Color(0xFF0D6EFD)),
                      const SizedBox(height: 16),
                      Text(
                        _getStepTitle(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A202C)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getStepSubtitle(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF718096)),
                      ),
                      const SizedBox(height: 24),

                      // CONTENU DES ÉTAPES AVEC FILTRAGE STRICT DES ENTRÉES
                      if (_currentStep == 0) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedCountryCode,
                          decoration: InputDecoration(
                            labelText: "Pays de résidence (16 Pays - CEDEAO)",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          items: _cedeaoCountries.entries.map((e) {
                            return DropdownMenuItem(
                                value: e.key,
                                child: Text(
                                    "${e.value['name']} (${e.value['dial']})"));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCountryCode = val;
                                _phoneController
                                    .clear(); // Réinitialise pour éviter les conflits de format
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          // 🔒 FILTRE STRICT : Uniquement des chiffres acceptés (Zéro lettre)
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            labelText: "Numéro de téléphone",
                            prefixIcon: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              child: Text(
                                countryInfo['dial'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF0D6EFD)),
                              ),
                            ),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D6EFD),
                                foregroundColor: Colors.white),
                            onPressed: _isLoading ? null : _requestOtp,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text("Recevoir le code SMS"),
                          ),
                        ),
                      ] else if (_currentStep == 1) ...[
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          // 🔒 FILTRE STRICT : Chiffres uniquement
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: const TextStyle(
                              fontSize: 24,
                              letterSpacing: 8,
                              fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            counterText: "",
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D6EFD),
                                foregroundColor: Colors.white),
                            onPressed: _isLoading ? null : _verifyOtp,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text("Valider le code"),
                          ),
                        ),
                      ] else if (_currentStep == 2) ...[
                        TextField(
                          controller: _lastNameController,
                          // 🔒 FILTRE STRICT : Uniquement des lettres et espaces (Zéro chiffre autorisé dans le nom)
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-ZÀ-ÿ\s]'))
                          ],
                          decoration: InputDecoration(
                            labelText: "Nom de famille (Légal)",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _firstNameController,
                          // 🔒 FILTRE STRICT : Uniquement des lettres et espaces
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-ZÀ-ÿ\s]'))
                          ],
                          decoration: InputDecoration(
                            labelText: "Prénom(s) (Légal)",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D6EFD),
                                foregroundColor: Colors.white),
                            onPressed: () => setState(() => _currentStep = 3),
                            child: const Text("Continuer"),
                          ),
                        ),
                      ] else if (_currentStep == 3) ...[
                        TextField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          // 🔒 FILTRE STRICT : Chiffres uniquement
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style:
                              const TextStyle(fontSize: 22, letterSpacing: 12),
                          decoration: InputDecoration(
                            labelText: "Code PIN (4-6 chiffres)",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            counterText: "",
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white),
                            onPressed:
                                _isLoading ? null : _completeRegistration,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text("Activer mon compte marchand"),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return "Connexion Mobile Money";
      case 1:
        return "Vérification par SMS";
      case 2:
        return "Identité Légale (KYC)";
      case 3:
        return "Code PIN Transactionnel";
      default:
        return "Onboarding SebGo Pay";
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return "Entrez le numéro lié à votre opérateur national";
      case 1:
        return "Entrez le code à 6 chiffres reçu par SMS";
      case 2:
        return "Conforme aux exigences des transferts UEMOA/BCEAO";
      case 3:
        return "Nécessaire pour valider vos encaissements";
      default:
        return "";
    }
  }
}
