import '../../domain/entities/terminal_transaction_entity.dart';

class TerminalTransactionModel extends TerminalTransactionEntity {
  TerminalTransactionModel({
    super.id,
    required super.amount,
    required super.currency,
    required super.actionType,
    required super.timestamp,
    super.recipientPhone,
    super.paymentToken,
  });

  /// Convertit le modèle en Map (JSON) pour l'insertion dans la table Supabase `transactions`.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'action_type': actionType, // Correspond à la colonne SQL action_type
      'created_at': timestamp.toIso8601String(),
      if (recipientPhone != null) 'recipient_phone': recipientPhone,
      if (paymentToken != null) 'payment_token': paymentToken,
    };
  }

  /// Constructeur pour recréer le modèle à partir des données de Supabase (lecture)
  factory TerminalTransactionModel.fromMap(Map<String, dynamic> map) {
    return TerminalTransactionModel(
      id: map['id'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'XOF',
      actionType: map['action_type'] ?? '',
      timestamp: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      recipientPhone: map['recipient_phone'],
      paymentToken: map['payment_token'],
    );
  }
}
