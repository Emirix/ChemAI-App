import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:chem_ai/core/constants/app_colors.dart';

class SupplierSearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SupplierSearchScreen({super.key, this.initialQuery});

  @override
  State<SupplierSearchScreen> createState() => _SupplierSearchScreenState();
}

class _SupplierSearchScreenState extends State<SupplierSearchScreen> {
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.surfaceDark : Colors.white)
                    .withOpacity(0.8),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tedarikçi Bul',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight,
                          ),
                        ),
                        Text(
                          'Güvenilir tedarikçilere ulaşın',
                          style: GoogleFonts.notoSans(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Symbols.filter_list,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar & Filter Chips
            Container(
              padding: const EdgeInsets.all(16),
              color: isDark
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
              child: Column(
                children: [
                  TextField(
                    controller: TextEditingController(
                      text: widget.initialQuery,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Kimyasal, firma veya CAS No...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                      prefixIcon: Icon(
                        Symbols.search,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'Onaylı',
                          isSelected: true,
                          icon: Symbols.verified,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(label: 'İstanbul', isSelected: false),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Lab Ekipmanları',
                          isSelected: false,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(label: '★ 4.5+', isSelected: false),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildSponsoredCard(isDark),
                  const SizedBox(height: 16),
                  _buildSupplierCard(
                    isDark,
                    title: 'Sigma-Aldrich',
                    initials: 'SA',
                    rating: '4.8',
                    reviewCount: '850',
                    category: 'Kimyasallar',
                    location: 'İstanbul, Şişli',
                    isOfficial: true,
                    description: 'Dünya çapında lider kimyasal tedarikçisi.',
                  ),
                  const SizedBox(height: 12),
                  _buildSupplierCard(
                    isDark,
                    title: 'Merck Life Science',
                    initials: 'MK',
                    rating: '4.9',
                    reviewCount: '2.1k',
                    category: 'İlaç & Kimya',
                    location: 'Ankara, Çankaya',
                    features: ['09:00 - 18:00'],
                    icon: Symbols.schedule,
                    description: 'Yaşam bilimleri alanında yenilikçi çözümler.',
                  ),
                  const SizedBox(height: 12),
                  _buildSupplierCard(
                    isDark,
                    title: 'Analitik Kimya A.Ş.',
                    initials: 'AK',
                    rating: '4.2',
                    reviewCount: '120',
                    category: 'Cihaz Bakım',
                    location: 'İzmir, Bornova',
                    features: ['Aynı Gün Kargo'],
                    icon: Symbols.local_shipping,
                    description:
                        'Analitik cihazlar ve teknik servis hizmetleri.',
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    bool isSelected = false,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsoredCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.indigo.shade900.withOpacity(0.2),
                  Colors.blue.shade900.withOpacity(0.1),
                ]
              : [Colors.indigo.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.indigo.shade800 : Colors.indigo.shade100,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'SPONSORLU',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Symbols.biotech,
                    size: 32,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LabMarketim',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Symbols.star,
                            size: 16,
                            color: Colors.amber,
                            fill: 1,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '4.9 (1.2k)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                          Text(
                            ' • Laboratuvar Sarf Malzemeleri',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Türkiye\'nin en geniş laboratuvar malzemeleri tedarikçisi. Hızlı kargo.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierCard(
    bool isDark, {
    required String title,
    required String initials,
    required String rating,
    required String reviewCount,
    required String category,
    required String location,
    required String description,
    bool isOfficial = false,
    List<String>? features,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textMainDark
                                  : AppColors.textMainLight,
                            ),
                          ),
                        ),
                        Icon(
                          Symbols.bookmark,
                          size: 20,
                          color: Colors.grey.shade300,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Symbols.star,
                          size: 14,
                          color: Colors.amber,
                          fill: 1,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$rating ($reviewCount)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                        Text(
                          ' • $category',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Symbols.location_on,
                          size: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          location,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Divider(
              height: 1,
              thickness: 1,
              color: isDark ? Colors.white10 : Colors.grey.shade50,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isOfficial)
                Row(
                  children: [
                    const Icon(Symbols.verified, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Resmi Distribütör',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.greenAccent : Colors.green,
                      ),
                    ),
                  ],
                )
              else if (features != null && features.isNotEmpty)
                Row(
                  children: [
                    if (icon != null)
                      Icon(
                        icon,
                        size: 16,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    if (icon != null) const SizedBox(width: 4),
                    Text(
                      features.first,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                )
              else
                const SizedBox(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'İncele',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
