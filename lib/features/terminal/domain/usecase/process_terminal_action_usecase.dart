import 'package:uuid/uuid.dart';
import '../entities/terminal_transaction_entity.dart';
import '../repositories/terminal_repository.dart';

class ProcessTerminalActionUsecase {
  final TerminalRepository repository;

  ProcessTerminalActionUsecase(this.repository);

  /// Exécute l'action du terminal et retourne le [paymentToken] si c'est un partage de lien Escrow
  Future<String?> call({
    required double amount,
    required String currency,
    required String actionType, // 'scanner', 'my_qr', 'share', 'p2p'
    String? recipientPhone,
  }) async {
    // 1. Règle métier : Interdire toute action si le montant est nul ou négatif
    if (amount <= 0) {
      throw Exception("Le montant de la transaction doit être supérieur à 0.");
    }

    // 2. Règle métier Escrow : Si l'action est 'share', on génère le jeton unique pour l'URL
    String? paymentToken;
    if (actionType == 'share') {
      paymentToken = const Uuid().v4();
    }

    // 3. Création de l'entité avec le token généré et le numéro du destinataire/marchand
    final transaction = TerminalTransactionEntity(
      amount: amount,
      currency: currency,
      actionType: actionType,
      timestamp: DateTime.now(),
      recipientPhone: recipientPhone,
      paymentToken: paymentToken, // Transmis à l'entité pour Supabase
    );

    // 4. Enregistrement en base de données via le repository
    await repository.executeTerminalAction(transaction);

    // 5. Retourne le token à la vue pour construire l'URL de partage
    return paymentToken;
  }
}
