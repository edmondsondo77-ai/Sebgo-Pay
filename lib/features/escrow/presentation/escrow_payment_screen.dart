import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Suppression stricte et définitive de la barre de défilement en Flutter Web Desktop
class NoScrollbarBehavior extends MaterialScrollBehavior {
  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class EscrowPaymentScreen extends StatefulWidget {
  final String paymentToken;
  const EscrowPaymentScreen({super.key, required this.paymentToken});

  @override
  State<EscrowPaymentScreen> createState() => _EscrowPaymentScreenState();
}

class _EscrowPaymentScreenState extends State<EscrowPaymentScreen> {
  final _supabase = Supabase.instance.client;
  final _phoneController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _escrowDetails;

  // Configuration Pays et Devise (CEDEAO - 16 Pays)
  String _selectedCountryCode = 'BF';
  String _selectedCurrency = 'XOF';
  double _exchangeRate = 1.0;

  // Méthode de paiement sélectionnée
  String _selectedPaymentMethod = 'SOLDE_SEBGO';
  bool _isProcessingPayment = false;

  // Gestion d'état de succès inline
  bool _isPaymentSuccess = false;
  Map<String, dynamic>? _lastTransactionSummary;

  // 🌍 COUVERTURE COMPLÈTE DES 16 PAYS DE LA CEDEAO ET LEURS OPÉRATEURS
  final Map<String, Map<String, dynamic>> _regionalProviders = {
    'BF': {
      'name': 'Burkina Faso 🇧🇫',
      'currency': 'XOF',
      'rateToXOF': 1.0,
      'methods': [
        {
          'id': 'SOLDE_SEBGO',
          'name': 'Solde SebGo Pay',
          'subtitle': 'Paiement instantané (Sans frais)',
          'icon': Icons.account_balance_wallet_rounded,
          'color': const Color(0xFF0D6EFD)
        },
        {
          'id': 'ORANGE_BF',
          'name': 'Orange Money BF',
          'subtitle': 'Validation Push (*144#)',
          'icon': Icons.phone_android_rounded,
          'color': const Color(0xFFFF6600)
        },
        {
          'id': 'MOOV_BF',
          'name': 'Moov Money BF',
          'subtitle': 'Moov Africa (*555#)',
          'icon': Icons.phonelink_ring_rounded,
          'color': const Color(0xFF0055A5)
        },
        {
          'id': 'TELECEL_BF',
          'name': 'Telecel Cash BF',
          'subtitle': 'Telecel Faso (*777#)',
          'icon': Icons.cell_tower_rounded,
          'color': const Color(0xFFE60000)
        },
        {
          'id': 'WAVE_BF',
          'name': 'Wave Burkina',
          'subtitle': 'QR Code / Wave App',
          'icon': Icons.waves_rounded,
          'color': const Color(0xFF1DC3F7)
        },
        {
          'id': 'CARD_BF',
          'name': 'Carte Bancaire',
          'subtitle': 'Visa / Mastercard',
          'icon': Icons.credit_card_rounded,
          'color': const Color(0xFF1A1F71)
        },
      ],
    },
    'CI': {
      'name': "Côte d'Ivoire 🇨🇮",
      'currency': 'XOF',
      'rateToXOF': 1.0,
      'methods': [
        {
          'id': 'SOLDE_SEBGO',
          'name': 'Solde SebGo Pay',
          'subtitle': 'Paiement instantané',
          'icon': Icons.account_balance_wallet_rounded,
          'color': const Color(0xFF0D6EFD)
        },
        {
          'id': 'ORANGE_CI',
          'name': 'Orange Money CI',
          'subtitle': '#144# Orange Money',
          'icon': Icons.phone_android_rounded,
          'color': const Color(0xFFFF6600)
        },
        {
          'id': 'MTN_CI',
          'name': 'MTN MoMo CI',
          'subtitle': '*133# Mobile Money',
          'icon': Icons.bolt_rounded,
          'color': const Color(0xFFFFCC00)
        },
        {
          'id': 'WAVE_CI',
          'name': "Wave Côte d'Ivoire",
          'subtitle': 'Paiement rapide',
          'icon': Icons.waves_rounded,
          'color': const Color(0xFF1DC3F7)
        },
        {
          'id': 'MOOV_CI',
          'name': 'Moov Money CI',
          'subtitle': 'Moov Africa CI',
          'icon': Icons.phonelink_ring_rounded,
          'color': const Color(0xFF0055A5)
        },
        {
          'id': 'CARD_CI',
          'name': 'Carte Bancaire',
          'subtitle': 'Visa / Mastercard',
          'icon': Icons.credit_card_rounded,
          'color': const Color(0xFF1A1F71)
        },
      ],
    },
    'SN': {
      'name': 'Sénégal 🇸🇳',
      'currency': 'XOF',
      'rateToXOF': 1.0,
      'methods': [
        {
          'id': 'SOLDE_SEBGO',
          'name': 'Solde SebGo Pay',
          'subtitle': 'Paiement instantané',
          'icon': Icons.account_balance_wallet_rounded,
          'color': const Color(0xFF0D6EFD)
        },
        {
          'id': 'ORANGE_SN',
          'name': 'Orange Money Sénégal',
          'subtitle': '#144# OM',
          'icon': Icons.phone_android_rounded,
          'color': const Color(0xFFFF6600)
        },
        {
          'id': 'WAVE_SN',
          'name': 'Wave Sénégal',
          'subtitle': 'Règlement instantané',
          'icon': Icons.waves_rounded,
          'color': const Color(0xFF1DC3F7)
        },
        {
          'id': 'FREE_SN',
          'name': 'Free Money Sénégal',
          'subtitle': '*150# Free Money',
          'icon': Icons.attach_money_rounded,
          'color': const Color(0xFFE60000)
        },
        {
          'id': 'CARD_SN',
          'name': 'Carte Bancaire',
          'subtitle': 'Visa / Mastercard',
          'icon': Icons.credit_card_rounded,
          'color': const Color(0xFF1A1F71)
        },
      ],
    },
    'ML': {
      'name': 'Mali 🇲🇱',
      'currency': 'XOF',
      'rateToXOF': 1.0,
      'methods': [
        {
          'id': 'SOLDE_SEBGO',
          'name': 'Solde SebGo Pay',
          'subtitle': 'Paiement instantané',
          'icon': Icons.account_balance_wallet_rounded,
          'color': const Color(0xFF0D6EFD)
        },
        {
          'id': 'ORANGE_ML',
          'name': 'Orange Money Mali',
          'subtitle': '#144# Orange Mali',
          'icon': Icons.phone_android_rounded,
          'color': const Color(0xFFFF6600)
        },
        {
          'id': 'MOOV_ML',
          'name': 'Moov Africa Malitel',
          'subtitle': 'Moov Money Mali',
          'icon': Icons.phonelink_ring_rounded,
          'color': const Color(0xFF0055A5)
        },
        {
          'id': 'WAVE_ML',
          'name': 'Wave Mali',
          'subtitle': 'Paiement sans frais',
          'icon': Icons.waves_rounded,
          'color': const Color(0xFF1DC3F7)
        },
        {
          'id': 'CARD_ML',
          'name': 'Carte Bancaire',
          'subtitle': 'Visa / Mastercard',
          'icon': Icons.credit_card_rounded,
          'color': const Color(0xFF1A1F71)
        },
      ],
    },
    'BJ': {
      'name': 'Bénin 🇧🇯',
      'currency': 'XOF',
      'rateToXOF': 1.0,
      'methods': [
        {
          'id': 'SOLDE_SEBGO',
          'name': 'Solde SebGo Pay',
          'subtitle': 'Paiement instantané',
          'icon': Icons.account_balance_wallet_rounded,
          'color': const Color(0xFF0D6EFD)
        },
        {
          'id': 'MTN_BJ',
          'name': 'MTN MoMo Bénin',
          'subtitle': '*880# MTN Bénin',
          'icon': Icons.bolt_rounded,
          'color': const Color(0xFFFFCC00)
        },
        {
          'id': 'MOOV_BJ',
          'name': 'Moov Africa Bénin',
          'subtitle': '*155# Moov Money',
          'icon': Icons.phonelink_ring_rounded,
          'color': const Color(0xFF0055A5)
        },
        {
          'id': 'CELTIIS_BJ',
          'name': 'Celtiis Cash',
          'subtitle': 'Réseau SBIN',
          'icon': Icons.cell_tower_rounded,
          'color': const Color(0xFF8E24AA)
        },
        {
          'id': 'CARD_BJ',
          'name': 'Carte Bancaire',
          'subtitle': 'Visa / Mastercard',
          'icon': Icons.credit_card_rounded,
          'color': const Color(0xFF1A1F71)
        },
      ],
    },
    'TG': {
      'name': 'Togo 🇹🇬',
      'currency': 'XOF',
      'rateToXOF': 1.0,
      'methods': [
        {
          'id': 'SOLDE_SEBGO',
          'name': 'Solde SebGo Pay',
          'subtitle': 'Paiement instantané',
          'icon': Icons.account_balance_wallet_rounded,
          'color': const Color(0xFF0D6EFD)
        },
        {
          'id': 'TMONEY_TG',
          'name': 'TMoney (Togocom)',
          'subtitle': '*145# Togocom',
          'icon': Icons.phone_android_rounded,
          'color': const Color(0xFF2E7D32)
        },
        {
          'id': 'MOOV_TG',
          'name': 'Moov Africa Togo (Flooz)',
          'subtitle': '*155# Flooz',
          'icon': Icons.phonelink_ring_rounded,
          'color': const Color(0xFF0055A5)
        },
        {
          'id': 'CARD_TG',
          'name': 'Carte Bancaire',
          'subtitle': 'Visa / Mastercard',
          'icon': Icons.credit_card_rounded,
          'color': const Color(0xFF1A1F71)
        },
      ],
    },
    'NE': {
      'name': 'Niger 🇳🇪',
      'currency': 'XOF',
      'rateToXOF': 1.0,
      'methods': [
        {
          'id': 'SOLDE_SEBGO',
          'name': 'Solde SebGo Pay',
          'subtitle': 'Paiement instantané',
          'icon': Icons.account_balance_wallet_rounded,
          'color': const Color(0xFF0D6EFD)
        },
        {
          'id': 'AIRTEL_NE',
          'name': 'Airtel Money Niger',
          'subtitle': '*141# Airtel',
          'icon': Icons.phone_android_rounded,
          'color': const Color(0xFFD32F2F)
        },
        {
          'id': 'ZAMANI_NE',
          'name': 'Zamani Cash',
          'subtitle': 'Zamani Telecom',
          'icon': Icons.phonelink_ring_rounded,
          'color': const Color(0xFFE65100)
        },
        {
          'id': 'MOOV_NE',
          'name': 'Moov Africa Niger',
          'subtitle': 'Moov Money Niger',
          'icon': Icons.smartphone_rounded,
          'color': const Color(0xFF0055A5)
        },
        {
          'id': 'CARD_NE',
          'name': 'Carte Bancaire',
          'subtitle': 'Visa / Mastercard',
          'icon': Icons.credit_card_rounded,
          'color': const Color(0xFF1A1F71)
        },
      ],
    },
    'GW': {
      'name': 'Guinée-Bissau 🇬🇼',
      'currency': 'XOF',
      'rateToXOF': 1.0,
      'methods': [
        {
          'id': 'SOLDE_SEBGO',
          'name': 'Solde SebGo Pay',
          'subtitle': 'Paiement instantané',
          'icon': Icons.account_balance_wallet_rounded,
          'color': const Color(0xFF0D6EFD)
        },
        {
          'id': 'ORANGE_GW',
          'name': 'Orange Bissau',
          'subtitle': 'Orange Money',
          'icon': Icons.phone_android_rounded,
          'color': const Color(0xFFFF6600)
        },
        {
          'id': 'MTN_GW',
          'name': 'MTN Guinée-Bissau',
          'subtitle': 'MTN MoMo',
          'icon': Icons.bolt_rounded,
          'color': const Color(0xFFFFCC00)
        },
        {
          'id': 'CARD_GW',
          'name': 'Carte Bancaire',
          'subtitle': 'Visa / Mastercard',
          'icon': Icons.credit_card_rounded,
          'color': const Color(0xFF1A1F71)
        },
      ],
    },
    'GH': {
      'name': 'Ghana 🇬🇭',
      'currency': 'GHS',
      'rateToXOF': 55.0,
      'methods': [
        {
          'id': 'SOLDE_SEBGO',
          'name': 'Solde SebGo Pay',
          'subtitle': 'Instant payment',
          'icon': Icons.account_balance_wallet_rounded,
          'color': const Color(0xFF0D6EFD)
        },
        {
          'id': 'MTN_GH',
          'name': 'MTN Mobile Money Ghana',
          'subtitle': '*170# MoMo',
          'icon': Icons.bolt_rounded,
          'color': const Color(0xFFFFCC00)
        },
        {
          'id': 'VODAFONE_GH',
          'name': 'Telecel Cash Ghana (Vodafone)',
          'subtitle': '*110#',
          'icon': Icons.phone_android_rounded,
          'color': const Color(0xFFE60000)
        },
        {
          'id': 'AIRTELTIGO_GH',
          'name': 'AirtelTigo Cash',
          'subtitle': '*501#',
          'icon': Icons.smartphone_rounded,
          'color': const Color(0xFF0055A5)
        },
        {
          'id': 'CARD_GH',
          'name': 'Bank Card',
          'subtitle': 'Visa / Mastercard',
          'icon': Icons.credit_card_rounded,
          'color': const Color(0xFF1A1F71)
        },
      ],
    },
    'NG': {
      'name': 'Nigeria 🇳🇬',
      'currency': 'NGN',
      'rateToXOF': 0.75,
      'methods': [
        {
          'id': 'SOLDE_SEBGO',
          'name': 'Solde SebGo Pay',
          'subtitle': 'Instant wallet payment',
          'icon': Icons.account_balance_wallet_rounded,
          'color': const Color(0xFF0D6EFD)
        },
        {
          'id': 'OPAY_NG',
          'name': 'OPay Nigeria',
          'subtitle': 'OPay Digital Wallet',
          'icon': Icons.account_balance_rounded,
          'color': const Color(0xFF2E7D32)
        },
        {
          'id': 'PALMPAY_NG',
          'name': 'PalmPay',
          'subtitle': 'PalmPay App Transfer',
          'icon': Icons.phone_android_rounded,
          'color': const Color(0xFF0055A5)
        },
        {
          'id': 'MTN_NG',
          'name': 'MTN Momo PSB Nigeria',
          'subtitle': '*671#',
          'icon': Icons.bolt_rounded,
          'color': const Color(0xFFFFCC00)
        },
        {
          'id': 'CARD_NG',
          'name': 'Debit Card (Naira / USD)',
          'subtitle': 'Secure Online Payment',
          'icon': Icons.credit_card_rounded,
          'color': const Color(0xFF1A1F71)
        },
      ],
    },
    'GM': {
      'name': 'Gambie 🇬🇲',
      'currency': 'GMD',
      'rateToXOF': 10.5,
      'methods': [
        {
          'id': 'SOLDE_SEBGO',
          'name': 'Solde SebGo Pay',
          'subtitle': 'Instant payment',
          'icon': Icons.account_balance_wallet_rounded,
          'color': const Color(0xFF0D6EFD)
        },
        {
          'id': 'QCELL_GM',
          'name': 'QMoney (QCell)',
          'subtitle': '*323# QCell Gambia',
          'icon': Icons.phone_android_rounded,
          'color': const Color(0xFFE60000)
        },
        {
          'id': 'AFRICELL_GM',
          'name': 'Africell Money (Afrimoney)',
          'subtitle': '*131# Afrimoney',
          'icon': Icons.smartphone_rounded,
          'color': const Color(0xFF1DC3F7)
        },
        {
          'id': 'CARD_GM',
          'name': 'Bank Card',
          'subtitle': 'Visa / Mastercard',
          'icon': Icons.credit_card_rounded,
          'color': const Color(0xFF1A1F71)
        },
      ],
    },
    'GN': {
      'name': 'Guinée 🇬🇳',
      'currency': 'GNF',
      'rateToXOF': 0.075,
      'methods': [
        {
          'id': 'SOLDE_SEBGO',
          'name': 'Solde SebGo Pay',
          'subtitle': 'Paiement instantané',
          'icon': Icons.account_balance_wallet_rounded,
          'color': const Color(0xFF0D6EFD)
        },
        {
          'id': 'ORANGE_GN',
          'name': 'Orange Money Guinée',
          'subtitle': '#144# Orange Guinée',
          'icon': Icons.phone_android_rounded,
          'color': const Color(0xFFFF6600)
        },
        {
          'id': 'MTN_GN',
          'name': 'MTN MoMo Guinée',
          'subtitle': '*123# MoMo',
          'icon': Icons.bolt_rounded,
          'color': const Color(0xFFFFCC00)
        },
        {
          'id': 'CARD_GN',
          'name': 'Carte Bancaire',
          'subtitle': 'Visa / Mastercard',
          'icon': Icons.credit_card_rounded,
          'color': const Color(0xFF1A1F71)
        },
      ],
    },
    'LR': {
      'name': 'Libéria 🇱🇷',
      'currency': 'LRD',
      'rateToXOF': 3.3,
      'methods': [
        {
          'id': 'SOLDE_SEBGO',
          'name': 'Solde SebGo Pay',
          'subtitle': 'Instant payment',
          'icon': Icons.account_balance_wallet_rounded,
          'color': const Color(0xFF0D6EFD)
        },
        {
          'id': 'MTN_LR',
          'name': 'MTN Mobile Money Liberia',
          'subtitle': '*156# MoMo',
          'icon': Icons.bolt_rounded,
          'color': const Color(0xFFFFCC00)
        },
        {
          'id': 'ORANGE_LR',
          'name': 'Orange Money Liberia',
          'subtitle': '*144# Orange',
          'icon': Icons.phone_android_rounded,
          'color': const Color(0xFFFF6600)
        },
        {
          'id': 'CARD_LR',
          'name': 'Bank Card',
          'subtitle': 'Visa / Mastercard',
          'icon': Icons.credit_card_rounded,
          'color': const Color(0xFF1A1F71)
        },
      ],
    },
    'SL': {
      'name': 'Sierra Leone 🇸🇱',
      'currency': 'SLL',
      'rateToXOF': 0.03,
      'methods': [
        {
          'id': 'SOLDE_SEBGO',
          'name': 'Solde SebGo Pay',
          'subtitle': 'Instant payment',
          'icon': Icons.account_balance_wallet_rounded,
          'color': const Color(0xFF0D6EFD)
        },
        {
          'id': 'ORANGE_SL',
          'name': 'Orange Money Sierra Leone',
          'subtitle': '#144# Orange',
          'icon': Icons.phone_android_rounded,
          'color': const Color(0xFFFF6600)
        },
        {
          'id': 'AFRICELL_SL',
          'name': 'Africell Money (Afrimoney)',
          'subtitle': '*161# Afrimoney',
          'icon': Icons.smartphone_rounded,
          'color': const Color(0xFF1DC3F7)
        },
        {
          'id': 'CARD_SL',
          'name': 'Bank Card',
          'subtitle': 'Visa / Mastercard',
          'icon': Icons.credit_card_rounded,
          'color': const Color(0xFF1A1F71)
        },
      ],
    },
    'CV': {
      'name': 'Cap-Vert 🇨🇻',
      'currency': 'CVE',
      'rateToXOF': 5.5,
      'methods': [
        {
          'id': 'SOLDE_SEBGO',
          'name': 'Solde SebGo Pay',
          'subtitle': 'Pagamento instantâneo',
          'icon': Icons.account_balance_wallet_rounded,
          'color': const Color(0xFF0D6EFD)
        },
        {
          'id': 'SINTIC_CV',
          'name': 'Sintic / PayCV',
          'subtitle': 'Rede nacional de pagamentos',
          'icon': Icons.phone_android_rounded,
          'color': const Color(0xFF0055A5)
        },
        {
          'id': 'CARD_CV',
          'name': 'Cartão Bancário',
          'subtitle': 'Visa / Mastercard',
          'icon': Icons.credit_card_rounded,
          'color': const Color(0xFF1A1F71)
        },
      ],
    },
    'MR': {
      'name': 'Mauritanie 🇲🇷',
      'currency': 'XOF',
      'rateToXOF': 1.0,
      'methods': [
        {
          'id': 'SOLDE_SEBGO',
          'name': 'Solde SebGo Pay',
          'subtitle': 'Paiement instantané',
          'icon': Icons.account_balance_wallet_rounded,
          'color': const Color(0xFF0D6EFD)
        },
        {
          'id': 'BANKILY_MR',
          'name': 'Bankily / Masrvi',
          'subtitle': 'Paiement mobile Mauritanie',
          'icon': Icons.phone_android_rounded,
          'color': const Color(0xFF2E7D32)
        },
        {
          'id': 'SEDAD_MR',
          'name': 'Sedad Mauritanie',
          'subtitle': 'Mobile wallet',
          'icon': Icons.smartphone_rounded,
          'color': const Color(0xFFE65100)
        },
        {
          'id': 'CARD_MR',
          'name': 'Carte Bancaire',
          'subtitle': 'Visa / Mastercard',
          'icon': Icons.credit_card_rounded,
          'color': const Color(0xFF1A1F71)
        },
      ],
    },
  };

