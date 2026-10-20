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
     
     // 🛡️ RÈGLE FINTECH STRICTE : Récupération exclusive de l'utilisateur authentifié (auth.uid())
     final user = _supabaseClient.auth.currentUser;
     if (user == null || user.id.isEmpty) {
       throw Exception(
           "Sécurité financière : Session non authentifiée ou expirée. Veuillez vous reconnecter à votre compte SebGo Pay.");
     }
     
     // L'identifiant du marchand est strictement et uniquement l'UUID de l'utilisateur connecté[cite: 7]
     final String merchantId = user.id;
     
     // Enregistrement de la transaction globale rattachée au VRAI marchand[cite: 7]
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
     
     // Création du coffre-fort Escrow avec l'UUID rigoureux du marchand connecté[cite: 7]
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

  @override
  Future<bool> verifyPin(String enteredPin) async {
    try {
      // Appel de la fonction RPC Supabase pour comparer le PIN en clair avec le hash BCrypt
      final response = await _supabaseClient.rpc(
        'verify_merchant_pin',
        params: {'p_pin': enteredPin},
      );
      return response as bool? ?? false;
    } catch (e) {
      throw Exception("Sécurité : Impossible de vérifier le code PIN. Erreur : $e");
    }
  }
}