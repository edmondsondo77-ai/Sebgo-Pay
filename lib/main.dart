import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sebgo_pay/features/terminal/presentation/merchant_terminal_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Supabase avec vos clés officielles
  await Supabase.initialize(
    url: 'https://ectruwhkrwnnzmpnyiue.supabase.co',
    anonKey: 'sb_publishable_F1-nihDsVcCYFLfPcjImog_zXldZjew',
  );

  runApp(const SebGoApp());
}

class SebGoApp extends StatefulWidget {
  const SebGoApp({super.key});

  @override
  State<SebGoApp> createState() => _SebGoAppState();
}

class _SebGoAppState extends State<SebGoApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = (prefs.getBool("sebgo_dark_mode") ?? false)
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  void toggleTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final bool isDark = mode == ThemeMode.dark;
    await prefs.setBool("sebgo_dark_mode", isDark);
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sebgo Pay',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue, // Teinte Alipay / Professionnelle
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      builder: (context, child) {
        return Material(
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: PinLockScreen(onThemeChanged: toggleTheme, currentMode: _themeMode),
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
      _bio();
    });
  }

  Future<void> _bio() async {
    if (_isAuthenticating) return;
    try {
      setState(() => _isAuthenticating = true);
      bool canCheck =
          await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (canCheck) {
        bool authenticated = await _auth.authenticate(
          localizedReason: 'Authentification requise pour ouvrir SebGo',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
            useErrorDialogs: true,
          ),
        );
        if (authenticated && mounted) {
          _enter();
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

  void _enter() {
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
        _enter();
      } else {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _pin = "");
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? Colors.grey.shade900
          : const Color(0xFF0061FF), // Bleu Alipay
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
                          onPressed: _bio,
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
