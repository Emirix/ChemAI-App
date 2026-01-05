import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';

class AiPromoBanner extends StatelessWidget {
  final VoidCallback? onTap;
  final bool showButton;

  const AiPromoBanner({super.key, this.onTap, this.showButton = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2563EB), // Blue-600
            Color(0xFF60A5FA), // Blue-400
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Decorative Cube/Icon
          Positioned(
            right: -20,
            bottom: -30,
            child: Transform.rotate(
              angle: -0.2, // Slight tilt
              child: Icon(
                Symbols.science, // Looks like a 3D box/structure
                size: 180,
                color: Colors.white.withOpacity(0.15),
                fill: 1.0, // Filled variant
              ),
            ),
          ),

          // Sparkle elements (Circles)
          Positioned(
            top: 20,
            right: 60,
            child: Icon(
              Symbols.auto_awesome,
              color: Colors.white.withOpacity(0.3),
              size: 24,
            ),
          ),
          Positioned(
            bottom: 40,
            right: 120,
            child: Icon(
              Symbols.auto_awesome,
              color: Colors.white.withOpacity(0.2),
              size: 16,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Symbols.smart_toy,
                        color: Colors.white,
                        size: 16,
                        weight: 600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'YAPAY ZEKA ASİSTANI',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Title
                Text(
                  'ChemAI',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 8),

                // Description
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.65,
                  child: Text(
                    'Laboratuvar analizlerinizde ve araştırmalarınızda en güçlü yardımcınız.',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),

                if (showButton) ...[
                  const SizedBox(height: 20),
                  // Plus Button
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Symbols.diamond,
                              size: 18,
                              color: Color(0xFFEAB308), // Gold color
                              fill: 1.0,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Plus Üyelik',
                              style: GoogleFonts.inter(
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
