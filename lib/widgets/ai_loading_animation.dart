import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'dart:math' as math;
import '../core/constants/app_colors.dart';

enum AiLoadingType { ocr, search }

class AiLoadingAnimation extends StatefulWidget {
  final String message;
  final bool isDark;
  final AiLoadingType type;

  const AiLoadingAnimation({
    super.key,
    this.message = 'AI tarafından analiz ediliyor...',
    this.isDark = true,
    this.type = AiLoadingType.ocr,
  });

  @override
  State<AiLoadingAnimation> createState() => _AiLoadingAnimationState();
}

class _AiLoadingAnimationState extends State<AiLoadingAnimation>
    with TickerProviderStateMixin {
  // Common controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // OCR specific
  late AnimationController _scannerController;
  late Animation<double> _scannerAnimation;
  late AnimationController _dataPointsController;

  // Search specific
  late AnimationController _orbController;
  late AnimationController _moleculesController;

  final List<Offset> _dataPoints = List.generate(
    15,
    (index) => Offset(
      math.Random().nextDouble(),
      math.Random().nextDouble(),
    ),
  );

  @override
  void initState() {
    super.initState();

    // Fade in animation for the whole widget
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // Initialize OCR animations
    _scannerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _scannerAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _scannerController, curve: Curves.easeInOut),
    );
    _dataPointsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Initialize Search animations
    _orbController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _moleculesController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    if (widget.type == AiLoadingType.ocr) {
      _scannerController.repeat(reverse: true);
      _dataPointsController.repeat();
    } else {
      _orbController.repeat(reverse: true);
      _moleculesController.repeat();
    }

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scannerController.dispose();
    _dataPointsController.dispose();
    _orbController.dispose();
    _moleculesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        ),
        child: Stack(
          children: [
            _buildGridBackground(),
            if (widget.type == AiLoadingType.ocr) ...[
              ...List.generate(_dataPoints.length, (index) => _buildDataPoint(index)),
              _buildOcrView(),
            ] else
              _buildSearchView(),
          ],
        ),
      ),
    );
  }

  // --- COMMON WIDGETS ---

  Widget _buildGridBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: GridPainter(
          color: AppColors.primary.withOpacity(widget.isDark ? 0.05 : 0.1),
        ),
      ),
    );
  }

  Widget _buildMessageSection({required String submessage, required IconData subIcon}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            widget.message,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: widget.isDark ? Colors.white : AppColors.textMainLight,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(subIcon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              submessage,
              style: GoogleFonts.notoSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: widget.isDark ? Colors.grey[400] : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: widget.type == AiLoadingType.ocr ? _dataPointsController : _moleculesController,
          builder: (context, child) {
            final anim = widget.type == AiLoadingType.ocr ? _dataPointsController : _moleculesController;
            final progress = (anim.value + (index * 0.33)) % 1.0;
            final isHighlight = progress > 0.3 && progress < 0.6;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isHighlight ? AppColors.primary : AppColors.primary.withOpacity(0.2),
                boxShadow: isHighlight ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ] : null,
              ),
            );
          },
        );
      }),
    );
  }

  // --- OCR VIEW ---

  Widget _buildOcrView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                   Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withOpacity(0.0),
                          AppColors.primary.withOpacity(0.02),
                          AppColors.primary.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                  ...List.generate(5, (index) => _buildAnalysisBox(index)),
                  AnimatedBuilder(
                    animation: _scannerAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: 280 * _scannerAnimation.value,
                        left: 0, right: 0,
                        child: Column(
                          children: [
                            Container(
                              height: 2,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                boxShadow: [
                                  BoxShadow(color: AppColors.primary.withOpacity(0.8), blurRadius: 15, spreadRadius: 2),
                                ],
                              ),
                            ),
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: _scannerController.status == AnimationStatus.forward ? Alignment.bottomCenter : Alignment.topCenter,
                                  end: _scannerController.status == AnimationStatus.forward ? Alignment.topCenter : Alignment.bottomCenter,
                                  colors: [AppColors.primary.withOpacity(0.15), AppColors.primary.withOpacity(0.0)],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  _buildCorners(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 60),
          _buildMessageSection(submessage: 'Görüntü İşleniyor...', subIcon: Symbols.memory),
          const SizedBox(height: 32),
          _buildProgressDots(),
        ],
      ),
    );
  }

  Widget _buildDataPoint(int index) {
    final pos = _dataPoints[index];
    return AnimatedBuilder(
      animation: _dataPointsController,
      builder: (context, child) {
        final cycleProgress = (_dataPointsController.value + (index * 0.1)) % 1.0;
        final opacity = math.max(0.0, 1.0 - (cycleProgress * 2)).clamp(0.0, 0.4);
        final scale = 0.5 + (cycleProgress * 0.5);
        if (opacity < 0.01) return const SizedBox.shrink();
        return Positioned(
          left: MediaQuery.of(context).size.width * pos.dx,
          top: MediaQuery.of(context).size.height * pos.dy,
          child: Transform.scale(scale: scale, child: Icon(Symbols.adjust, size: 12, color: AppColors.primary.withOpacity(opacity))),
        );
      },
    );
  }

  Widget _buildAnalysisBox(int index) {
    final random = math.Random(index * 133);
    final width = 40.0 + random.nextDouble() * 80;
    final height = 20.0 + random.nextDouble() * 40;
    final left = random.nextDouble() * (280 - width);
    final top = random.nextDouble() * (280 - height);

    return AnimatedBuilder(
      animation: _scannerAnimation,
      builder: (context, child) {
        final laserTop = 280 * _scannerAnimation.value;
        final isNearLaser = (laserTop - top).abs() < 30;
        final opacity = isNearLaser ? 0.3 : 0.05;

        return Positioned(
          left: left,
          top: top,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: width,
            height: height,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary.withOpacity(opacity), width: 1),
              color: AppColors.primary.withOpacity(opacity * 0.1),
            ),
            child: isNearLaser ? _buildSmallCornerDots() : null,
          ),
        );
      },
    );
  }

  Widget _buildSmallCornerDots() {
    return Stack(
      children: [
        Positioned(top: 0, left: 0, child: _dot()),
        Positioned(top: 0, right: 0, child: _dot()),
        Positioned(bottom: 0, left: 0, child: _dot()),
        Positioned(bottom: 0, right: 0, child: _dot()),
      ],
    );
  }

  Widget _dot() => Container(width: 2, height: 2, color: AppColors.primary);

  Widget _buildCorners() {
    const size = 30.0;
    const thickness = 3.0;
    final color = AppColors.primary.withOpacity(0.6);
    return Stack(
      children: [
        Positioned(top: 0, left: 0, child: Container(width: size, height: size, decoration: BoxDecoration(border: Border(top: BorderSide(color: color, width: thickness), left: BorderSide(color: color, width: thickness))))),
        Positioned(top: 0, right: 0, child: Container(width: size, height: size, decoration: BoxDecoration(border: Border(top: BorderSide(color: color, width: thickness), right: BorderSide(color: color, width: thickness))))),
        Positioned(bottom: 0, left: 0, child: Container(width: size, height: size, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: color, width: thickness), left: BorderSide(color: color, width: thickness))))),
        Positioned(bottom: 0, right: 0, child: Container(width: size, height: size, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: color, width: thickness), right: BorderSide(color: color, width: thickness))))),
      ],
    );
  }

  // --- SEARCH VIEW ---

  Widget _buildSearchView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Molecular Search Animation
          SizedBox(
            width: 300,
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer rotating ring
                AnimatedBuilder(
                  animation: _moleculesController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _moleculesController.value * 2 * math.pi,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.1),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Stack(
                          children: [
                            _buildOrbitingDataPoint(0, 110),
                            _buildOrbitingDataPoint(math.pi / 2, 110),
                            _buildOrbitingDataPoint(math.pi, 110),
                            _buildOrbitingDataPoint(3 * math.pi / 2, 110),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                // Middle counter-rotating ring
                AnimatedBuilder(
                  animation: _moleculesController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: -_moleculesController.value * 2 * math.pi,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                             _buildOrbitingAtom(math.pi / 4, 80),
                             _buildOrbitingAtom(5 * math.pi / 4, 80),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Central Pulse Orb
                AnimatedBuilder(
                  animation: _orbController,
                  builder: (context, child) {
                    final scale = 0.9 + (_orbController.value * 0.2);
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.6),
                              AppColors.primary.withOpacity(0.0),
                            ],
                            stops: const [0.2, 0.6, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Symbols.science,
                          size: 40,
                          color: Colors.white,
                          fill: 1,
                        ),
                      ),
                    );
                  },
                ),
                
                // DNA/Chemical Helix particles
                ...List.generate(8, (index) => _buildHelixParticle(index)),
              ],
            ),
          ),

          const SizedBox(height: 40),
          _buildMessageSection(submessage: 'Veri Tabanı taranıyor...', subIcon: Symbols.database),
          const SizedBox(height: 32),
          _buildProgressDots(),
        ],
      ),
    );
  }

  Widget _buildOrbitingDataPoint(double angle, double radius) {
    return Positioned(
      left: radius + math.cos(angle) * radius - 8,
      top: radius + math.sin(angle) * radius - 8,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildOrbitingAtom(double angle, double radius) {
    return Positioned(
      left: radius + math.cos(angle) * radius - 12,
      top: radius + math.sin(angle) * radius - 12,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.surfaceDark : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: const Icon(Symbols.bolt, size: 14, color: AppColors.primary),
      ),
    );
  }

  Widget _buildHelixParticle(int index) {
    return AnimatedBuilder(
      animation: _moleculesController,
      builder: (context, child) {
        final progress = (_moleculesController.value + (index / 8)) % 1.0;
        final angle = progress * 2 * math.pi;
        final radius = 120.0 + math.sin(progress * 4 * math.pi) * 20;
        final x = math.cos(angle) * radius;
        final y = math.sin(angle) * radius;
        final size = 4.0 + math.sin(progress * 2 * math.pi).abs() * 4;

        return Transform.translate(
          offset: Offset(x, y),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(1.0 - progress),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1;
    const spacing = 30.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}


