 import 'package:supabase_flutter/supabase_flutter.dart';

class PaxityRemoteDataSource {
  final SupabaseClient supabaseClient;

  PaxityRemoteDataSource({required this.supabaseClient});

  /// Crée une transaction / un lien de paiement via l'Edge Function Supabase (Proxy sécurisé Paxity)
  Future<Map<String, dynamic>> createPaymentTransaction({
    required double amount,
    required String currency,
    required String description,
  }) async {
    final response = await supabaseClient.functions.invoke(
      'paxity-proxy',
      body: {
        'amount': amount,
        'currency': currency,
        'description': description,
      },
    );

    if (response.status == 200 || response.status == 201) {
      return response.data as Map<String, dynamic>;
    } else {
      throw Exception('Erreur Paxity (${response.status}) : ${response.data}');
    }
  }
}