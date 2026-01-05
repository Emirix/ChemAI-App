import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:chem_ai/core/constants/app_colors.dart';
import 'package:chem_ai/models/tds_data.dart';
import 'package:chem_ai/services/api_service.dart';
import 'package:chem_ai/services/pdf_service.dart';
import 'package:printing/printing.dart';
import 'package:chem_ai/widgets/custom_search_bar.dart';
import 'package:chem_ai/core/services/profile_service.dart';
import 'package:chem_ai/core/services/subscription_service.dart';
import 'package:chem_ai/services/company_service.dart';
import 'package:chem_ai/models/company.dart';
import 'package:shimmer/shimmer.dart';
import 'package:chem_ai/widgets/custom_header.dart';
import 'package:chem_ai/services/favorites_service.dart';
import 'package:chem_ai/screens/plus_membership_screen.dart';
import 'package:chem_ai/core/enums/tds_template.dart';
import 'package:chem_ai/core/utils/language_utils.dart';
import 'package:chem_ai/core/utils/navigation_utils.dart';
import 'package:chem_ai/services/view_history_service.dart';
import 'package:chem_ai/services/search_history_service.dart';
import 'package:chem_ai/l10n/app_localizations.dart';
import 'dart:typed_data';
import 'package:chem_ai/widgets/ai_loading_animation.dart';

class TdsScreen extends StatefulWidget {
  final String? initialQuery;
  const TdsScreen({super.key, this.initialQuery});

  @override
  State<TdsScreen> createState() => _TdsScreenState();
}

class _TdsScreenState extends State<TdsScreen> {
  final ApiService _apiService = ApiService();
  final PdfService _pdfService = PdfService();
  final ViewHistoryService _viewHistoryService = ViewHistoryService();
  final SearchHistoryService _searchHistoryService = SearchHistoryService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  TdsData? _tdsData;
  bool _isLoading = false;
  bool _isAiGenerating = false;
  bool _isExporting = false;
  bool _hasSearched = false;
  bool _isLoadedFromCache = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _fetchTdsData(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchTdsData(String query) async {
    setState(() {
      _isLoading = true;
      _isAiGenerating = true; // Arama başladığında animasyonu göster
      _isLoadedFromCache = false;
      _error = null;
      _hasSearched = true;
      _tdsData = null;
    });

    // Add to search history
    _searchHistoryService.addSearch(query, 'tds');

    try {
      final startTime = DateTime.now();
      
      final data = await _apiService.getTdsData(
        query,
        'Turkish',
        userId: ProfileService().userId,
      );

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('TdsScreen: API call took $duration ms');

      if (data != null) {
        final isCached = data['cached'] == true;
        
        if (isCached) {
          // Eğer cacheden geldiyse animasyonu kapatabiliriz
          setState(() {
            _isLoadedFromCache = true;
            _isAiGenerating = false;
          });
        }
      }

      setState(() {
        if (data != null) {
          _tdsData = data['data'] as TdsData;
          _viewHistoryService.addEntry(
            title: _tdsData!.productName,
            subtitle: _tdsData!.identity.casNumber,
            type: 'tds',
          );
        }
        _isLoading = false;
        _isAiGenerating = false;
        _isLoadedFromCache = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isAiGenerating = false;
        _isLoadedFromCache = false;
        _error = 'Bir hata oluştu: $e';
      });
    }
  }

  Future<void> _viewPDF() async {
    if (_tdsData == null) return;

    // Check Subscription for PDF
    final canGenerate = await SubscriptionService().canGeneratePdf();
    if (!canGenerate) {
      if (!mounted) return;
      _showUpgradeDialog(
        context,
        'Bu özellik Plus üyelik gerektirir.',
        'PDF oluşturmak ve paylaşmak için Plus\'a geçin.',
      );
      return;
    }

    // Show Company Selection Dialog first
    _searchFocusNode.unfocus();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildCompanySelectionSheet(context),
    );
  }

