import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isLoadingContact = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickContact() async {
    setState(() => _isLoadingContact = true);
    try {
      if (await FlutterContacts.requestPermission(readonly: true)) {
        final Contact? contact = await FlutterContacts.openExternalPick();
        if (!mounted) return;
        if (contact != null && contact.phones.isNotEmpty) {
          setState(() {
            // Nettoyage automatique du numéro extrait des contacts
            String rawNum =
                contact.phones.first.number.replaceAll(RegExp(r'[^\d+]'), '');
            _phoneController.text = rawNum;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Accès aux contacts non disponible sur cette plateforme."),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingContact = false);
    }
  }

  // Affichage d'un récapitulatif immersif de style "Alipay" avant validation finale
  void _showAlipayStyleSummary(String normalizedPhone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indicateur de glissement
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0061FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shield_rounded,
                        color: Color(0xFF0061FF), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Récapitulatif - Envoi P2P",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow("Destinataire", normalizedPhone),
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1)),
                    _buildSummaryRow(
                        "Montant", "${widget.amount.toStringAsFixed(0)} XOF"),
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1)),
                    _buildSummaryRow("Frais de transfert", "0 XOF",
                        isFree: true),
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1)),
                    _buildSummaryRow("Total à prélever",
                        "${widget.amount.toStringAsFixed(0)} XOF",
                        isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Annuler",
                          style: TextStyle(
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0061FF),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Ferme la modale
                        Navigator.pop(context,
                            normalizedPhone); // Retourne le numéro validé
                      },
                      child: const Text("Confirmer",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isBold = false, bool isFree = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(
            color: isFree ? Colors.green.shade700 : const Color(0xFF1E293B),
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _submitRecipient() {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez entrer un numéro de téléphone valide."),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      // Analyse et routage régional sécurisé (CEDEAO)
      final routingResult = normalizeAndRoutePhoneNumber(rawPhone);
      // Déclenchement du récapitulatif immersif type Alipay
      _showAlipayStyleSummary(routingResult.formattedPhone);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Destinataire du transfert",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carte épurée du montant
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0061FF).withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF0061FF).withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Montant à envoyer",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475569)),
                    ),
                    Text(
                      "${widget.amount.toStringAsFixed(0)} XOF",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0061FF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                "Numéro Mobile Money",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              // Champ de saisie strictement numérique
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(
                      r'[0-9+]')), // Chiffres et '+' uniquement (Zéro lettre)
                ],
                onSubmitted: (_) => _submitRecipient(),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: "Ex: +226 70 00 00 00",
                  hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.normal),
                  prefixIcon: const Icon(Icons.phone_iphone_rounded,
                      color: Color(0xFF0061FF)),
                  suffixIcon: _isLoadingContact
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          icon: const Icon(Icons.contacts_rounded,
                              color: Color(0xFF0061FF)),
                          onPressed: _pickContact,
                          tooltip: "Sélectionner depuis les contacts",
                        ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Color(0xFF0061FF), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Compatible avec tous les opérateurs de la zone CEDEAO (Indicatif requis pour l'international).",
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0061FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
      ),
    );
  }
}
