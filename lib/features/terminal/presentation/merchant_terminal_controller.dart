import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sebgo_pay/features/terminal/domain/repositories/terminal_repository.dart';
import 'package:sebgo_pay/features/terminal/data/repositories/terminal_repository_impl.dart';
import 'package:sebgo_pay/features/terminal/domain/usecase/process_terminal_action_usecase.dart';
import 'package:sebgo_pay/features/terminal/presentation/qr_scanner_screen.dart';
import 'package:sebgo_pay/features/terminal/presentation/p2p_recipient_screen.dart';
import 'package:sebgo_pay/core/utils/phone_helper.dart';

// Importez votre widget de vue
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
  late final ProcessTerminalActionUsecase _processActionUsecase;

  @override
  void initState() {
    super.initState();
    final TerminalRepository repository =
        TerminalRepositoryImpl(Supabase.instance.client);
    _processActionUsecase = ProcessTerminalActionUsecase(repository);
  }

  void _onKeyPressed(String value) {
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
    final double amount = double.tryParse(_amountString) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez saisir un montant valide supérieur à 0"),
        ),
      );
      return;
    }

    try {
      // 1. Récupération dynamique du numéro du marchand connecté (ex: depuis la session Supabase Auth)
      final merchantPhone =
          Supabase.instance.client.auth.currentUser?.phone ?? '+22670000000';

      // 2. Appel unique du UseCase qui gère l'enregistrement ET retourne le paymentToken si actionType == 'share'
      final String? paymentToken = await _processActionUsecase.call(
        amount: amount,
        currency: 'XOF',
        actionType: actionType,
        recipientPhone: merchantPhone,
      );

      if (!mounted) return;

      switch (actionType) {
        case 'my_qr':
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
                        data:
                            'sebgo://pay?amount=$amount&currency=XOF&type=my_qr',
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
              recipientPhone: merchantPhone,
            );
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
          // 3. Utilisation du token retourné par le UseCase (plus d'appel direct à Supabase !)
          if (paymentToken != null) {
            // 1. URL de paiement
            // En environnement de développement local (Web/PC) :
            final String paymentLink =
                "https://sebgo-pay.netlify.app/#/pay/$paymentToken";
            //debut cmt final String paymentLink =
            //fin cmt    "https://pay.sebgo.com/pay/$paymentToken";

            final String message =
                " 🧾  *Facture & Paiement Sécurisé SebGo Pay*\n\n"
                "Montant : $amount XOF\n"
                "Coffre-fort Escrow : Validé et en attente  🔒 \n\n"
                "Réglez en toute sécurité en cliquant sur ce lien unique :\n"
                "$paymentLink\n\n"
                "Merci pour votre confiance !  🇧🇫 ";

            await Share.share(
              message,
              subject: 'Paiement Sécurisé SebGo Pay - $amount XOF',
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Lien de paiement Escrow partagé avec succès !"),
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
          final phoneDigits = routingResult.formattedPhone;
          final maskedRecipient = phoneDigits.length > 8
              ? '${phoneDigits.substring(0, 4)} ${phoneDigits.substring(4, 6)} **** ${phoneDigits.substring(phoneDigits.length - 2)}'
              : phoneDigits;

          final bool? confirmed = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: Row(
                  children: const [
                    Icon(Icons.security, color: Color(0xFF0061FF)),
                    SizedBox(width: 8),
                    Text("Récapitulatif - Envoi P2P"),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(routingResult.flagEmoji,
                              style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Destination détectée",
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                              Text(routingResult.countryName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text("Destinataire : $maskedRecipient",
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text("Montant : $amount XOF",
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    const Text("Frais de transfert : 0 XOF",
                        style: TextStyle(
                            color: Colors.green, fontWeight: FontWeight.w500)),
                    const Divider(height: 20),
                    Text(
                      "Total à prélever : $amount XOF",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF0061FF)),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Annuler",
                        style: TextStyle(color: Colors.red)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0061FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Confirmer le transfert"),
                  ),
                ],
              );
            },
          );

          if (confirmed == true && mounted) {
            await _processActionUsecase.call(
              amount: amount,
              currency: 'XOF',
              actionType: 'p2p_transfer',
              recipientPhone: routingResult.formattedPhone,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.currentMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        //  title: const Text("SebGo Pay - Terminal Marchand"),
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