  @override
  void initState() {
    super.initState();
    _fetchEscrowDetails();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchEscrowDetails() async {
    if (widget.paymentToken.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage =
              "Aucun jeton de paiement n'a été fourni.\nVeuillez utiliser le lien sécurisé envoyé par le marchand.";
          _isLoading = false;
        });
      }
      return;
    }
    try {
      // Récupération sécurisée du coffre-fort Escrow avec jointure optionnelle sur le profil du marchand lié par UUID
      final response = await _supabase
          .from('escrow')
          .select('*, profiles:merchant_id(id)')
          .eq('payment_token', widget.paymentToken)
          .maybeSingle();

      if (response == null || response['status'] == 'COMPLETED') {
        if (mounted) {
          setState(() {
            _errorMessage = response == null
                ? "Lien de paiement invalide ou introuvable."
                : "Ce paiement Escrow a déjà été réglé avec succès.";
            _isLoading = false;
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          _escrowDetails = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              "Erreur de connexion au serveur : Veuillez réessayer.";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _processPayment() async {
    if (_escrowDetails == null) return;
    final buyerPhone = _phoneController.text.trim();
    if (buyerPhone.isEmpty || buyerPhone.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Veuillez entrer un numéro de téléphone valide."),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 🌟 VALIDATION RELATIONNELLE : Vérification de la présence du merchant_id (UUID)
    final String? merchantId = _escrowDetails!['merchant_id'];
    if (merchantId == null || merchantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              "Erreur critique : Aucun marchand associé à ce coffre-fort Escrow."),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isProcessingPayment = true);
    try {
      final double originalAmount =
          (_escrowDetails!['amount'] as num).toDouble();
      final double convertedAmount = originalAmount * _exchangeRate;
      final String baseCurrency = _escrowDetails!['currency'] ?? 'XOF';

      // 🌟 APPEL RPC SÉCURISÉ : Sans aucun paramètre de téléphone obsolète (recipient_phone / merchant_phone)
      await _supabase.rpc('process_escrow_payment_atomic', params: {
        'p_token': widget.paymentToken,
        'p_method': _selectedPaymentMethod,
        'p_country': _selectedCountryCode,
        'p_paid_amount': convertedAmount,
        'p_paid_currency': _selectedCurrency,
        'p_buyer_phone': buyerPhone,
        'p_canal': _selectedPaymentMethod,
      });

      if (!mounted) return;
      setState(() {
        _isPaymentSuccess = true;
        _lastTransactionSummary = {
          'originalAmount': originalAmount,
          'convertedAmount': convertedAmount,
          'baseCurrency': baseCurrency,
          'paidCurrency': _selectedCurrency,
          'paymentMethod': _selectedPaymentMethod,
          'countryCode': _selectedCountryCode,
          'buyerPhone': buyerPhone,
        };
      });
    } on PostgrestException catch (e) {
      String userMsg = "Échec : ${e.message}";
      if (e.message.contains('ALREADY_PAID')) {
        userMsg = "Ce paiement a déjà été effectué depuis un autre appareil.";
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMsg),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Erreur système. Veuillez réessayer."),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF0D6EFD)),
              SizedBox(height: 16),
              Text(
                "Chargement du coffre-fort Escrow...",
                style: TextStyle(
                  color: Color(0xFF718096),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text("SebGo Pay"),
          backgroundColor: const Color(0xFF0D6EFD),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.link_off_rounded,
                  size: 64,
                  color: Colors.orangeAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          "SebGo Pay • Afrique de l'Ouest",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D6EFD),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(scrollbars: false),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Card(
                  elevation: 6,
                  shadowColor: Colors.black.withOpacity(0.06),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _isPaymentSuccess
                        ? _buildSuccessView()
                        : _buildCheckoutForm(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutForm() {
    final double originalAmount = (_escrowDetails!['amount'] as num).toDouble();
    final String baseCurrency = _escrowDetails!['currency'] ?? 'XOF';
    _exchangeRate =
        (_regionalProviders[_selectedCountryCode]!['rateToXOF'] as num)
            .toDouble();
    _selectedCurrency =
        _regionalProviders[_selectedCountryCode]!['currency'] as String;
    final double convertedAmount = originalAmount * _exchangeRate;
    final List<dynamic> methods =
        _regionalProviders[_selectedCountryCode]!['methods'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFC8E6C9)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_user_rounded,
                color: Color(0xFF2E7D32),
                size: 18,
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  "Paiement Sécurisé par Coffre-Fort Escrow",
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Text(
                "Montant réclamé par le vendeur",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    originalAmount.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A202C),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    baseCurrency,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D6EFD),
                    ),
                  ),
                ],
              ),
              if (_selectedCurrency != baseCurrency) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.currency_exchange_rounded,
                      size: 16,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Montant converti : ${convertedAmount.toStringAsFixed(2)} $_selectedCurrency",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "Votre Pays de Règlement (16 Pays - CEDEAO)",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFCBD5E0)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCountryCode,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF4A5568),
              ),
              items: _regionalProviders.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(
                    entry.value['name'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A202C),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (code) {
                if (code != null) {
                  setState(() {
                    _selectedCountryCode = code;
                    _selectedPaymentMethod =
                        _regionalProviders[code]!['methods'][0]['id'];
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Numéro de téléphone de l'acheteur (Payeur)",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: "Entrez votre numéro (ex: +226...)",
            prefixIcon:
                const Icon(Icons.phone_rounded, color: Color(0xFF0D6EFD)),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0D6EFD), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "Moyen de paiement disponible",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 12),
        ...methods.map((method) {
          final bool isSelected = _selectedPaymentMethod == method['id'];
          final Color itemColor = method['color'] as Color;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: InkWell(
              onTap: () => setState(
                () => _selectedPaymentMethod = method['id'] as String,
              ),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? itemColor.withOpacity(0.05)
                      : const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? itemColor : const Color(0xFFE2E8F0),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: itemColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        method['icon'] as IconData,
                        color: itemColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method['name'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isSelected
                                  ? const Color(0xFF1A202C)
                                  : const Color(0xFF4A5568),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            method['subtitle'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Radio<String>(
                      value: method['id'] as String,
                      groupValue: _selectedPaymentMethod,
                      activeColor: itemColor,
                      onChanged: (val) => setState(
                        () => _selectedPaymentMethod = val!,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D6EFD),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            onPressed: _isProcessingPayment ? null : _processPayment,
            child: _isProcessingPayment
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    "Valider le Paiement (${_selectedCurrency == baseCurrency ? '${originalAmount.toStringAsFixed(0)} $baseCurrency' : '${convertedAmount.toStringAsFixed(2)} $_selectedCurrency'})",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    final summary = _lastTransactionSummary!;
    final double originalAmount = summary['originalAmount'];
    final double convertedAmount = summary['convertedAmount'];
    final String baseCurrency = summary['baseCurrency'];
    final String paidCurrency = summary['paidCurrency'];
    final String formattedAmountText = (paidCurrency != baseCurrency)
        ? "${convertedAmount.toStringAsFixed(2)} $paidCurrency (${originalAmount.toStringAsFixed(0)} $baseCurrency)"
        : "${originalAmount.toStringAsFixed(0)} $baseCurrency";

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: Color(0xFFE8F5E9),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF2E7D32),
            size: 60,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Paiement Sécurisé !",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: Color(0xFF1A202C),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Votre règlement de $formattedAmountText est désormais sécurisé dans le coffre-fort SebGo Pay.",
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF4A5568),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEDF2F7)),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFF2E7D32), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Les fonds seront libérés au vendeur dès réception conforme de la marchandise.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF718096),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D6EFD),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            onPressed: () {},
            child: const Text(
              "Transaction Terminée",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}
