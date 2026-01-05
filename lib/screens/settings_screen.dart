import 'package:flutter/material.dart';
import 'package:chem_ai/core/constants/app_colors.dart';
import 'package:chem_ai/main.dart'; // To access ChemAIApp
import 'package:chem_ai/l10n/app_localizations.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(l10n.settings, style: GoogleFonts.spaceGrotesk()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('General', isDark),
          _buildLanguageOption(context, isDark),
          const SizedBox(height: 24),
          _buildSectionHeader('App Info', isDark),
          ListTile(
            title: Text(
              'Version',
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            subtitle: Text('1.0.0', style: TextStyle(color: Colors.grey)),
            leading: Icon(
              Symbols.info,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 16),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? AppColors.primary : AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
        ),
      ),
      child: ListTile(
        leading: Icon(
          Symbols.language,
          color: isDark ? Colors.white : Colors.black,
        ),
        title: Text(
          'Language',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        subtitle: Text(
          _getLanguageName(Localizations.localeOf(context).languageCode),
        ),
        trailing: Icon(
          Symbols.chevron_right,
          color: isDark ? Colors.grey : Colors.grey,
        ),
        onTap: () {
          _showLanguageBottomSheet(context);
        },
      ),
    );
  }

  void _showLanguageBottomSheet(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                'Select Language',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              _buildLanguageItem(context, 'tr', 'Türkçe'),
              _buildLanguageItem(context, 'en', 'English'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageItem(BuildContext context, String code, String name) {
    bool isSelected = Localizations.localeOf(context).languageCode == code;
    return ListTile(
      title: Text(name),
      trailing: isSelected
          ? const Icon(Symbols.check, color: AppColors.primary)
          : null,
      onTap: () {
        ChemAIApp.of(context)?.setLocale(Locale(code));
        Navigator.pop(context);
      },
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'tr':
        return 'Türkçe';
      case 'en':
        return 'English';
      default:
        return 'Türkçe'; // Default to Turkish or English
    }
  }
}
