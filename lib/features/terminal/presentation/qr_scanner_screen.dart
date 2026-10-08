import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatelessWidget {
  final double amount;
  const QrScannerScreen({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Scanner - ${amount.toStringAsFixed(0)} XOF"),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final String? code = barcode.rawValue;
            if (code != null) {
              // QR code détecté avec succès, on retourne le résultat
              Navigator.pop(context, code);
              break;
            }
          }
        },
      ),
    );
  }
}
