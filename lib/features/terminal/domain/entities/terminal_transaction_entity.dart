import 'package:uuid/uuid.dart';

class TerminalTransactionEntity {
  final String id;
  final double amount;
  final String currency;
  final String actionType; // 'scanner', 'my_qr', 'share', 'p2p'
  final DateTime timestamp;
  final String? recipientPhone; // 1. Ajout de la propriété pour le P2P

  TerminalTransactionEntity({
    String? id,
    required this.amount,
    required this.currency,
    required this.actionType,
    required this.timestamp,
    this.recipientPhone, // 2. Ajout dans le constructeur optionnel
  }) : id = id ??
            const Uuid()
                .v4(); // Génère automatiquement un UUID valide si aucun n'est fourni
}
