import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sebgo_pay/features/terminal/presentation/merchant_terminal_controller.dart';
import 'package:sebgo_pay/features/escrow/presentation/escrow_payment_screen.dart';
import 'package:sebgo_pay/features/auth/presentation/screens/merchant_onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  await Supabase.initialize(
    url: 'https://ectruwhkrwnnzmpnyiue.supabase.co',
    anonKey: 'sb_publishable_F1-nihDsVcCYFLfPcjImog_zXldZjew',
  );

  final prefs = await SharedPreferences.getInstance();
  final bool isDark = prefs.getBool("sebgo_dark_mode") ?? false;
  runApp(SebGoApp(initialThemeMode: isDark ? ThemeMode.dark : ThemeMode.light));
}

class SebGoApp extends StatefulWidget {
  final ThemeMode initialThemeMode;
  const SebGoApp({super.key, required this.initialThemeMode});

  @override
  State<SebGoApp> createState() => _SebGoAppState();
}

class _SebGoAppState extends State<SebGoApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
  }

  void toggleTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final bool isDark = mode == ThemeMode.dark;
    await prefs.setBool("sebgo_dark_mode", isDark);
    if (!mounted) return;
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final initialUri = Uri.base;
    final segments =
        initialUri.pathSegments.where((s) => s.isNotEmpty).toList();
    List<String> hashSegments = [];
    if (initialUri.fragment.isNotEmpty) {
      hashSegments = Uri.parse(initialUri.fragment)
          .pathSegments
          .where((s) => s.isNotEmpty)
          .toList();
    }
    final bool isPaymentRoute =
        (segments.isNotEmpty && segments.first == 'pay') ||
            (hashSegments.isNotEmpty && hashSegments.first == 'pay');
    final String tokenFromUrl = isPaymentRoute
        ? (segments.isNotEmpty && segments.first == 'pay' && segments.length > 1
            ? segments[1]
            : (hashSegments.length > 1 ? hashSegments[1] : ''))
        : '';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SebGo Pay',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0061FF), brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0061FF), brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      onGenerateRoute: (settings) {
        final rawName = settings.name ?? '';
        final Uri uri = Uri.parse(rawName);
        final routeSegments =
            uri.pathSegments.where((s) => s.isNotEmpty).toList();
        List<String> uriHashSegments = [];
        if (uri.fragment.isNotEmpty) {
          uriHashSegments = Uri.parse(uri.fragment)
              .pathSegments
              .where((s) => s.isNotEmpty)
              .toList();
        }
        if ((routeSegments.isNotEmpty && routeSegments.first == 'pay') ||
            (uriHashSegments.isNotEmpty && uriHashSegments.first == 'pay')) {
          final String extractedToken = routeSegments.isNotEmpty &&
                  routeSegments.first == 'pay' &&
                  routeSegments.length > 1
              ? routeSegments[1].trim()
              : (uriHashSegments.length > 1 ? uriHashSegments[1].trim() : '');
          if (extractedToken.isNotEmpty) {
            return MaterialPageRoute(
              builder: (_) => EscrowPaymentScreen(paymentToken: extractedToken),
              settings: settings,
            );
          }
        }
        return null;
      },
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: tokenFromUrl.isNotEmpty
          ? EscrowPaymentScreen(paymentToken: tokenFromUrl)
          : StreamBuilder<AuthState>(
              stream: Supabase.instance.client.auth.onAuthStateChange,
              builder: (context, snapshot) {
                final session = Supabase.instance.client.auth.currentSession;

                // Si non connecté -> Écran d'onboarding / inscription
                if (session == null) {
                  return const MerchantOnboardingScreen();
                }

                // Si connecté -> Écran de verrouillage PIN / biométrie existant[cite: 9]
                return PinLockScreen(
                  onThemeChanged: toggleTheme,
                  currentMode: _themeMode,
                );
              },
            ),
    );
  }
}

class PinLockScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentMode;
  const PinLockScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentMode,
  });
  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _pin = "";
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticateBiometrics();
    });
  }

  Future<void> _authenticateBiometrics() async {
    if (_isAuthenticating) return;
    try {
      if (!mounted) return;
      setState(() => _isAuthenticating = true);
      bool canCheck =
          await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (canCheck) {
        bool authenticated = await _auth.authenticate(
          localizedReason: 'Authentification requise pour ouvrir SebGo Pay',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
            useErrorDialogs: true,
          ),
        );
        if (authenticated && mounted) {
          _navigateToTerminal();
        }
      }
    } catch (e) {
      debugPrint('Erreur biométrique : $e');
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  void _navigateToTerminal() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MerchantTerminalController(
          onThemeChanged: widget.onThemeChanged,
          currentMode: widget.currentMode,
        ),
      ),
    );
  }

  void _onNum(int n) {
    if (_pin.length < 4) {
      setState(() => _pin += n.toString());
    }
    if (_pin.length == 4) {
      if (_pin == "1234") {
        _navigateToTerminal();
      } else {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) setState(() => _pin = "");
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.currentMode == ThemeMode.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFF0061FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "SebGo",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "FINTECH INTERNATIONALE SÉCURISÉE",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < _pin.length ? Colors.white : Colors.white24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      if (index == 9) {
                        return TextButton(
                          onPressed: () => setState(() => _pin = ""),
                          child: const Text(
                            "C",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                        );
                      }
                      if (index == 11) {
                        return IconButton(
                          onPressed: _authenticateBiometrics,
                          icon: const Icon(
                            Icons.fingerprint,
                            color: Colors.white,
                            size: 32,
                          ),
                        );
                      }
                      final int num = index == 10 ? 0 : index + 1;
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDark ? Colors.black54 : Colors.white24,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _onNum(num),
                        child: Text(
                          num.toString(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
