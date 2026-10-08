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
            content: Text("Veuillez saisir un montant valide supérieur à 0")),
      );
      return;
    }

    try {
      await _processActionUsecase.call(
        amount: amount,
        currency: 'XOF',
        actionType: actionType,
      );
      if (!mounted) return;

      String message = "";
      switch (actionType) {
        case 'my_qr':
          message = "QR code de caisse généré pour $amount XOF";

          // Affichage de la boîte de dialogue avec le QR code
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
        case 'scanner':
          // Navigation vers l'écran de la caméra
          final scannedData = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (_) => QrScannerScreen(amount: amount),
            ),
          );

          if (scannedData != null && mounted) {
            // Traitement du code scanné du client
            await _processActionUsecase.call(
              amount: amount,
              currency: 'XOF',
              actionType: 'scanner_success',
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
          // Génération d'une référence ou d'un lien unique de paiement sécurisé
          final String paymentLink =
              "https://pay.sebgo.com/pay?amount=$amount&currency=XOF";
          final String message =
              "Lien de paiement sécurisé SebGo Pay : $amount XOF.\nRéglez en toute sécurité ici : $paymentLink";

          // Appel du partage natif (WhatsApp, Messenger, SMS, etc.)
          await Share.share(message,
              subject: 'Paiement SebGo Pay - $amount XOF');
          break;
        case 'p2p':
          // 1. Identification du destinataire (Saisie manuelle ou répertoire)
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

          // 2. Normalisation et routage panafricain intelligent (avec le helper)
          final routingResult =
              normalizeAndRoutePhoneNumber(recipientPhoneInput);

          // Masquage intelligent et propre (ex: +225 05 **** 14)
          final phoneDigits = routingResult.formattedPhone;
          final maskedRecipient = phoneDigits.length > 8
              ? '${phoneDigits.substring(0, 4)} ${phoneDigits.substring(4, 6)} **** ${phoneDigits.substring(phoneDigits.length - 2)}'
              : phoneDigits;

          // 3. Affichage du récapitulatif ultra-professionnel avec Drapeau et Pays
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
                    // En-tête Pays & Drapeau pour rassurer l'utilisateur
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

          // 4. Validation finale et enregistrement dans la base de données Supabase
          if (confirmed == true && mounted) {
            await _processActionUsecase.call(
              amount: amount,
              currency: 'XOF',
              actionType: 'p2p_transfer',
              recipientPhone: routingResult
                  .formattedPhone, // On envoie le numéro normalisé définitif
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );

      setState(() {
        _amountString = "0";
      });
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
