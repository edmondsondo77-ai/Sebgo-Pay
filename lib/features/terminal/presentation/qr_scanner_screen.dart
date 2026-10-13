import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  final double amount;
  const QrScannerScreen({super.key, required this.amount});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanned = false; // Verrou anti-double scan[cite: 25]

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _isScanned = true;
        });
        _scannerController.stop();
        if (!mounted) return;
        Navigator.pop(context, code);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Flux Caméra Plein Écran Immersif
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // 2. Viseur de cadrage épuré au centre avec style Alipay
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF0061FF), width: 3),
                borderRadius: BorderRadius.circular(24),
                color: Colors.transparent,
              ),
            ),
          ),

          // 3. Barre supérieure flottante (Retour, Titre, Flash)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bouton retour élégant
                  CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  // Rappel du montant à flasher
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      "Encaisser : ${widget.amount.toStringAsFixed(0)} XOF",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                  // Contrôle de la torche
                  CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    child: ValueListenableBuilder<MobileScannerState>(
                      valueListenable: _scannerController,
                      builder: (context, state, child) {
                        final isTorchOn = state.torchState == TorchState.on;
                        return IconButton(
                          icon: Icon(
                            isTorchOn ? Icons.flash_on : Icons.flash_off,
                            color: isTorchOn ? Colors.yellow : Colors.white,
                            size: 20,
                          ),
                          onPressed: () => _scannerController.toggleTorch(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Message d'instruction moderne flottant en bas
          Positioned(
            bottom: 60,
            left: 32,
            right: 32,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner_rounded,
                      color: Color(0xFF0061FF), size: 20),
                  SizedBox(width: 10),
                  Text(
                    "Alignez le QR code dans le cadre",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
