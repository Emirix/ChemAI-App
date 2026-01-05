import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:chem_ai/core/constants/app_colors.dart';
import 'dart:ui';
import 'dart:math' as math;

class OcrScannerScreen extends StatefulWidget {
  const OcrScannerScreen({super.key});

  @override
  State<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends State<OcrScannerScreen> 
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isCapturing = false;
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final XFile image = await _controller!.takePicture();
      if (mounted) {
        Navigator.pop(context, image.path);
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

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
            // Camera Preview
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            ),

            // Technical Overlay
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: CustomPaint(
                  painter: OcrOverlayPainter(
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
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40, height: 4,
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
                          'AI ANALİZ',
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
                            child: Container(
                              color: _controller!.value.flashMode != FlashMode.off 
                                  ? AppColors.primary.withOpacity(0.2) 
                                  : Colors.white.withOpacity(0.1),
                              child: IconButton(
                                onPressed: () {
                                  final newMode = _controller!.value.flashMode == FlashMode.torch 
                                      ? FlashMode.off 
                                      : FlashMode.torch;
                                  _controller!.setFlashMode(newMode);
                                  setState(() {});
                                },
                                icon: Icon(
                                  _controller!.value.flashMode == FlashMode.torch 
                                      ? Symbols.flashlight_on 
                                      : Symbols.flashlight_off,
                                  color: _controller!.value.flashMode == FlashMode.torch 
                                      ? AppColors.primary 
                                      : Colors.white,
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

            // Shutter Button Panel
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 24, right: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(
                    'Etiket veya Yazıyı Merkeze Alın',
                    style: GoogleFonts.notoSans(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: _isCapturing 
                          ? const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                            )
                          : const Icon(Symbols.auto_awesome, color: Colors.white, size: 32),
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

class OcrOverlayPainter extends CustomPainter {
  final Animation<double> scanLineProgress;
  OcrOverlayPainter({required this.scanLineProgress}) : super(repaint: scanLineProgress);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Larger box for OCR
    final boxWidth = width * 0.82;
    final boxHeight = boxWidth * 1.1;
    final horizontalOffset = (width - boxWidth) / 2;
    final verticalOffset = (height - boxHeight) / 2 - 40;
    final boxRect = Rect.fromLTWH(horizontalOffset, verticalOffset, boxWidth, boxHeight);

    // Dark layer
    final paint = Paint()..color = Colors.black.withOpacity(0.7);
    final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, width, height));
    final innerPath = Path()..addRRect(RRect.fromRectAndRadius(boxRect, const Radius.circular(32)));
    canvas.drawPath(Path.combine(PathOperation.difference, outerPath, innerPath), paint);

    // Corners
    _drawCorners(canvas, boxRect);

    // Scan Line
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
      Offset(horizontalOffset + 30, scanLineY),
      Offset(horizontalOffset + boxWidth - 30, scanLineY),
      scanLinePaint,
    );

    // Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withOpacity(0.1),
          AppColors.primary.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(width / 2, scanLineY), radius: boxWidth / 2))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    
    canvas.drawRect(
      Rect.fromLTWH(horizontalOffset, scanLineY - 40, boxWidth, 80),
      glowPaint,
    );
  }

  void _drawCorners(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerSize = 44.0;
    const radius = 32.0;

    // TL
    canvas.drawPath(Path()..moveTo(rect.left, rect.top + cornerSize)..lineTo(rect.left, rect.top + radius)..arcToPoint(Offset(rect.left + radius, rect.top), radius: const Radius.circular(radius))..lineTo(rect.left + cornerSize, rect.top), paint);
    // TR
    canvas.drawPath(Path()..moveTo(rect.right - cornerSize, rect.top)..lineTo(rect.right - radius, rect.top)..arcToPoint(Offset(rect.right, rect.top + radius), radius: const Radius.circular(radius))..lineTo(rect.right, rect.top + cornerSize), paint);
    // BL
    canvas.drawPath(Path()..moveTo(rect.left, rect.bottom - cornerSize)..lineTo(rect.left, rect.bottom - radius)..arcToPoint(Offset(rect.left + radius, rect.bottom), radius: const Radius.circular(radius), clockwise: false)..lineTo(rect.left + cornerSize, rect.bottom), paint);
    // BR
    canvas.drawPath(Path()..moveTo(rect.right - cornerSize, rect.bottom)..lineTo(rect.right - radius, rect.bottom)..arcToPoint(Offset(rect.right, rect.bottom - radius), radius: const Radius.circular(radius), clockwise: false)..lineTo(rect.right, rect.bottom - cornerSize), paint);
  }

  @override
  bool shouldRepaint(covariant OcrOverlayPainter oldDelegate) => true;
}
