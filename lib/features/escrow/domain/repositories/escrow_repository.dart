import '../entities/escrow_entity.dart';

abstract class EscrowRepository {
  /// Récupère les détails d'une transaction Escrow via son token unique (lien partagé)
  Future<EscrowEntity?> getEscrowDetailsByToken(String paymentToken);

  /// Traite le paiement de l'acheteur (gestion multi-pays CEDEAO / multi-devises)
  Future<void> processEscrowPayment({
    required String paymentToken,
    required String buyerPhone,
    required String buyerCountry,
    required double paidAmount,
    required String paidCurrency,
    required String paymentChannel,
  });

  /// Libère les fonds du coffre-fort vers le solde du marchand (confirmation de livraison)
  Future<void> releaseEscrowFunds(String escrowId);

  /// Récupère la transaction Escrow sécurisée via son jeton de paiement
  Future<EscrowEntity?> getEscrowByToken(String paymentToken);

  /// Autres contrats de méthode (ex: verrouillage des fonds, libération, etc.)
  Future<void> createEscrow(EscrowEntity escrow);
}
