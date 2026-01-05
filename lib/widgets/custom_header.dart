import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:chem_ai/core/constants/app_colors.dart';

import 'package:chem_ai/screens/profile_screen.dart';
import 'package:chem_ai/core/services/profile_service.dart';
import 'package:chem_ai/core/utils/navigation_utils.dart';

class CustomHeader extends StatelessWidget {
  final String title;
  final Widget? actionButton;
  final List<Widget>? actions;
  final TextStyle? style;
  final bool showBackButton;

  const CustomHeader({
    super.key,
    this.title = 'ChemAI',
    this.actionButton,
    this.actions,
    this.style,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (showBackButton)
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Symbols.arrow_back),
                padding: const EdgeInsets.only(right: 8),
                constraints: const BoxConstraints(),
              ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Symbols.science, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textMainDark
                    : AppColors.textMainLight,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (actions != null) ...[...actions!, const SizedBox(width: 8)],
            if (actionButton != null)
              actionButton!
            else
              FutureBuilder<Map<String, dynamic>?>(
                future: ProfileService().getProfile(),
                builder: (context, snapshot) {
                  String? avatarUrl;
                  if (snapshot.hasData && snapshot.data != null) {
                    avatarUrl = snapshot.data!['avatar_url'];
                  }

                  return GestureDetector(
                    onTap: () {
                      NavigationUtils.pushWithSlide(
                        context,
                        const ProfileScreen(),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? AppColors.surfaceDark
                            : Colors.grey[200],
                        border: Border.all(
                          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                        ),
                        image: avatarUrl != null
                            ? DecorationImage(
                                image: NetworkImage(avatarUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: avatarUrl == null
                          ? Icon(
                              Symbols.person,
                              size: 24,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            )
                          : null,
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}
