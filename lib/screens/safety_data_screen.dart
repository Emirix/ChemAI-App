import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:chem_ai/core/constants/app_colors.dart';
import 'package:chem_ai/widgets/custom_header.dart';
import 'package:chem_ai/widgets/custom_search_bar.dart';
import 'package:chem_ai/l10n/app_localizations.dart';
import 'package:chem_ai/models/safety_data.dart';
import 'package:chem_ai/services/api_service.dart';
import 'package:chem_ai/services/pdf_service.dart';
import 'package:chem_ai/services/view_history_service.dart';
import 'package:shimmer/shimmer.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:chem_ai/services/favorites_service.dart';
import 'package:chem_ai/core/services/profile_service.dart';
import 'package:chem_ai/core/services/subscription_service.dart';
import 'package:chem_ai/services/company_service.dart';
import 'package:chem_ai/models/company.dart';
import 'package:chem_ai/screens/plus_membership_screen.dart';
import 'package:chem_ai/core/utils/navigation_utils.dart';
import 'package:chem_ai/core/enums/msds_template.dart';
import 'package:chem_ai/core/utils/language_utils.dart';
import 'package:chem_ai/services/search_history_service.dart';
import 'package:chem_ai/widgets/ai_loading_animation.dart';

class SafetyDataScreen extends StatefulWidget {
  final String? initialQuery;

  const SafetyDataScreen({super.key, this.initialQuery});

  @override
  State<SafetyDataScreen> createState() => _SafetyDataScreenState();
}

