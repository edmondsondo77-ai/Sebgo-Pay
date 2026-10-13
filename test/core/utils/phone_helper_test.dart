import 'package:flutter_test/flutter_test.dart';
import 'package:sebgo_pay/core/utils/phone_helper.dart';

void main() {
  group('normalizeAndRoutePhoneNumber tests', () {
    // 1. Cas locaux (Burkina Faso - XOF)
    test('Doit formater correctement un numéro local burkinabé valide', () {
      final result = normalizeAndRoutePhoneNumber('70000000');
      expect(result.formattedPhone, '+22670000000');
      expect(result.countryName, 'Burkina Faso');
      expect(result.flagEmoji, '🇧🇫');
    });

    test('Doit nettoyer les espaces et le zéro initial pour le Burkina Faso',
        () {
      // Entrée avec un 0 initial + 8 chiffres = 9 chiffres au total (' 070 00 00 00 ')
      final result = normalizeAndRoutePhoneNumber(' 070 00 00 00 ');
      expect(result.formattedPhone, '+22670000000');
      expect(result.countryName, 'Burkina Faso');
    });

    // 2. Routage transfrontalier CEDEAO (Multi-devises XOF / GHS / NGN)
    test('Doit identifier correctement un numéro ivoirien (+225 - XOF)', () {
      final result = normalizeAndRoutePhoneNumber('+2250546155214');
      expect(result.formattedPhone, '+2250546155214');
      expect(result.countryName, "Côte d'Ivoire");
      expect(result.flagEmoji, '🇨🇮');
    });

    test('Doit identifier correctement un numéro ghanaéen (+233 - GHS)', () {
      final result = normalizeAndRoutePhoneNumber('+233241234567');
      expect(result.formattedPhone, '+233241234567');
      expect(result.countryName, 'Ghana');
      expect(result.flagEmoji, '🇬🇭');
    });

    test('Doit identifier correctement un numéro nigérian (+234 - NGN)', () {
      final result = normalizeAndRoutePhoneNumber('+2348012345678');
      expect(result.formattedPhone, '+2348012345678');
      expect(result.countryName, 'Nigeria');
      expect(result.flagEmoji, '🇳🇬');
    });

    // 3. Gestion des erreurs et validation de saisie
    test('Doit rejeter un numéro trop court avec une exception', () {
      expect(
        () => normalizeAndRoutePhoneNumber('5'),
        throwsA(isA<Exception>()),
      );
    });

    test('Doit rejeter une chaîne vide ou ne contenant que des espaces', () {
      expect(
        () => normalizeAndRoutePhoneNumber('   '),
        throwsA(isA<Exception>()),
      );
    });
  });
}
