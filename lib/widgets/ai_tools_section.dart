import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:chem_ai/core/constants/app_colors.dart';
import 'package:chem_ai/widgets/tool_card.dart';
import 'package:chem_ai/screens/safety_data_screen.dart';
import 'package:chem_ai/screens/tds_screen.dart';
import 'package:chem_ai/core/utils/navigation_utils.dart';
import 'package:chem_ai/l10n/app_localizations.dart';

/// AI Tools grid section - optimized with const constructors
class AiToolsSection extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const AiToolsSection({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverMainAxisGroup(
      slivers: [
        // Section Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.aiTools,
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
                    l10n.viewAll,
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tools Grid
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            delegate: SliverChildListDelegate([
              ToolCard(
                icon: Symbols.description,
                title: 'SDS',
                description: 'Güvenlik bilgileri',
                iconBgColor: const Color(0xFFFFEDD5),
                iconColor: const Color(0xFFEA580C),
                onTap: () {
                  NavigationUtils.pushWithSlide(
                    context,
                    const SafetyDataScreen(),
                  );
                },
              ),
              ToolCard(
                icon: Symbols.description,
                title: 'TDS',
                description: 'Teknik veri sayfası',
                iconBgColor: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF16A34A),
                onTap: () {
                  NavigationUtils.pushWithSlide(context, const TdsScreen());
                },
              ),
              ToolCard(
                icon: Symbols.chat,
                title: 'AI Chat',
                description: 'Kimya asistanı ile sohbet',
                iconBgColor: const Color(0xFFE0F2FE),
                iconColor: AppColors.primary,
                onTap: () {
                  onIndexChanged(1); // Navigate to AI Chat tab
                },
              ),
              ToolCard(
                icon: Symbols.storefront,
                title: 'Tedarikçi Bul',
                description: 'Güvenilir tedarikçilere ulaşın',
                iconBgColor: const Color(0xFFEEF2FF),
                iconColor: const Color(0xFF4F46E5),
                onTap: () {
                  onIndexChanged(2); // Navigate to supplier tab
                },
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
