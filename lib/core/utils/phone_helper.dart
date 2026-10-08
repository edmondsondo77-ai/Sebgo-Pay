class PhoneRoutingResult {
  final String formattedPhone;
  final String countryName;
  final String countryCode;
  final String flagEmoji;

  PhoneRoutingResult({
    required this.formattedPhone,
    required this.countryName,
    required this.countryCode,
    required this.flagEmoji,
  });
}

PhoneRoutingResult normalizeAndRoutePhoneNumber(String input,
    {String defaultCountryCode = '+226'}) {
  // 1. Nettoyage de la chaîne (garder uniquement les chiffres et le '+')
  String cleaned = input.trim().replaceAll(RegExp(r'[^\d+]'), '');

  // 2. Gestion du format international avec '00' au lieu de '+'
  if (cleaned.startsWith('00')) {
    cleaned = '+${cleaned.substring(2)}';
  }

  // Base de données exhaustive de l'Afrique de l'Ouest (CEDEAO / UEMOA + voisins)
  final Map<String, Map<String, dynamic>> countryDatabase = {
    '226': {'name': 'Burkina Faso', 'flag': '🇧🇫', 'minLength': 8},
    '225': {'name': 'Côte d\'Ivoire', 'flag': '🇨🇮', 'minLength': 10},
    '223': {'name': 'Mali', 'flag': '🇲🇱', 'minLength': 8},
    '221': {'name': 'Sénégal', 'flag': '🇸🇳', 'minLength': 9},
    '228': {'name': 'Togo', 'flag': '🇹🇬', 'minLength': 8},
    '229': {'name': 'Bénin', 'flag': '🇧🇯', 'minLength': 8},
    '227': {'name': 'Niger', 'flag': '🇳🇪', 'minLength': 8},
    '233': {'name': 'Ghana', 'flag': '🇬🇭', 'minLength': 9},
    '234': {'name': 'Nigeria', 'flag': '🇳🇬', 'minLength': 10},
    '224': {'name': 'Guinée', 'flag': '🇬🇳', 'minLength': 9},
    '232': {'name': 'Sierra Leone', 'flag': '🇸🇱', 'minLength': 8},
    '231': {'name': 'Libéria', 'flag': '🇱🇷', 'minLength': 8},
    '220': {'name': 'Gambie', 'flag': '🇬🇲', 'minLength': 7},
    '245': {'name': 'Guinée-Bissau', 'flag': '🇬🇼', 'minLength': 7},
    '238': {'name': 'Cap-Vert', 'flag': '🇨🇻', 'minLength': 7},
    '222': {'name': 'Mauritanie', 'flag': '🇲🇷', 'minLength': 8},
  };

  // 3. Sécurité absolue : rejet immédiat si le numéro est trop court (ex: "5", "12", "22")
  // Un numéro de téléphone valide en Afrique de l'Ouest a au moins 7 chiffres après nettoyage.
  if (cleaned.replaceAll('+', '').length < 7) {
    throw Exception("Le numéro de téléphone saisi est trop court ou invalide.");
  }

  // 4. Si le numéro commence par '+'
  if (cleaned.startsWith('+')) {
    String digitsWithoutPlus = cleaned.substring(1);
    for (var entry in countryDatabase.entries) {
      if (digitsWithoutPlus.startsWith(entry.key)) {
        return PhoneRoutingResult(
          formattedPhone: cleaned,
          countryName: entry.value['name'] as String,
          countryCode: '+${entry.key}',
          flagEmoji: entry.value['flag'] as String,
        );
      }
    }
  }

  // 5. Si l'utilisateur a collé un indicatif international sans le '+' (ex: 2250546155214)
  for (var entry in countryDatabase.entries) {
    String code = entry.key;
    if (cleaned.startsWith(code) && cleaned.length >= code.length + 6) {
      return PhoneRoutingResult(
        formattedPhone: '+$cleaned',
        countryName: entry.value['name'] as String,
        countryCode: '+$code',
        flagEmoji: entry.value['flag'] as String,
      );
    }
  }

  // 6. Cas par défaut (Numéro local sans indicatif, ex: 70000000 au Burkina)
  final defaultCleanCode = defaultCountryCode.replaceAll('+', '');
  final defaultInfo = countryDatabase[defaultCleanCode] ??
      {'name': 'Burkina Faso', 'flag': '🇧🇫', 'minLength': 8};

  String finalPhone = cleaned.startsWith('0') ? cleaned.substring(1) : cleaned;

  return PhoneRoutingResult(
    formattedPhone: '$defaultCountryCode$finalPhone',
    countryName: defaultInfo['name'] as String,
    countryCode: defaultCountryCode,
    flagEmoji: defaultInfo['flag'] as String,
  );
}
