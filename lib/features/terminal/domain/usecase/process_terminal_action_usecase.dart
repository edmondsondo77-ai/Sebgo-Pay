 import 'package:uuid/uuid.dart';
import '../entities/terminal_transaction_entity.dart';
import '../repositories/terminal_repository.dart';
import '../../data/datasources/paxity_remote_datasource.dart';

class ProcessTerminalActionUsecase {
  final TerminalRepository repository;
  final PaxityRemoteDataSource paxityRemoteDataSource;

  ProcessTerminalActionUsecase({
    required this.repository,
    required this.paxityRemoteDataSource,
  });

  /// Exécute l'action du terminal et retourne le lien de paiement ou jeton Escrow[cite: 11]
  Future<String?> call({
    required double amount,
    required String currency,
    required String actionType, // 'scanner', 'my_qr', 'share', 'p2p'
  }) async {
    // 1. Règle métier : Interdire toute action si le montant est nul ou négatif
    if (amount <= 0) {
      throw Exception("Le montant de la transaction doit être supérieur à 0.");
    }

    String? paymentToken;
    String? checkoutUrl;

    // 2. Règle métier Escrow/Paxity : Si l'action est 'share', on initialise la transaction chez Paxity
    if (actionType == 'share') {
      paymentToken = const Uuid().v4();

      // Création de la transaction chez l'agrégateur Paxity Sandbox
      final response = await paxityRemoteDataSource.createPaymentTransaction(
        amount: amount,
        currency: currency,
        description: 'Paiement Marchand SebGo Pay - Ref: $paymentToken',
      );

      // Récupération du lien de paiement / checkout généré par Paxity
      checkoutUrl = response['url'] ?? response['checkout_url'] ?? response['payment_url'];
    }

    // 3. Création de l'entité propre avec le jeton de transaction[cite: 11]
    final transaction = TerminalTransactionEntity(
      amount: amount,
      currency: currency,
      actionType: actionType,
      timestamp: DateTime.now(),
      paymentToken: paymentToken,
    );

    // 4. Enregistrement local / Supabase via le repository[cite: 11]
    await repository.executeTerminalAction(transaction);

    // 5. Retourne l'URL de paiement Paxity (ou à défaut le token local)[cite: 11]
    return checkoutUrl ?? paymentToken;
  }
}