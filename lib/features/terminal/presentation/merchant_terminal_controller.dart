import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sebgo_pay/features/terminal/domain/repositories/terminal_repository.dart';
import 'package:sebgo_pay/features/terminal/data/repositories/terminal_repository_impl.dart';
import 'package:sebgo_pay/features/terminal/data/datasources/paxity_remote_datasource.dart';
import 'package:sebgo_pay/features/terminal/domain/usecase/process_terminal_action_usecase.dart';
import 'package:sebgo_pay/features/terminal/presentation/qr_scanner_screen.dart';
import 'package:sebgo_pay/features/terminal/presentation/p2p_recipient_screen.dart';
import 'package:sebgo_pay/core/utils/phone_helper.dart';
import 'terminal_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MerchantTerminalController extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentMode;

  const MerchantTerminalController({
    super.key,
    required this.onThemeChanged,
    required this.currentMode,
  });

  @override
  State<MerchantTerminalController> createState() =>
      _MerchantTerminalControllerState();
}

class _MerchantTerminalControllerState
    extends State<MerchantTerminalController> {
  String _amountString = "0";
  bool _isLoading = false; // Drapeau anti-double clic[cite: 10]
  late final ProcessTerminalActionUsecase _processActionUsecase;

  @override
  void initState() {
    super.initState();
    
    final TerminalRepository repository =
        TerminalRepositoryImpl(Supabase.instance.client);

    // Initialisation du DataSource Paxity avec la clé API Sandbox
 final paxityDataSource = PaxityRemoteDataSource(
  supabaseClient: Supabase.instance.client,
);
    _processActionUsecase = ProcessTerminalActionUsecase(
      repository: repository,
      paxityRemoteDataSource: paxityDataSource,
    );
  }

  void _onKeyPressed(String value) {
    if (_isLoading) return;
    setState(() {
      if (value == "C") {
        _amountString = "0";
      } else if (value == "X") {
        if (_amountString.length > 1) {
          _amountString = _amountString.substring(0, _amountString.length - 1);
        } else {
          _amountString = "0";
        }
      } else {
        if (_amountString == "0") {
          _amountString = value;
        } else {
          if (_amountString.length < 9) {
            _amountString += value;
          }
        }
      }
    });
  }

  Future<void> _handleAction(String actionType) async {
    if (_isLoading) return; // Sécurité anti-double clic[cite: 10]
    final double amount = double.tryParse(_amountString) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez saisir un montant valide supérieur à 0"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      switch (actionType) {
        case 'my_qr':
          final String? paymentToken = await _processActionUsecase.call(
            amount: amount,
            currency: 'XOF',
            actionType: actionType,
          );

          if (!mounted) return;
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Encaissement SebGo Pay"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$amount XOF",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0061FF),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: QrImageView(
                        data: 'sebgo://pay?amount=$amount&currency=XOF&type=my_qr&token=$paymentToken',
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Demandez au client de flasher ce code pour régler.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Fermer"),
                  ),
                ],
              );
            },
          );
          break;

        case 'scanner':
          final scannedData = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (_) => QrScannerScreen(amount: amount),
            ),
          );

          if (scannedData != null && mounted) {
            await _processActionUsecase.call(
              amount: amount,
              currency: 'XOF',
              actionType: 'scanner_success',
            );

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Paiement validé pour le code : $scannedData"),
                backgroundColor: Colors.green,
              ),
            );
            setState(() {
              _amountString = "0";
            });
          }
          break;

        case 'share':
          // Génération du lien de paiement Sandbox direct via Paxity
          final String? paymentLink = await _processActionUsecase.call(
            amount: amount,
            currency: 'XOF',
            actionType: actionType,
          );

          if (paymentLink != null && mounted) {
            final String message =
                "🧾 *Facture & Paiement Sécurisé SebGo Pay*\n\n"
                "Montant : $amount XOF\n"
                "Coffre-fort Escrow : En attente de règlement🔒\n\n"
                "Réglez en toute sécurité via notre guichet partagé :\n"
                "$paymentLink\n\n"
                "Merci pour votre confiance ! 🇧🇫";

            await Share.share(
              message,
              subject: 'Paiement Sécurisé SebGo Pay - $amount XOF',
            );

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Lien de paiement Paxity Sandbox partagé avec succès !"),
                backgroundColor: Colors.green,
              ),
            );
            setState(() {
              _amountString = "0";
            });
          }
          break;

        case 'p2p':
          final recipientPhoneInput = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (_) => P2pRecipientScreen(amount: amount),
            ),
          );

          if (recipientPhoneInput == null ||
              recipientPhoneInput.isEmpty ||
              !mounted) {
            return;
          }

          final routingResult =
              normalizeAndRoutePhoneNumber(recipientPhoneInput);

          if (routingResult.formattedPhone.isNotEmpty && mounted) {
            await _processActionUsecase.call(
              amount: amount,
              currency: 'XOF',
              actionType: 'p2p_transfer',
            );

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    "Transfert de $amount XOF vers ${routingResult.countryName} réussi !"),
                backgroundColor: Colors.green,
              ),
            );
            setState(() {
              _amountString = "0";
            });
          }
          break;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.currentMode == ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              widget.onThemeChanged(isDark ? ThemeMode.light : ThemeMode.dark);
            },
          ),
        ],
      ),
      body: TabTerminalWidget(
        amount: _amountString,
        currency: 'XOF',
        isDark: isDark,
        onPressKey: _onKeyPressed,
        onScanQr: () => _handleAction('scanner'),
        onShowMyQr: () => _handleAction('my_qr'),
        onShareInvoice: () => _handleAction('share'),
        onSendMoneyP2P: () => _handleAction('p2p'),
      ),
    );
  }
}