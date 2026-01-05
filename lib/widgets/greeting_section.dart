import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chem_ai/core/constants/app_colors.dart';
import 'package:chem_ai/core/services/profile_service.dart';
import 'package:chem_ai/l10n/app_localizations.dart';

/// Optimized greeting widget with caching
class GreetingSection extends StatefulWidget {
  const GreetingSection({super.key});

  @override
  State<GreetingSection> createState() => _GreetingSectionState();
}

class _GreetingSectionState extends State<GreetingSection> 
    with AutomaticKeepAliveClientMixin {
  String? _cachedName;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileService().getProfile();
      if (mounted) {
        setState(() {
          _cachedName = profile?['first_name'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = _cachedName ?? 'Misafir';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        '${l10n.goodMorning} $name',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          height: 1.1,
          color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
        ),
      ),
    );
  }
}
