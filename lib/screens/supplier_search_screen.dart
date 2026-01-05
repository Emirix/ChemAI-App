import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:chem_ai/core/constants/app_colors.dart';
import 'package:chem_ai/services/api_service.dart';
import 'supplier_detail_screen.dart';
import 'dart:async';

class SupplierSearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SupplierSearchScreen({super.key, this.initialQuery});

  @override
  State<SupplierSearchScreen> createState() => _SupplierSearchScreenState();
}

class _SupplierSearchScreenState extends State<SupplierSearchScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _suppliers = [];
  List<String> _availableCities = [];
  String _selectedCity = 'Tümü';
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _suppliers = []);
      return;
    }

    setState(() => _isLoading = true);

    final results = await _apiService.searchSuppliers(query);
    
    // Group results by supplier (tid)
    final Map<int, Map<String, dynamic>> groupedSuppliers = {};
    if (results != null) {
      for (var s in results) {
        final tid = s['tid'] as int?;
        if (tid == null) continue;
        
        if (!groupedSuppliers.containsKey(tid)) {
          groupedSuppliers[tid] = {
            ...s,
            'matched_products': <String>{},
          };
        }
        
        if (s['matched_product'] != null) {
          (groupedSuppliers[tid]!['matched_products'] as Set<String>).add(s['matched_product'] as String);
        }
      }
    }

    final finalSuppliers = groupedSuppliers.values.map((s) => {
      ...s,
      'matched_products': (s['matched_products'] as Set<String>).toList(),
    }).toList();
    
    // Extract unique cities from grouped results
    final cities = <String>{};
    for (var s in finalSuppliers) {
      final il = (s['il'] as String?)?.trim().toUpperCase();
      if (il != null && il.isNotEmpty) {
        cities.add(il);
      }
    }

    if (mounted) {
      setState(() {
        _suppliers = finalSuppliers;
        _availableCities = cities.toList()..sort();
        _selectedCity = 'Tümü'; // Reset filter on new search
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
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
                    controller: _searchController,
                    onChanged: _onSearchChanged,
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
                  if (_availableCities.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              label: 'Tümü',
                              isSelected: _selectedCity == 'Tümü',
                              onTap: () => setState(() => _selectedCity = 'Tümü'),
                            ),
                            ..._availableCities.map((city) => Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: _buildFilterChip(
                                    label: city,
                                    isSelected: _selectedCity == city,
                                    onTap: () =>
                                        setState(() => _selectedCity = city),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _suppliers.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'Tedarikçi aramak için yazın'
                                : 'Sonuç bulunamadı',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        )
                      : (() {
                          final filteredSuppliers = _selectedCity == 'Tümü'
                              ? _suppliers
                              : _suppliers.where((s) {
                                  final il = (s['il'] as String?)?.trim().toUpperCase();
                                  return il == _selectedCity;
                                }).toList();

                          if (filteredSuppliers.isEmpty) {
                            return Center(
                              child: Text(
                                '$_selectedCity ilinde sonuç bulunamadı',
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredSuppliers.length,
                            itemBuilder: (context, index) {
                              final supplier = filteredSuppliers[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildSupplierCard(
                                  isDark,
                                  context: context,
                                  matchedProducts:
                                      (supplier['matched_products'] as List?)
                                              ?.map((e) => e.toString())
                                              .toList() ??
                                          [],
                                  title: supplier['firma_adi'] ?? 'Firma',
                                  initials: (supplier['firma_adi'] as String?) != null
                                      ? (supplier['firma_adi'] as String).substring(0, (supplier['firma_adi'] as String).length >= 2 ? 2 : 1).toUpperCase()
                                      : '?',
                                  rating: '0.0',
                                  reviewCount: '0',
                                  location:
                                      (supplier['il'] as String?)?.toUpperCase() ?? '',
                                  description: supplier['adres'] ?? '',
                                  webUrl: supplier['web'],
                                ),
                              );
                            },
                          );
                        })(),
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
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }



  Widget _buildSupplierCard(
    bool isDark, {
    required BuildContext context,
    required List<String> matchedProducts,
    required String title,
    required String initials,
    required String rating,
    required String reviewCount,
    required String location,
    required String description,
    bool isOfficial = false,
    List<String>? features,
    IconData? icon,
    String? webUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(0),
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.primary,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          title: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade50,
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.textMainDark
                                      : AppColors.textMainLight,
                                ),
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
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[500],
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Footer Row (Action Buttons)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isOfficial)
                    Row(
                      children: [
                        const Icon(Symbols.verified,
                            size: 16, color: Colors.green),
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
                    // Show count of matched products if expanding
                    Text(
                      '${matchedProducts.length} ürün bulundu',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SupplierDetailScreen(
                                supplier: {
                                  'firma_adi': title,
                                  'il': location,
                                  'web': webUrl,
                                  'adres': description, // Using description as placeholder for full address
                                },
                                matchedProducts: matchedProducts,
                              ),
                            ),
                          );
                        },
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
                    ),
                ],
              ),
            ],
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                      color: isDark ? Colors.grey[800] : Colors.grey[200]),
                  const SizedBox(height: 8),
                  Text(
                    'BULUNAN ÜRÜNLER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: isDark
                          ? Colors.grey[400]
                          : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: matchedProducts.map((product) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.backgroundDark
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey[800]!
                                : Colors.grey[200]!,
                          ),
                        ),
                        child: Text(
                          product,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey[300]
                                : Colors.grey[800],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
