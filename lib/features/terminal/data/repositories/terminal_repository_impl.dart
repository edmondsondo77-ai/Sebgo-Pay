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
    final model = TerminalTransactionModel(
      id: transaction.id,
      amount: transaction.amount,
      currency: transaction.currency,
      actionType: transaction.actionType,
      timestamp: transaction.timestamp,
    );

    // Enregistrement sécurisé dans la base Supabase de SebGo Pay
    await _supabaseClient.from('transactions').insert(model.toMap());
  }
}
