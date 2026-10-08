import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:sebgo_pay/core/utils/phone_helper.dart';

class P2pRecipientScreen extends StatefulWidget {
  final double amount;
  const P2pRecipientScreen({super.key, required this.amount});

  @override
  State<P2pRecipientScreen> createState() => _P2pRecipientScreenState();
}

class _P2pRecipientScreenState extends State<P2pRecipientScreen> {
  final TextEditingController _phoneController = TextEditingController();

  Future<void> _pickContact() async {
    if (await FlutterContacts.requestPermission(readonly: true)) {
      final Contact? contact = await FlutterContacts.openExternalPick();
      if (contact != null && contact.phones.isNotEmpty) {
        setState(() {
          _phoneController.text = contact.phones.first.number;
        });
      }
    }
  }

  /// Normalisation intelligente et automatique du numéro (Routage Panafricain)
  /// Si aucun indicatif n'est présent, on applique par défaut le pays local (+226 - Burkina Faso).
  String _normalizePhoneNumber(String rawInput) {
    String cleaned =
        rawInput.replaceAll(RegExp(r'\s+'), ''); // Supprime les espaces

    if (cleaned.startsWith('+')) {
      return cleaned; // Déjà au format international (ex: +225...)
    }

    // Si le numéro commence par un 0 ou ne contient pas d'indicatif, on applique le défaut (+226)
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }

    // Par défaut pour le contexte local (Burkina Faso)
    return '+226$cleaned';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Envoi d'argent P2P"),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // En-tête du montant
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0061FF).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Montant du transfert",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${widget.amount.toStringAsFixed(0)} XOF",
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0061FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      "Identifier le destinataire",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Champ de saisie du numéro
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Numéro de téléphone",
                        hintText: "Ex: 70000000 ou +225...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.phone_iphone),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bouton répertoire parfaitement aligné
                    InkWell(
                      onTap: _pickContact,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Répertoire",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.contacts_outlined),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              "Choisir dans le répertoire",
                              style: TextStyle(
                                  color: Colors.black87, fontSize: 16),
                            ),
                            Icon(Icons.arrow_forward_ios,
                                size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Bouton de validation
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0061FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () {
                        final rawPhone = _phoneController.text.trim();
                        try {
                          if (rawPhone.isEmpty) {
                            throw Exception(
                                "Veuillez entrer un numéro de téléphone.");
                          }

                          // Analyse et routage sécurisé (lève une exception si le numéro est trop court)
                          final routingResult =
                              normalizeAndRoutePhoneNumber(rawPhone);

                          // On renvoie le numéro formaté au contrôleur via le Navigator.pop
                          Navigator.pop(context, routingResult.formattedPhone);
                        } catch (e) {
                          // Affichage d'une alerte propre si l'utilisateur saisit "5" ou un format invalide
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  e.toString().replaceAll("Exception: ", "")),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: const Text(
                        "Continuer vers le récapitulatif",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
