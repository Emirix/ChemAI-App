import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chem_ai/core/constants/app_colors.dart';
import 'package:chem_ai/services/favorites_service.dart';
import 'package:chem_ai/l10n/app_localizations.dart';

/// Quick reference favorites section
class QuickReferenceSection extends StatelessWidget {
  const QuickReferenceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: FavoritesService(),
      builder: (context, child) {
        final favorites = FavoritesService().favorites;
        if (favorites.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

        return SliverToBoxAdapter(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.quickReference,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        l10n.edit,
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final ref = favorites[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: _RefCard(
                        name: ref['name'],
                        cas: ref['cas'],
                        icon: ref['icon'],
                        color: ref['color'],
                        isDark: isDark,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _RefCard extends StatelessWidget {
  final String name;
  final String? cas;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _RefCard({
    required this.name,
    required this.cas,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            name,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textMainLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (cas != null)
            Text(
              cas!,
              style: GoogleFonts.firaCode(
                fontSize: 10,
                color: isDark ? Colors.grey[400] : AppColors.textSecondaryLight,
              ),
            ),
        ],
      ),
    );
  }
}
