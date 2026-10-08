import '../../domain/entities/terminal_transaction_entity.dart';

class TerminalTransactionModel extends TerminalTransactionEntity {
  TerminalTransactionModel({
    required super.id,
    required super.amount,
    required super.currency,
    required super.actionType,
    required super.timestamp,
  });

  /// Convertit le modèle en Map (JSON) pour l'insertion dans la table Supabase `transactions`.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'action_type': actionType, // Correspond à la colonne SQL action_type
      'created_at': timestamp
          .toIso8601String(), // Convertit le DateTime Dart en format texte ISO 8601 pour Supabase
    };
  }

  /// Constructeur optionnel pour recréer le modèle à partir des données de Supabase (lecture)
  factory TerminalTransactionModel.fromMap(Map<String, dynamic> map) {
    return TerminalTransactionModel(
      id: map['id'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'XOF',
      actionType: map['action_type'] ?? '',
      timestamp: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }
}
