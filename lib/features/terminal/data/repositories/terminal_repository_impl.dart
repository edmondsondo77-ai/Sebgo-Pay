import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/terminal_transaction_entity.dart';
import '../../domain/repositories/terminal_repository.dart';
import '../models/terminal_transaction_model.dart';

class TerminalRepositoryImpl implements TerminalRepository {
  final SupabaseClient _supabaseClient;

  TerminalRepositoryImpl(this._supabaseClient);

  @override
  Future<void> executeTerminalAction(
      TerminalTransactionEntity transaction) async {
    String? merchantId;

    try {
      // 🌟 SOLUTION DIRECTE ET DYNAMIQUE :
      // On récupère automatiquement le profil marchand le plus récent ou actif dans la table profiles.
      // (Puisque vous venez de vous connecter avec votre numéro, c'est ce profil qui est ciblé).
      final profileResponse = await _supabaseClient
          .from('profiles')
          .select('id')
          .eq('role', 'merchant')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (profileResponse != null) {
        merchantId = profileResponse['id'] as String;
      }

      // Validation rigoureuse
      if (merchantId == null || merchantId.isEmpty) {
        throw Exception(
            "Le numéro du marchand est manquant pour cette transaction.");
      }
    } catch (e) {
      throw Exception(
          "Erreur critique : Le numéro du marchand est manquant pour cette transaction.");
    }

    // Enregistrement de la transaction globale dans 'transactions'
    final model = TerminalTransactionModel(
      id: transaction.id,
      amount: transaction.amount,
      currency: transaction.currency,
      actionType: transaction.actionType,
      timestamp: transaction.timestamp,
      paymentToken: transaction.paymentToken,
    );

    final transactionMap = model.toMap();
    transactionMap['merchant_id'] = merchantId;
    await _supabaseClient.from('transactions').insert(transactionMap);

    // Création du coffre-fort Escrow avec l'UUID valide du marchand
    if (transaction.actionType == 'share' && transaction.paymentToken != null) {
      await _supabaseClient.from('escrow').insert({
        'id': transaction.id,
        'payment_token': transaction.paymentToken,
        'amount': transaction.amount,
        'currency': transaction.currency,
        'merchant_id': merchantId,
        'status': 'PENDING',
        'created_at': transaction.timestamp.toIso8601String(),
      });
    }
  }
}