class _SafetyDataScreenState extends State<SafetyDataScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final PdfService _pdfService = PdfService();
  final ViewHistoryService _viewHistoryService = ViewHistoryService();
  final SearchHistoryService _searchHistoryService = SearchHistoryService();
  final TextEditingController _searchController = TextEditingController();
  SafetyData? _data;
  bool _isLoading = false;
  bool _isAiGenerating = false;
  bool _isExporting = false;
  bool _hasSearched = false;
  bool _isLoadedFromCache = false;

  Future<void> _viewPDF() async {
    if (_data == null) return;

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
    FocusScope.of(context).unfocus();
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
                  // Option: No Logo / Default
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
                      _showRevisionInfoForm(context, null);
                    },
                  ),
                  const Divider(),
                  // Company Options
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
                        _showRevisionInfoForm(context, company.toJson());
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

  void _showRevisionInfoForm(
    BuildContext context,
    Map<String, dynamic>? companyInfo,
  ) {
    final versionController = TextEditingController(text: '1.0');
    final changesController = TextEditingController(text: 'İlk yayın');
    final today = DateTime.now();
    final dateController = TextEditingController(
      text:
          '${today.day.toString().padLeft(2, '0')}.${today.month.toString().padLeft(2, '0')}.${today.year}',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Revizyon Bilgileri (2/3)',
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
              'SDS belgesinin revizyon bilgilerini girin.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: versionController,
              decoration: const InputDecoration(
                labelText: 'SDS Versiyonu',
                hintText: '1.0',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: 'Revizyon Tarihi',
                hintText: 'GG.AA.YYYY',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (selectedDate != null) {
                  dateController.text =
                      '${selectedDate.day.toString().padLeft(2, '0')}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.year}';
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: changesController,
              decoration: const InputDecoration(
                labelText: 'Değişiklik Açıklaması',
                hintText: 'İlk yayın veya revizyon detayı',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showTemplateSelection(
                    context,
                    companyInfo,
                    revisionInfo: {
                      'version': versionController.text,
                      'date': dateController.text,
                      'changes': changesController.text,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Devam Et',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showTemplateSelection(
    BuildContext context,
    Map<String, dynamic>? companyInfo, {
    Map<String, String>? revisionInfo,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          _buildTemplateSelectionSheet(context, companyInfo, revisionInfo),
    );
  }

  Widget _buildTemplateSelectionSheet(
    BuildContext context,
    Map<String, dynamic>? companyInfo,
    Map<String, String>? revisionInfo,
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
                'Şablon Seçimi (3/3)',
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
            label: 'Standart Şablon (Detaylı)',
            desc: 'Renkli başlıklar, detaylı fiziksel özellikler ve tablolar.',
            icon: Symbols.article,
            color: AppColors.primary,
            isRecommended: true,
            onTap: () {
              Navigator.pop(context);
              _generateAndShowPdf(
                companyInfo,
                MsdsTemplate.standard,
                revisionInfo: revisionInfo,
              );
            },
          ),
          const SizedBox(height: 12),
          _buildTemplateOption(
            context,
            label: 'Profesyonel Şablon (Kurumsal)',
            desc:
                'QR Kod, risk etiketleri, kurumsal tasarım ve grafik ikonlar.',
            icon: Symbols.award_star,
            color: Colors.purple,
            onTap: () {
              Navigator.pop(context);
              _generateAndShowPdf(
                companyInfo,
                MsdsTemplate.professional,
                revisionInfo: revisionInfo,
              );
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
    MsdsTemplate template, {
    Map<String, String>? revisionInfo,
  }) async {
    setState(() => _isExporting = true);

    try {
      final language = LanguageUtils.getLanguageString(context);

      // Override revision info if provided by user
      SafetyData dataToUse = _data!;
      if (revisionInfo != null) {
        dataToUse = _data!.copyWith(
          revisionInformation: RevisionInformation(
            sdsVersion: revisionInfo['version'] ?? '1.0',
            revisionDate:
                revisionInfo['date'] ??
                DateTime.now().toString().substring(0, 10),
            changes: revisionInfo['changes'] ?? 'İlk yayın',
          ),
        );
      }

      final result = await _pdfService.generateMsds(
        dataToUse,
        language,
        companyInfo: companyInfo,
        template: template,
      );

      final bytes = result['bytes'] as Uint8List;
      final fileName = result['fileName'] as String;

      // Log to history as a "creation"
      _viewHistoryService.addEntry(
        title: _data!.chemicalName,
        subtitle: 'SDS Belgesi Oluşturuldu',
        type: 'msds_pdf',
        metadata: {
          'fileName': fileName,
          'cas': _data!.casNumber,
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
                  'SDS Belgesi Hazır',
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
      debugPrint('PDF Generation Error: $e');
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
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      // Use a post frame callback to ensure context is available for checks if needed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSearch(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch(String query) async {
    if (query.isEmpty) return;

    // Check Daily Limit
    final canView = await SubscriptionService().checkDailyMsdsLimit();
    if (!canView) {
      if (!mounted) return;
      _showUpgradeDialog(
        context,
        'Günlük Limit Aşıldı',
        'Günlük ücretsiz SDS görüntüleme limitinize ulaştınız. Limitsiz erişim için Plus\'a geçin.',
      );
      return;
    }

    debugPrint('SafetyDataScreen: Starting search for: $query');

    setState(() {
      _isLoading = true;
      _isAiGenerating = true; // Arama başladığında animasyonu göster
      _isLoadedFromCache = false;
      _data = null; // Clear old data
      _hasSearched = true;
    });

    try {
      final language = LanguageUtils.getLanguageString(context);

      debugPrint('SafetyDataScreen: Language: $language');
      final startTime = DateTime.now();

      // Add to search history
      _searchHistoryService.addSearch(query, 'msds');

      final result = await _apiService.getSafetyData(
        query,
        language,
        userId: ProfileService().userId,
      );

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('SafetyDataScreen: API call took $duration ms');

      if (result != null) {
        final isCached = result['cached'] == true;
        
        if (isCached) {
          // Eğer cacheden geldiyse animasyonu kapatabiliriz (zaten isLoading false olacak birazdan)
          setState(() {
            _isLoadedFromCache = true;
            _isAiGenerating = false;
          });
        }
      }

      if (mounted) {
        setState(() {
          if (result != null) {
            _data = result['data'] as SafetyData;
            _viewHistoryService.addEntry(
              title: _data!.chemicalName,
              subtitle: _data!.casNumber,
              type: 'msds',
            );
          } else {
            debugPrint('SafetyDataScreen: No result found or error occurred.');
          }
        });
      }
    } catch (e) {
      debugPrint('SafetyDataScreen: Search error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
      }
    } finally {
      debugPrint(
        'SafetyDataScreen: Search completed, setting isLoading = false',
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isAiGenerating = false;
          _isLoadedFromCache = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: CustomHeader(
                title: l10n.safetyData,
                actionButton: _data == null
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Favorites Button
                          AnimatedBuilder(
                            animation: FavoritesService(),
                            builder: (context, child) {
                              final isFav = FavoritesService().isFavorite(
                                _data!.chemicalName,
                              );
                              return IconButton(
                                onPressed: () {
                                  FavoritesService().toggleFavorite(
                                    _data!.chemicalName,
                                    _data!.casNumber,
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
                        ],
                      ),
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CustomSearchBar(
                controller: _searchController,
                onSubmitted: _handleSearch,
                onScannerTap: () {},
              ),
            ),

            const SizedBox(height: 8),

            if (_data == null && !_isLoading) _buildRecentSearches(isDark),

            const SizedBox(height: 8),

            // Tab Bar
            if (_data != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.primary,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                  labelStyle: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  indicatorPadding: const EdgeInsets.all(4),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: 'Özet'), // Summary (1,2,9)
                    Tab(text: 'Güvenlik'), // Safety (4,5,6,7,8)
                    Tab(text: 'Teknik'), // Technical (10-15)
                  ],
                ),
              ),

            Expanded(
              child: _isLoading
                  ? (_isAiGenerating
                      ? AiLoadingAnimation(
                          message: 'Yapay zeka tarafından SDS belgesi ayarlanıyor...',
                          isDark: isDark,
                          type: AiLoadingType.search,
                        )
                      : _buildSkeletonLoading(isDark, isAi: false))
                  : _data == null
                  ? _buildEmptyState(isDark, l10n)
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSummaryTab(isDark, l10n),
                        _buildSafetyTab(isDark, l10n),
                        _buildTechnicalTab(isDark, l10n),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _data != null
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
                    : const Icon(Symbols.picture_as_pdf),
                label: Text(
                  _isExporting ? 'Hazırlanıyor...' : 'PDF Oluştur & Gönder',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  elevation: 0,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState(bool isDark, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _hasSearched ? Symbols.search_off : Symbols.search_check,
            size: 80,
            color: isDark ? Colors.white24 : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _hasSearched ? 'Arama sonucu bulunamadı' : l10n.searchHint,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              color: isDark ? Colors.white60 : Colors.grey[600],
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
      future: _searchHistoryService.getRecentSearches('msds'),
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
                      _searchHistoryService.clearHistory('msds').then((_) {
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
                        _handleSearch(query);
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

  Widget _buildSummaryTab(bool isDark, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header Info (Sec 1: ID)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _data!.chemicalName,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'CAS: ${_data!.casNumber}',
                      style: GoogleFonts.firaCode(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey[400]
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  'https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/${_data!.casNumber.isNotEmpty ? 'name/${_data!.casNumber}' : 'name/${Uri.encodeComponent(_data!.chemicalName)}'}/PNG',
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }
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
                    debugPrint('Molecule image error: $error');
                    return const Center(
                      child: Icon(
                        Symbols.science,
                        color: Colors.grey,
                        size: 32,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // AI Alert (Risk)
        if (_data!.riskAlert.hasAlert) _buildAIRiskAlert(isDark, l10n),
        if (_data!.riskAlert.hasAlert) const SizedBox(height: 24),

        // GHS Hazards (Sec 2)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey[100]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('TEHLİKE TANIMLAMA (Bölüm 2)', isDark),
              const SizedBox(height: 16),
              Center(
                child: Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: _data!.hazards
                      .map(
                        (h) =>
                            _buildGHSDiamond(_getHazardIcon(h.type), h.label),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Properties Snippet (Sec 9)
        _buildInfoExpansionTile(
          title: 'Fiziksel Özellikler (Bölüm 9)',
          icon: Symbols.info,
          isDark: isDark,
          children: _data!.properties
              .take(5) // Show top 5
              .map((p) => _buildDetailRow(p.label, p.value))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSafetyTab(bool isDark, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // First Aid (Sec 4) - Top priority
        _buildEmergencyCard(
          title: 'İlk Yardım (Bölüm 4)',
          icon: Symbols.medical_services,
          color: Colors.red,
          isDark: isDark,
          steps: _data!.firstAid,
        ),
        const SizedBox(height: 16),

        // Firefighting (Sec 5)
        _buildEmergencyCard(
          title: 'Yangınla Mücadele (Bölüm 5)',
          icon: Symbols.local_fire_department,
          color: Colors.orange,
          isDark: isDark,
          steps: _data!.firefighting,
        ),
        const SizedBox(height: 16),

        // Accidental Release (Sec 6)
        _buildInfoExpansionTile(
          title: 'Kaza Sonucu Yayılma (Bölüm 6)',
          icon: Symbols.warning,
          isDark: isDark,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _data!.accidentalRelease,
                style: GoogleFonts.notoSans(fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Handling & Storage (Sec 7)
        _buildInfoExpansionTile(
          title: 'Kullanım ve Depolama (Bölüm 7)',
          icon: Symbols.inventory,
          isDark: isDark,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kullanım:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _data!.handling,
                    style: GoogleFonts.notoSans(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Depolama:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _data!.storage,
                    style: GoogleFonts.notoSans(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // PPE (Sec 8)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey[100]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'KKD / MARUZİYET KONTROLLERİ (Bölüm 8)',
                isDark,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _data!.ppe
                    .map((p) => _buildPPEChip(_getPPEIcon(p.type), p.label))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicalTab(bool isDark, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stability (Sec 10)
        _buildSectionCard(
          isDark,
          title: 'Kararlılık & Tepkime (Bölüm 10)',
          icon: Symbols.science,
          content: _data!.stabilityAndReactivity,
        ),
        const SizedBox(height: 12),

        // Toxicological (Sec 11)
        _buildSectionCard(
          isDark,
          title: 'Toksikolojik Bilgiler (Bölüm 11)',
          icon: Symbols.coronavirus,
          content: _data!.toxicologicalInformation,
        ),
        const SizedBox(height: 12),

        // Ecological (Sec 12)
        _buildSectionCard(
          isDark,
          title: 'Ekolojik Bilgiler (Bölüm 12)',
          icon: Symbols.eco,
          content: _data!.ecologicalInformation,
        ),
        const SizedBox(height: 12),

        // Disposal (Sec 13)
        _buildSectionCard(
          isDark,
          title: 'Bertaraf Bilgileri (Bölüm 13)',
          icon: Symbols.delete,
          content: _data!.disposalConsiderations,
        ),
        const SizedBox(height: 12),

        // Transport (Sec 14)
        _buildSectionCard(
          isDark,
          title: 'Taşımacılık Bilgileri (Bölüm 14)',
          icon: Symbols.local_shipping,
          content: _data!.transportInformation,
        ),
        const SizedBox(height: 12),

        // Regulatory (Sec 15)
        _buildSectionCard(
          isDark,
          title: 'Mevzuat Bilgileri (Bölüm 15)',
          icon: Symbols.gavel,
          content: _data!.regulatoryInformation,
        ),
      ],
    );
  }

  Widget _buildSectionCard(
    bool isDark, {
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[100]!),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: Icon(icon, color: Colors.blueGrey),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content,
              style: GoogleFonts.notoSans(fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  IconData _getHazardIcon(String type) {
    switch (type.toLowerCase()) {
      case 'flammable':
        return Symbols.local_fire_department;
      case 'toxic':
        return Symbols.skull;
      case 'corrosive':
        return Symbols.science;
      case 'oxidizer':
        return Symbols.filter_vintage;
      case 'explosive':
        return Symbols.explosion;
      case 'environmental':
        return Symbols.eco;
      case 'health_hazard':
        return Symbols.health_metrics;
      case 'gas_cylinder':
        return Symbols.mode_fan;
      case 'irritant':
      default:
        return Symbols.error;
    }
  }

  IconData _getPPEIcon(String type) {
    switch (type.toLowerCase()) {
      case 'goggles':
        return Symbols.visibility;
      case 'gloves':
        return Symbols.pan_tool;
      case 'lab_coat':
        return Symbols.science;
      case 'mask':
        return Symbols.masks;
      case 'face_shield':
        return Symbols.safety_check;
      case 'respirator':
        return Symbols.air_purifier;
      default:
        return Symbols.safety_check;
    }
  }

  Widget _buildGHSDiamond(IconData icon, String label) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: 0.785398, // 45 degrees
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFFEE2E2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.red, width: 4.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
            Icon(icon, color: Colors.red[900], size: 36, fill: 1),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxWidth: 90),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAIRiskAlert(bool isDark, AppLocalizations l10n) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF27364A)]
              : [const Color(0xFFFFF7ED), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.warning.withOpacity(0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.warning.withOpacity(0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Symbols.auto_awesome,
                        color: Colors.white,
                        size: 18,
                        fill: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.aiRiskAlert,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: AppColors.warning,
                          ),
                        ),
                        Text(
                          'AI-Generated Warning',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _data!.riskAlert.title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textMainLight,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _data!.riskAlert.description,
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    height: 1.6,
                    color: isDark
                        ? Colors.grey[300]
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPPEChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.notoSans(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.grey[400] : AppColors.textSecondaryLight,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildInfoExpansionTile({
    required String title,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.surfaceDark, const Color(0xFF151F29)]
              : [Colors.white, Colors.grey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : AppColors.primary.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.08 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          title: Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          children: children,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required List<String> steps,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: isDark ? 0.12 : 0.08),
            color.withValues(alpha: isDark ? 0.05 : 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.split('(')[0].trim(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                        height: 1.2,
                      ),
                    ),
                    if (title.contains('('))
                      Text(
                        '(${title.split('(')[1]}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.03)
                  : Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: steps.asMap().entries.map((entry) {
                int index = entry.key;
                String step = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < steps.length - 1 ? 12.0 : 0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step,
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
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
                  l10n.aiGeneratingSds,
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
                // Tab Bar Skeleton
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 24),

                // Chemical Info Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 38,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 24,
                            width: 140,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Risk AI Alert Skeleton
                Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 24),

                // Main Detailed Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: 120, color: Colors.white),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(
                          3,
                          (index) => Column(
                            children: [
                              Transform.rotate(
                                angle: 0.785398,
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(height: 10, width: 50, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(color: Colors.white24),
                      ),
                      Container(height: 14, width: 120, color: Colors.white),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: List.generate(
                          4,
                          (index) => Container(
                            height: 36,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        height: 54,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ],
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
