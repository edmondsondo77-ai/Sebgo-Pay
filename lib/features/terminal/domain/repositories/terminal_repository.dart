import '../entities/terminal_transaction_entity.dart';

abstract class TerminalRepository {
  /// Enregistre ou initialise une transaction depuis le terminal marchand
  Future<void> executeTerminalAction(TerminalTransactionEntity transaction);

  /// Vérifie le code PIN saisi par le marchand par rapport au hash sécurisé en base
  Future<bool> verifyPin(String enteredPin);
}