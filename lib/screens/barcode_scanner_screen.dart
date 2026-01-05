import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:chem_ai/core/constants/app_colors.dart';
import 'dart:ui';
import 'dart:math' as math;

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> 
    with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController();
  bool _isScanCompleted = false;
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Camera View
            MobileScanner(
              controller: controller,
              onDetect: (capture) {
                if (_isScanCompleted) return;
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final String? code = barcodes.first.displayValue;
                  if (code != null) {
                    setState(() => _isScanCompleted = true);
                    Navigator.pop(context, code);
                  }
                }
              },
            ),

            // Technical Overlay
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: CustomPaint(
                  painter: ScannerOverlayPainter(
                    scanLineProgress: _scanLineAnimation,
                  ),
                ),
              ),
            ),

            // Top Drag Handle & Controls
            Positioned(
              top: 0, left: 0, right: 0,
              child: Column(
                children: [
                  // Drag Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              color: Colors.white.withOpacity(0.1),
                              child: IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Symbols.close, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          'TARAYICI',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: ValueListenableBuilder(
                              valueListenable: controller,
                              builder: (context, state, child) {
                                final torchOn = state.torchState == TorchState.on;
                                return Container(
                                  color: torchOn ? AppColors.primary.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                                  child: IconButton(
                                    onPressed: () => controller.toggleTorch(),
                                    icon: Icon(
                                      torchOn ? Symbols.flashlight_on : Symbols.flashlight_off,
                                      color: torchOn ? AppColors.primary : Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Action Panel
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 24, right: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Barkodu veya Etiketi Hizalayın',
                    style: GoogleFonts.notoSans(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: InkWell(
                          onTap: () => Navigator.pop(context, 'action:ocr'),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Symbols.auto_awesome, color: Colors.white, size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  'AI ANALİZİ BAŞLAT',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Animation<double> scanLineProgress;
  ScannerOverlayPainter({required this.scanLineProgress}) : super(repaint: scanLineProgress);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final boxWidth = width * 0.72;
    final boxHeight = boxWidth * 0.72;
    final horizontalOffset = (width - boxWidth) / 2;
    final verticalOffset = (height - boxHeight) / 2;
    final boxRect = Rect.fromLTWH(horizontalOffset, verticalOffset, boxWidth, boxHeight);

    // Dark layer outside the scanner
    final paint = Paint()..color = Colors.black.withOpacity(0.65);
    final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, width, height));
    final innerPath = Path()..addRRect(RRect.fromRectAndRadius(boxRect, const Radius.circular(24)));
    canvas.drawPath(Path.combine(PathOperation.difference, outerPath, innerPath), paint);

    // Frame (Corners)
    _drawCorners(canvas, boxRect);

    // Animated Scan Line
    final scanLineY = verticalOffset + (boxHeight * scanLineProgress.value);
    final scanLinePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.primary.withOpacity(0.0),
          AppColors.primary,
          AppColors.primary.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(horizontalOffset, scanLineY - 1, boxWidth, 2))
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(horizontalOffset + 20, scanLineY),
      Offset(horizontalOffset + boxWidth - 20, scanLineY),
      scanLinePaint,
    );

    // Glow effect for the scan line
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withOpacity(0.15),
          AppColors.primary.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(width / 2, scanLineY), radius: boxWidth / 2))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    
    canvas.drawRect(
      Rect.fromLTWH(horizontalOffset, scanLineY - 30, boxWidth, 60),
      glowPaint,
    );
  }

  void _drawCorners(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerSize = 40.0;
    const radius = 24.0;

    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + cornerSize)
        ..lineTo(rect.left, rect.top + radius)
        ..arcToPoint(Offset(rect.left + radius, rect.top), radius: const Radius.circular(radius))
        ..lineTo(rect.left + cornerSize, rect.top),
      paint,
    );

    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cornerSize, rect.top)
        ..lineTo(rect.right - radius, rect.top)
        ..arcToPoint(Offset(rect.right, rect.top + radius), radius: const Radius.circular(radius))
        ..lineTo(rect.right, rect.top + cornerSize),
      paint,
    );

    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.bottom - cornerSize)
        ..lineTo(rect.left, rect.bottom - radius)
        ..arcToPoint(Offset(rect.left + radius, rect.bottom), radius: const Radius.circular(radius), clockwise: false)
        ..lineTo(rect.left + cornerSize, rect.bottom),
      paint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cornerSize, rect.bottom)
        ..lineTo(rect.right - radius, rect.bottom)
        ..arcToPoint(Offset(rect.right, rect.bottom - radius), radius: const Radius.circular(radius), clockwise: false)
        ..lineTo(rect.right, rect.bottom - cornerSize),
      paint,
    );

    // Optional: Inner glows for corners
    final glowPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    // Repeat drawing with glow (simplified for one corner here but applied to path)
    // For brevity, just adding a small point glow
    canvas.drawCircle(Offset(rect.left + 5, rect.top + 5), 2, glowPaint);
    canvas.drawCircle(Offset(rect.right - 5, rect.top + 5), 2, glowPaint);
  }

  @override
  bool shouldRepaint(covariant ScannerOverlayPainter oldDelegate) => true;
}

