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
  bool _isScanned = false; // Verrou anti-double scan

  @override
  void dispose() {
    _scannerController
        .dispose(); // Libération propre des ressources de la caméra
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned)
      return; // Ignore les frames suivantes si un code a déjà été lu

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        if (!mounted) return;

        setState(() {
          _isScanned = true;
        });

        _scannerController.stop(); // Arrête le flux vidéo

        if (!mounted) return;
        Navigator.pop(context, code); // Retourne le résultat du scan
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Scanner - ${widget.amount.toStringAsFixed(0)} XOF"),
        backgroundColor: const Color(0xFF0061FF),
        foregroundColor: Colors.white,
        actions: [
          // 1. Bouton Torche / Flash (ValueListenableBuilder v4+)
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _scannerController,
              builder: (context, state, child) {
                final isTorchOn = state.torchState == TorchState.on;
                return Icon(
                  isTorchOn ? Icons.flash_on : Icons.flash_off,
                  color: isTorchOn ? Colors.yellow : Colors.white,
                );
              },
            ),
            onPressed: () => _scannerController.toggleTorch(),
          ),

          // 2. Bouton Permuter Caméra
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Flux Caméra
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // Viseur de cadrage au centre
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF0061FF), width: 4),
                borderRadius: BorderRadius.circular(16),
                color: Colors.transparent,
              ),
            ),
          ),

          // Message d'instruction
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "Alignez le QR code dans le cadre pour encaisser.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
