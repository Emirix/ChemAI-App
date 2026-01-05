import 'package:flutter/material.dart';
import 'package:chem_ai/core/constants/app_colors.dart';

class ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String category;
  final String time;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback? onViewTap;
  final VoidCallback? onShareTap;

  const ActivityItem({
    super.key,
    required this.icon,
    required this.title,
    required this.category,
    required this.time,
    required this.iconColor,
    required this.iconBgColor,
    this.onViewTap,
    this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          if (onViewTap != null || onShareTap != null) ...[
            if (onViewTap != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.visibility_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                onPressed: onViewTap,
              ),
            if (onShareTap != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.share_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                onPressed: onShareTap,
              ),
          ] else
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
        ],
      ),
    );
  }
}
