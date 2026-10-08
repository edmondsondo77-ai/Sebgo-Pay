import 'package:flutter/material.dart';

class TabTerminalWidget extends StatelessWidget {
  final String amount;
  final String currency;
  final bool isDark;
  final Function(String) onPressKey;
  final VoidCallback onScanQr;
  final VoidCallback onShowMyQr;
  final VoidCallback onShareInvoice;
  final VoidCallback onSendMoneyP2P;

  const TabTerminalWidget({
    super.key,
    required this.amount,
    required this.currency,
    required this.isDark,
    required this.onPressKey,
    required this.onScanQr,
    required this.onShowMyQr,
    required this.onShareInvoice,
    required this.onSendMoneyP2P,
  });

  static const Color _kAlipayDeepBlue = Color(0xFF0061FF);
  static final RegExp _thousandsRegExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');

  String _formatDisplay(String amt) {
    if (amt == "0" || amt.isEmpty) return "0";
    return amt.replaceAllMapped(_thousandsRegExp, (Match m) => '${m[1]} ');
  }

  @override
  Widget build(BuildContext context) {
    final double parsedAmount = double.tryParse(amount) ?? 0.0;
    final bool isActionEnabled = parsedAmount > 0;

    return Material(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA),
      child: SafeArea(
        child: Center(
          child: ScrollConfiguration(
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // En-tête du montant
                    Text(
                      "MONTANT DE LA TRANSACTION",
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.1,
                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      height: 48,
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _formatDisplay(amount),
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              currency,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _kAlipayDeepBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Pavé numérique (Grille 3x4)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        childAspectRatio: 1.7,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        if (index == 9) {
                          return _buildKeyContainer(
                            onTap: () => onPressKey("C"),
                            color: Colors.red.withOpacity(isDark ? 0.15 : 0.08),
                            child: const Text(
                              "C",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                          );
                        }
                        if (index == 11) {
                          return _buildKeyContainer(
                            onTap: () => onPressKey("X"),
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F3F5),
                            child: Icon(
                              Icons.backspace_outlined,
                              color: isDark
                                  ? Colors.white70
                                  : Colors.grey.shade700,
                              size: 18,
                            ),
                          );
                        }
                        final String currentKey =
                            index == 10 ? "0" : (index + 1).toString();
                        return _buildKeyContainer(
                          onTap: () => onPressKey(currentKey),
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F3F5),
                          child: Text(
                            currentKey,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Boutons d'actions principaux
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                label: "Scanner",
                                icon: Icons.qr_code_scanner,
                                isPrimary: false,
                                onPressed: isActionEnabled ? onScanQr : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildActionButton(
                                label: "Mon QR",
                                icon: Icons.qr_code,
                                isPrimary: true,
                                onPressed: isActionEnabled ? onShowMyQr : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                label: "Partager",
                                icon: Icons.share_outlined,
                                isPrimary: false,
                                onPressed:
                                    isActionEnabled ? onShareInvoice : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildActionButton(
                                label: "Envoi d'argent",
                                icon: Icons.send_rounded,
                                isPrimary: false,
                                onPressed:
                                    isActionEnabled ? onSendMoneyP2P : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyContainer({
    required VoidCallback onTap,
    required Color color,
    required Widget child,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback? onPressed,
  }) {
    final Widget buttonContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );

    if (isPrimary) {
      return SizedBox(
        height: 42,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kAlipayDeepBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: onPressed,
          child: buttonContent,
        ),
      );
    }

    return SizedBox(
      height: 42,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white70 : _kAlipayDeepBlue,
          side: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed,
        child: buttonContent,
      ),
    );
  }
}
