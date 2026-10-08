import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:sebgo_pay/core/utils/phone_helper.dart';

class P2pRecipientScreen extends StatefulWidget {
  final double amount;

  const P2pRecipientScreen({
    super.key,
    required this.amount,
  });

  @override
  State<P2pRecipientScreen> createState() => _P2pRecipientScreenState();
}

class _P2pRecipientScreenState extends State<P2pRecipientScreen> {
  final TextEditingController _phoneController = TextEditingController();

  // 1. Libération de la mémoire
  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // 2. Sélection de contact sécurisée
  Future<void> _pickContact() async {
    try {
      if (await FlutterContacts.requestPermission(readonly: true)) {
        final Contact? contact = await FlutterContacts.openExternalPick();

        // Vérification de la présence du widget avant setState
        if (!mounted) return;

        if (contact != null && contact.phones.isNotEmpty) {
          setState(() {
            _phoneController.text = contact.phones.first.number;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la sélection du contact : $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 3. Validation et routage sécurisés
  void _submitRecipient() {
    final rawPhone = _phoneController.text.trim();

    if (rawPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez entrer un numéro de téléphone."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Analyse et routage régional (Burkina Faso + 15 pays CEDEAO)
      final routingResult = normalizeAndRoutePhoneNumber(rawPhone);

      // Envoi du numéro normalisé au contrôleur parent
      Navigator.pop(context, routingResult.formattedPhone);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Destinataire du transfert"),
        backgroundColor: const Color(0xFF0061FF),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rappel du montant à envoyer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0061FF).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Montant à envoyer :",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "${widget.amount} XOF",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0061FF),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Champ de saisie du numéro avec bouton de sélection de contact
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitRecipient(),
              decoration: InputDecoration(
                labelText: "Numéro de téléphone du destinataire",
                hintText: "Ex: +226 70 00 00 00 ou 07000000",
                prefixIcon: const Icon(Icons.phone),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.contacts, color: Color(0xFF0061FF)),
                  onPressed: _pickContact,
                  tooltip: "Sélectionner dans les contacts",
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Saisissez l'indicatif pays (ex: +225, +233) pour un envoi international CEDEAO.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Spacer(),

            // Bouton de validation
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0061FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _submitRecipient,
                child: const Text(
                  "Continuer",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
