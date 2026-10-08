import '../entities/terminal_transaction_entity.dart';
import '../repositories/terminal_repository.dart';

class ProcessTerminalActionUsecase {
  final TerminalRepository repository;

  ProcessTerminalActionUsecase(this.repository);

  Future<void> call({
    required double amount,
    required String currency,
    required String actionType,
    String?
        recipientPhone, // 1. Ajout du paramètre optionnel pour le destinataire P2P
  }) async {
    // Règle métier : Interdire toute action si le montant est nul ou négatif
    if (amount <= 0) {
      throw Exception("Le montant de la transaction doit être supérieur à 0.");
    }

    final transaction = TerminalTransactionEntity(
      // L'id n'est plus passé ici, il sera généré automatiquement par l'entité (UUID v4)
      amount: amount,
      currency: currency,
      actionType: actionType,
      timestamp: DateTime.now(),
      recipientPhone: recipientPhone, // 2. Passage du numéro à l'entité
    );

    await repository.executeTerminalAction(transaction);
  }
}
