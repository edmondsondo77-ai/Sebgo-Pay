import 'package:uuid/uuid.dart';

/// Statuts possibles du coffre-fort Escrow
enum EscrowStatus { pending, locked, completed, disputed, released, refunded }

/// Représente le coffre-fort de sécurité interopérable (16 pays CEDEAO)
class EscrowEntity {
  final String id;
  final String paymentToken; // Token unique de l'URL partagée
  final double amount; // Montant demandé par le vendeur
  final String currency; // Devise du vendeur (ex: XOF)
  final String merchantPhone; // Numéro du vendeur

  // Informations remplies lors du paiement par l'acheteur
  final String? buyerPhone; // Numéro de l'acheteur
  final String? buyerCountry; // Pays de l'acheteur (ex: 'GH', 'BF', 'NG')
  final double? paidAmount; // Montant payé dans sa monnaie locale
  final String? paidCurrency; // Devise de l'acheteur (ex: GHS, NGN)
  final String? paymentChannel; // Moyen de paiement (ex: 'MTN_GH', 'ORANGE_BF')

  final EscrowStatus status; // Statut du coffre-fort
  final DateTime createdAt;

  EscrowEntity({
    String? id,
    required this.paymentToken,
    required this.amount,
    required this.currency,
    required this.merchantPhone,
    this.buyerPhone,
    this.buyerCountry,
    this.paidAmount,
    this.paidCurrency,
    this.paymentChannel,
    this.status = EscrowStatus.pending,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();
}
