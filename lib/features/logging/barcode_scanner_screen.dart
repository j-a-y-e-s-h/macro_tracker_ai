import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/food_search_service.dart';
import '../../core/theme/app_theme.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );
  bool _isScanning = true;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first.rawValue;
    if (barcode == null) return;

    setState(() => _isScanning = false);
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
    );

    try {
      final product = await ref.read(foodSearchServiceProvider).getProductByBarcode(barcode);
      
      if (mounted) {
        Navigator.pop(context); // Pop loading
        
        if (product != null) {
          Navigator.pop(context, product); // Return product to previous screen
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product not found')),
          );
          setState(() => _isScanning = true); // Resume scanning
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isScanning = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Align barcode within the frame',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Overlay Shape (Simplified version of what usually comes with scanner libs or custom made)
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 10.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final cutOutWidth = cutOutSize;
    final cutOutHeight = cutOutSize;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Draw background with cutout
    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutWidth,
      height: cutOutHeight,
    );

    final backgroundPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect)
      ..addRect(cutOutRect);

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Draw corners
    final l = borderLength;

    // Top Left
    canvas.drawLine(Offset(cutOutRect.left, cutOutRect.top), Offset(cutOutRect.left + l, cutOutRect.top), borderPaint);
    canvas.drawLine(Offset(cutOutRect.left, cutOutRect.top), Offset(cutOutRect.left, cutOutRect.top + l), borderPaint);

    // Top Right
    canvas.drawLine(Offset(cutOutRect.right, cutOutRect.top), Offset(cutOutRect.right - l, cutOutRect.top), borderPaint);
    canvas.drawLine(Offset(cutOutRect.right, cutOutRect.top), Offset(cutOutRect.right, cutOutRect.top + l), borderPaint);

    // Bottom Left
    canvas.drawLine(Offset(cutOutRect.left, cutOutRect.bottom), Offset(cutOutRect.left + l, cutOutRect.bottom), borderPaint);
    canvas.drawLine(Offset(cutOutRect.left, cutOutRect.bottom), Offset(cutOutRect.left, cutOutRect.bottom - l), borderPaint);

    // Bottom Right
    canvas.drawLine(Offset(cutOutRect.right, cutOutRect.bottom), Offset(cutOutRect.right - l, cutOutRect.bottom), borderPaint);
    canvas.drawLine(Offset(cutOutRect.right, cutOutRect.bottom), Offset(cutOutRect.right, cutOutRect.bottom - l), borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
    );
  }
}
