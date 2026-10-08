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
    // 1. Instanciation du modèle avec TOUS les champs (incluant le token et le téléphone)
    final model = TerminalTransactionModel(
      id: transaction.id,
      amount: transaction.amount,
      currency: transaction.currency,
      actionType: transaction.actionType,
      timestamp: transaction.timestamp,
      recipientPhone: transaction.recipientPhone,
      paymentToken: transaction.paymentToken,
    );

    // 2. Enregistrement dans l'historique général des transactions
    await _supabaseClient.from('transactions').insert(model.toMap());

    // 3. CRUCIAL pour l'Escrow : Si l'action est un partage de lien ('share'),
    // on crée immédiatement le coffre-fort dans la table 'escrow' avec le statut PENDING
    if (transaction.actionType == 'share' && transaction.paymentToken != null) {
      await _supabaseClient.from('escrow').insert({
        'id': transaction.id,
        'payment_token': transaction.paymentToken,
        'amount': transaction.amount,
        'currency': transaction.currency,
        'merchant_phone': transaction.recipientPhone ?? '',
        'status': 'PENDING',
        'created_at': transaction.timestamp.toIso8601String(),
      });
    }
  }
}
