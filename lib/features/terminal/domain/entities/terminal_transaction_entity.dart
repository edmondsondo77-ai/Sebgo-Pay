import 'package:uuid/uuid.dart';

/// Représente une action effectuée par le marchand sur son terminal SebGo Pay
class TerminalTransactionEntity {
  final String id;
  final double amount;
  final String currency;
  final String actionType; // 'scanner', 'my_qr', 'share', 'p2p'
  final DateTime timestamp;
  final String? recipientPhone;
  final String?
      paymentToken; // Lien vers le coffre-fort si actionType == 'share'

  TerminalTransactionEntity({
    String? id,
    required this.amount,
    required this.currency,
    required this.actionType,
    required this.timestamp,
    this.recipientPhone,
    this.paymentToken,
  }) : id = id ?? const Uuid().v4();
}
