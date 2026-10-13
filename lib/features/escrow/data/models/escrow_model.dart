import '../../domain/entities/escrow_entity.dart';

class EscrowModel extends EscrowEntity {
  EscrowModel({
    super.id,
    required super.paymentToken,
    required super.amount,
    required super.currency,
    required super.merchantId,
    super.buyerPhone,
    super.buyerCountry,
    super.paidAmount,
    super.paidCurrency,
    super.paymentChannel,
    super.status,
    super.createdAt,
  });

  /// Reconstruit l'objet à partir de la réponse Supabase[cite: 35]
  factory EscrowModel.fromMap(Map<String, dynamic> map) {
    return EscrowModel(
      id: map['id'] ?? '',
      paymentToken: map['payment_token'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'XOF',
      merchantId: map['merchant_id'] ?? '',
      buyerPhone: map['buyer_phone'],
      buyerCountry: map['buyer_country'],
      paidAmount: (map['paid_amount'] as num?)?.toDouble(),
      paidCurrency: map['paid_currency'],
      paymentChannel: map['canal'],
      status: _parseStatus(map['status']),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  /// Factory alias pour compatibilité avec fromJson[cite: 35]
  factory EscrowModel.fromJson(Map<String, dynamic> json) =>
      EscrowModel.fromMap(json);

  /// Factory pour convertir une entité de Domaine en Modèle de Données[cite: 35]
  factory EscrowModel.fromEntity(EscrowEntity entity) {
    return EscrowModel(
      id: entity.id,
      paymentToken: entity.paymentToken,
      amount: entity.amount,
      currency: entity.currency,
      merchantId: entity.merchantId,
      buyerPhone: entity.buyerPhone,
      buyerCountry: entity.buyerCountry,
      paidAmount: entity.paidAmount,
      paidCurrency: entity.paidCurrency,
      paymentChannel: entity.paymentChannel,
      status: entity.status,
      createdAt: entity.createdAt,
    );
  }

  /// Convertit le modèle en Map (JSON) pour Supabase (table 'escrow')[cite: 35]
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'payment_token': paymentToken,
      'amount': amount,
      'currency': currency,
      'merchant_id': merchantId, // Liaison relationnelle propre
      'status': status.name.toUpperCase(),
      'created_at': createdAt.toIso8601String(),
      if (buyerPhone != null) 'buyer_phone': buyerPhone,
      if (buyerCountry != null) 'buyer_country': buyerCountry,
      if (paidAmount != null) 'paid_amount': paidAmount,
      if (paidCurrency != null) 'paid_currency': paidCurrency,
      if (paymentChannel != null) 'canal': paymentChannel,
    };
  }

  /// Alias pour compatibilité avec toJson[cite: 35]
  Map<String, dynamic> toJson() => toMap();

  static EscrowStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'LOCKED':
        return EscrowStatus.locked;
      case 'COMPLETED':
        return EscrowStatus.completed;
      case 'DISPUTED':
        return EscrowStatus.disputed;
      case 'RELEASED':
        return EscrowStatus.released;
      case 'REFUNDED':
        return EscrowStatus.refunded;
      default:
        return EscrowStatus.pending;
    }
  }
}