  void _showUpgradeDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              NavigationUtils.pushWithSlide(
                context,
                const PlusMembershipScreen(),
              );
            },
            icon: const Icon(Symbols.diamond, size: 16),
            label: const Text('Plus\'a Geç'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanySelectionSheet(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PDF Ayarları (1/2)',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'PDF üzerinde görünecek firma bilgisini seçin.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<Company>>(
            future: CompanyService().getCompanies(
              ProfileService().userId ?? '',
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final companies = snapshot.data ?? [];

              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Symbols.block, color: Colors.grey),
                    ),
                    title: const Text('Firma Bilgisi Yok (Logosuz)'),
                    onTap: () {
                      Navigator.pop(context);
                      _showTemplateSelection(context, null);
                    },
                  ),
                  const Divider(),
                  if (companies.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Kayıtlı firma bulunamadı. Profil ayarlarından firma ekleyebilirsiniz.',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ...companies.map((company) {
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          image: company.logoUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(company.logoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: company.logoUrl == null
                            ? const Icon(Symbols.business, color: Colors.grey)
                            : null,
                      ),
                      title: Text(company.companyName),
                      subtitle: Text(
                        company.address ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showTemplateSelection(context, company.toJson());
                      },
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showTemplateSelection(
    BuildContext context,
    Map<String, dynamic>? companyInfo,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildTemplateSelectionSheet(context, companyInfo),
    );
  }

  Widget _buildTemplateSelectionSheet(
    BuildContext context,
    Map<String, dynamic>? companyInfo,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Şablon Seçimi (2/2)',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'İhtiyacınıza uygun PDF formatını belirleyin.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _buildTemplateOption(
            context,
            label: 'Standart Şablon',
            desc: 'Renkli başlıklar ve düzenli tablolar.',
            icon: Symbols.article,
            color: AppColors.primary,
            isRecommended: true,
            onTap: () {
              Navigator.pop(context);
              _generateAndShowPdf(companyInfo, TdsTemplate.standard);
            },
          ),
          const SizedBox(height: 12),
          _buildTemplateOption(
            context,
            label: 'Profesyonel Şablon',
            desc: 'Kurumsal tasarım ve detaylı yerleşim.',
            icon: Symbols.award_star,
            color: Colors.purple,
            onTap: () {
              Navigator.pop(context);
              _generateAndShowPdf(companyInfo, TdsTemplate.professional);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTemplateOption(
    BuildContext context, {
    required String label,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isRecommended = false,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRecommended
                ? color
                : (isDark ? Colors.white24 : Colors.grey[300]!),
            width: isRecommended ? 2 : 1,
          ),
          color: isRecommended
              ? color.withOpacity(0.05)
              : (isDark ? Colors.white.withOpacity(0.03) : Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ÖNERİLEN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: isDark ? Colors.grey[600] : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndShowPdf(
    Map<String, dynamic>? companyInfo,
    TdsTemplate template,
  ) async {
    setState(() => _isExporting = true);

    try {
      final language = LanguageUtils.getLanguageString(context);

      final result = await _pdfService.generateTds(
        _tdsData!,
        language,
        companyInfo: companyInfo,
        template: template,
      );

      final bytes = result['bytes'] as Uint8List;
      final fileName = result['fileName'] as String;

      // Log to history as a "creation"
      _viewHistoryService.addEntry(
        title: _tdsData!.productName,
        subtitle: 'TDS Belgesi Oluşturuldu',
        type: 'tds_pdf',
        metadata: {
          'fileName': fileName,
          'cas': _tdsData!.identity.casNumber,
          'template': template.name,
        },
      );

      if (mounted) {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TDS Belgesi Hazır',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(
                    Symbols.visibility,
                    color: AppColors.primary,
                  ),
                  title: const Text('Görüntüle ve Yazdır'),
                  subtitle: const Text('PDF belgesini uygulamada açar'),
                  onTap: () {
                    Navigator.pop(context);
                    Printing.layoutPdf(
                      onLayout: (format) => bytes,
                      name: fileName,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Symbols.share, color: AppColors.primary),
                  title: const Text('Dosyayı Paylaş'),
                  subtitle: const Text('WhatsApp, E-posta vb. ile gönder'),
                  onTap: () {
                    Navigator.pop(context);
                    Printing.sharePdf(bytes: bytes, filename: fileName);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('TDS PDF Generation Error: $e');
      debugPrint('Stack Trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF oluşturma hatası: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
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
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: CustomHeader(
                title: 'TDS Sonuçları',
                showBackButton: true,
                actionButton: _tdsData == null
                    ? null
                    : AnimatedBuilder(
                        animation: FavoritesService(),
                        builder: (context, child) {
                          final isFav = FavoritesService().isFavorite(
                            _tdsData!.productName,
                          );
                          return IconButton(
                            onPressed: () {
                              FavoritesService().toggleFavorite(
                                _tdsData!.productName,
                                _tdsData!.identity.casNumber,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isFav
                                        ? 'Hızlı referanslardan kaldırıldı'
                                        : 'Hızlı referanslara eklendi',
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            icon: Icon(
                              isFav ? Symbols.favorite : Symbols.favorite,
                              color: isFav ? Colors.red : Colors.grey,
                              fill: isFav ? 1 : 0,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: isDark
                                  ? AppColors.surfaceDark
                                  : Colors.white,
                              padding: const EdgeInsets.all(10),
                            ),
                          );
                        },
                      ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CustomSearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                hintText: 'Hammadde ara...',
                onSubmitted: (query) {
                  if (query.isNotEmpty) {
                    _fetchTdsData(query);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            if (_tdsData == null && !_isLoading) _buildRecentSearches(isDark),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? (_isAiGenerating
                      ? AiLoadingAnimation(
                          message: 'Yapay zeka tarafından TDS belgesi ayarlanıyor...',
                          isDark: isDark,
                          type: AiLoadingType.search,
                        )
                      : _buildSkeletonLoading(isDark, isAi: false))
                  : _error != null
                  ? Center(child: Text(_error!))
                  : _tdsData == null
                  ? _buildEmptyState(isDark)
                  : _buildTdsContent(isDark),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _tdsData != null
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white10 : Colors.grey[200]!,
                  ),
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _viewPDF,
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Symbols.download),
                label: Text(
                  _isExporting ? 'Oluşturuluyor...' : 'PDF Oluştur & Gönder',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _hasSearched ? Symbols.search_off : Symbols.description,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _hasSearched
                ? 'Arama sonucu bulunamadı'
                : 'Hammadde seçerek TDS oluşturun',
            style: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_hasSearched) ...[
            const SizedBox(height: 8),
            Text(
              'Aradığınız ürün bir kimyasal hammadde olmayabilir\nveya veri tabanımızda henüz bulunmuyor olabilir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white38 : Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentSearches(bool isDark) {
    return FutureBuilder<List<String>>(
      future: _searchHistoryService.getRecentSearches('tds'),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final recentSearches = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Icon(
                    Symbols.history,
                    size: 16,
                    color: isDark ? Colors.white38 : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Son Aramalar',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      _searchHistoryService.clearHistory('tds').then((_) {
                        setState(() {});
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Temizle',
                      style: TextStyle(fontSize: 12, color: Colors.blue[400]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: recentSearches.map((query) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      onTap: () {
                        _searchController.text = query;
                        _fetchTdsData(query);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          query,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.grey[800],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTdsContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Section
          _buildHeroSection(isDark),
          const SizedBox(height: 16),

          // Identity Section
          _buildSection(
            icon: Symbols.fingerprint,
            title: 'Ürün Kimliği',
            child: Column(
              children: [
                _buildInfoRow(
                  'CAS Numarası',
                  _tdsData!.identity.casNumber,
                  isDark,
                ),
                _buildInfoRow(
                  'EC Numarası',
                  _tdsData!.identity.ecNumber,
                  isDark,
                ),
                _buildInfoRow(
                  'Moleküler Formül',
                  _tdsData!.identity.formula,
                  isDark,
                ),
                _buildInfoRow(
                  'Moleküler Ağırlık',
                  _tdsData!.identity.molecularWeight,
                  isDark,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Physical Properties
          _buildSection(
            icon: Symbols.science,
            title: 'Fiziksel ve Kimyasal Özellikler',
            child: Column(
              children: _tdsData!.physicalProperties.asMap().entries.map((
                entry,
              ) {
                return _buildInfoRow(
                  entry.value.label,
                  entry.value.value,
                  isDark,
                  isLast: entry.key == _tdsData!.physicalProperties.length - 1,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Technical Specs
          _buildSection(
            icon: Symbols.fact_check,
            title: 'Teknik Spesifikasyonlar',
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
              itemCount: _tdsData!.technicalSpecs.length,
              itemBuilder: (context, index) {
                final spec = _tdsData!.technicalSpecs[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        spec.label,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? Colors.grey[400]
                              : AppColors.textSecondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        spec.value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Storage Section
          _buildSection(
            icon: Symbols.inventory_2,
            title: 'Depolama ve Raf Ömrü',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._tdsData!.storageInfo.conditions.map(
                  (condition) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6.0, right: 8.0),
                          child: CircleAvatar(
                            radius: 3,
                            backgroundColor: AppColors.primary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            condition,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey[300]
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                _buildInfoRow(
                  'Raf Ömrü',
                  _tdsData!.storageInfo.shelfLife,
                  isDark,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Safety Warnings
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.red.withOpacity(0.1) : Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.red.withOpacity(0.2) : Colors.red[100]!,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Symbols.warning, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tdsData!.safetyWarnings.ghsTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _tdsData!.safetyWarnings.hazardStatement,
                        style: TextStyle(
                          color: isDark ? Colors.red[200] : Colors.red[700],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: _tdsData!.safetyWarnings.ghsLabels.map((
                          label,
                        ) {
                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceDark
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.2),
                              ),
                            ),
                            child: Icon(
                              _getGhsIcon(label),
                              size: 20,
                              color: Colors.red,
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey[200]!,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tdsData!.productName,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _tdsData!.subtitle,
                  style: TextStyle(
                    color: isDark
                        ? Colors.grey[400]
                        : AppColors.textSecondaryLight,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _tdsData!.category.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey[200]!,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                'https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/${_tdsData!.identity.casNumber != '-' ? 'name/${_tdsData!.identity.casNumber}' : 'name/${Uri.encodeComponent(_tdsData!.productName)}'}/PNG',
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Symbols.science,
                      color: Colors.grey,
                      size: 24,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
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

  Widget _buildInfoRow(
    String label,
    String value,
    bool isDark, {
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey[100]!,
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : AppColors.textSecondaryLight,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getGhsIcon(String label) {
    switch (label.toLowerCase()) {
      case 'flammable':
        return Symbols.local_fire_department;
      case 'toxic':
      case 'skull':
        return Symbols.skull;
      case 'corrosive':
        return Symbols.vibration;
      case 'health_hazard':
      case 'health_and_safety':
        return Symbols.health_and_safety;
      case 'warning':
        return Symbols.warning;
      case 'environmental':
        return Symbols.nature;
      default:
        return Symbols.help;
    }
  }

  Widget _buildSkeletonLoading(bool isDark, {bool isAi = false}) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        if (isAi)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.aiGeneratingTds,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Shimmer.fromColors(
            baseColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey[200]!,
            highlightColor: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey[50]!,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Hero Section Skeleton
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 16),

                // Sections Skeletons
                ...List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
