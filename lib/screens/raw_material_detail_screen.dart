import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:chem_ai/core/constants/app_colors.dart';
import 'package:chem_ai/services/api_service.dart';
import 'package:chem_ai/services/favorites_service.dart';
import 'package:chem_ai/widgets/custom_header.dart';

import 'package:chem_ai/screens/safety_data_screen.dart';
import 'package:chem_ai/screens/chat_screen.dart';
import 'package:chem_ai/screens/supplier_search_screen.dart';
import 'package:chem_ai/core/utils/navigation_utils.dart';
import 'package:shimmer/shimmer.dart';
import 'package:chem_ai/core/utils/language_utils.dart';

class RawMaterialDetailScreen extends StatefulWidget {
  final String productName;

  const RawMaterialDetailScreen({super.key, required this.productName});

  @override
  State<RawMaterialDetailScreen> createState() =>
      _RawMaterialDetailScreenState();
}

class _RawMaterialDetailScreenState extends State<RawMaterialDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    // _loadData() moved to didChangeDependencies because it uses Localizations
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_data == null && _error == null) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      final language = LanguageUtils.getLanguageString(context);
      final data = await _apiService.getRawMaterialDetails(
        widget.productName,
        language,
      );
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Symbols.arrow_back,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: CustomHeader(
                      actions: [
                        if (!_isLoading && _data != null)
                          AnimatedBuilder(
                            animation: FavoritesService(),
                            builder: (context, child) {
                              final isFav = FavoritesService().isFavorite(
                                _data!['chemicalName'] ?? widget.productName,
                              );
                              return IconButton(
                                icon: Icon(
                                  isFav ? Symbols.favorite : Symbols.favorite,
                                  color: isFav
                                      ? Colors.red
                                      : (isDark ? Colors.white : Colors.black),
                                  fill: isFav ? 1 : 0,
                                ),
                                onPressed: () {
                                  FavoritesService().toggleFavorite(
                                    _data!['chemicalName'] ??
                                        widget.productName,
                                    _data!['casNumber'] ?? '',
                                  );
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(child: _buildContent(isDark)),

            // Bottom Actions
            if (!_isLoading && _data != null) _buildBottomActions(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return _buildSkeleton(isDark);
    }

    if (_error != null || _data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Symbols.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Veri yüklenemedi: ${_error ?? "Bilinmeyen hata"}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    final basicInfo = _data!['basicInfo'] ?? {};
    final safety = _data!['safetySummary'] ?? {};
    final properties = _data!['physicalProperties'] as List<dynamic>? ?? [];
    // final storage = _data!['storageInfo'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero
          Text(
            _data!['chemicalName'] ?? widget.productName,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
              height: 1.1,
            ),
          ),
          if (_data!['synonyms'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _data!['synonyms'],
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),

          const SizedBox(height: 16),

          Row(
            children: [
              if (_data!['casNumber'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Symbols.tag, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Text(
                        'CAS: ${_data!['casNumber']}',
                        style: TextStyle(
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Basic Info Card
          _buildCard(
            isDark: isDark,
            title: 'Temel Bilgiler',
            icon: Symbols.info,
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              children: [
                _buildInfoItem('FORMÜL', basicInfo['formula'], isDark),
                _buildInfoItem(
                  'MOL. AĞIRLIK',
                  basicInfo['molecularWeight'],
                  isDark,
                ),
                _buildInfoItem('GÖRÜNÜM', basicInfo['appearance'], isDark),
                _buildInfoItem('SAFLIK', basicInfo['purityGrade'], isDark),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Safety Card
          _buildCard(
            isDark: isDark,
            title: 'Güvenlik & Elleçleme',
            icon: Symbols.health_and_safety,
            iconColor: Colors.orange,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (safety['dangerDescription'] != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.orange[50],
                      border: Border(
                        left: BorderSide(color: Colors.orange, width: 4),
                      ),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      safety['dangerDescription'],
                      style: TextStyle(
                        color: isDark ? Colors.orange[200] : Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (safety['hazards'] != null) ...[
                  Text('TEHLİKELER', style: _labelStyle),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (safety['hazards'] as List)
                        .map<Widget>(
                          (h) => Chip(
                            label: Text(h.toString()),
                            backgroundColor: isDark
                                ? Colors.red.withOpacity(0.2)
                                : Colors.red[50],
                            labelStyle: TextStyle(
                              color: isDark ? Colors.red[200] : Colors.red[800],
                            ),
                            avatar: Icon(
                              Symbols.warning,
                              size: 18,
                              color: isDark ? Colors.red[200] : Colors.red[800],
                            ),
                            side: BorderSide.none,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                if (safety['ppEs'] != null) ...[
                  Text('GEREKLİ KKD', style: _labelStyle),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (safety['ppEs'] as List)
                        .map<Widget>(
                          (p) => Chip(
                            label: Text(p.toString()),
                            backgroundColor: isDark
                                ? Colors.grey[800]
                                : Colors.grey[100],
                            labelStyle: TextStyle(
                              color: isDark
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                            ),
                            side: BorderSide.none,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Physical Properties
          _buildCard(
            isDark: isDark,
            title: 'Fiziksel Özellikler',
            icon: Symbols.science,
            child: Column(
              children: properties
                  .map<Widget>(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            flex: 2,
                            child: Text(
                              p['label'] ?? '',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: Text(
                              p['value'] ?? '',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 80), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildBottomActions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Symbols.search,
                  label: 'Tedarikçi Bul',
                  color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
                  textColor: isDark ? Colors.white : Colors.black,
                  onTap: () {
                    NavigationUtils.pushWithSlide(
                      context,
                      SupplierSearchScreen(initialQuery: widget.productName),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Symbols.chat,
                  label: 'AI Asistan',
                  color: AppColors.primary,
                  textColor: Colors.white,
                  onTap: () {
                    // Navigate to Chat, perhaps passing context
                    NavigationUtils.pushWithSlide(
                      context,
                      ChatScreen(initialMessage: widget.productName),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            // Full width
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Symbols.safety_check),
              label: const Text('MSDS Güvenlik Bilgi Formu'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: isDark ? Colors.white : Colors.black,
                side: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              onPressed: () {
                // Navigate to SafetyDataScreen, ideally pre-filling the search
                NavigationUtils.pushWithSlide(
                  context,
                  SafetyDataScreen(initialQuery: widget.productName),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required Widget child,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor ?? AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String? value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 4),
        Text(
          value ?? '-',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSkeleton(bool isDark) {
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title skeleton
            Container(
              width: 250,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 150,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            // CAS Chip skeleton
            Container(
              width: 120,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 24),

            // Basic Info Card Skeleton
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            // Safety Card Skeleton
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            // Poperties Card Skeleton
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const TextStyle _labelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Colors.grey,
    letterSpacing: 0.5,
  );
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
