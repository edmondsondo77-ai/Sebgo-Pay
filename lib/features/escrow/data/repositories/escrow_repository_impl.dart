import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sebgo_pay/features/escrow/domain/entities/escrow_entity.dart';
import 'package:sebgo_pay/features/escrow/domain/repositories/escrow_repository.dart';
import 'package:sebgo_pay/features/escrow/data/models/escrow_model.dart';

class EscrowRepositoryImpl implements EscrowRepository {
  final SupabaseClient supabaseClient;

  EscrowRepositoryImpl(this.supabaseClient);

  @override
  Future<EscrowEntity?> getEscrowByToken(String paymentToken) async {
    try {
      final response = await supabaseClient
          .from('escrow')
          .select()
          .eq('payment_token', paymentToken)
          .maybeSingle();

      if (response == null) return null;

      return EscrowModel.fromMap(response);
    } catch (e) {
      throw Exception("Erreur lors de la récupération de l'Escrow : $e");
    }
  }

  @override
  Future<EscrowEntity?> getEscrowDetailsByToken(String paymentToken) async {
    return getEscrowByToken(paymentToken);
  }

  @override
  Future<void> createEscrow(EscrowEntity escrow) async {
    try {
      final model = EscrowModel.fromEntity(escrow);
      await supabaseClient.from('escrow').insert(model.toMap());
    } catch (e) {
      throw Exception("Échec de la création du coffre-fort Escrow : $e");
    }
  }

  @override
  Future<void> processEscrowPayment({
    required String paymentToken,
    required String buyerPhone,
    required String buyerCountry,
    required double paidAmount,
    required String paidCurrency,
    required String paymentChannel,
  }) async {
    try {
      await supabaseClient.from('escrow').update({
        'status': 'LOCKED',
        'buyer_phone': buyerPhone,
        'buyer_country': buyerCountry,
        'paid_amount': paidAmount,
        'paid_currency': paidCurrency,
        'canal': paymentChannel,
      }).eq('payment_token', paymentToken);
    } catch (e) {
      throw Exception("Échec du traitement du paiement Escrow : $e");
    }
  }

  @override
  Future<bool> releaseEscrowFunds(String escrowId) async {
    try {
      await supabaseClient.from('escrow').update({
        'status': 'RELEASED',
      }).eq('id', escrowId);

      return true;
    } catch (e) {
      throw Exception("Échec de la libération des fonds Escrow : $e");
    }
  }
}
