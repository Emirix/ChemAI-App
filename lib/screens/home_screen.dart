import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:chem_ai/core/constants/app_colors.dart';
import 'package:chem_ai/core/services/profile_service.dart';
import 'package:chem_ai/widgets/custom_bottom_nav.dart';
import 'package:chem_ai/widgets/custom_header.dart';
import 'package:chem_ai/widgets/custom_search_bar.dart';
import 'package:chem_ai/widgets/greeting_section.dart';
import 'package:chem_ai/widgets/ai_tools_section.dart';
import 'package:chem_ai/widgets/quick_reference_section.dart';
import 'package:chem_ai/widgets/recent_documents_section.dart';
import 'package:chem_ai/screens/ai_chat_list_screen.dart';
import 'package:chem_ai/core/utils/navigation_utils.dart';
import 'package:chem_ai/widgets/ai_promo_banner.dart';
import 'package:chem_ai/screens/plus_membership_screen.dart';
import 'package:chem_ai/services/view_history_service.dart';
import 'package:chem_ai/widgets/ad_banner.dart';
import 'package:chem_ai/screens/supplier_search_screen.dart';
import 'package:chem_ai/screens/raw_material_detail_screen.dart';
import 'package:chem_ai/screens/news_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chem_ai/services/barcode_service.dart';
import 'package:chem_ai/services/api_service.dart';
import 'package:chem_ai/screens/barcode_scanner_screen.dart';
import 'package:chem_ai/screens/safety_data_screen.dart';
import 'package:chem_ai/screens/tds_screen.dart';
import 'package:chem_ai/screens/ocr_scanner_screen.dart';
import 'package:chem_ai/core/utils/language_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:chem_ai/widgets/ai_loading_animation.dart';

/// Optimized HomeScreen with modular widgets
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  int _currentIndex = 0;
  final ViewHistoryService _historyService = ViewHistoryService();
  List<ViewHistoryItem> _recentActivities = [];
  bool _isPlus = false;

  // PDF cache: key is "chemicalName_type_template", value is {bytes, fileName}
  final Map<String, Map<String, dynamic>> _pdfCache = {};
  final BarcodeService _barcodeService = BarcodeService();
  final ImagePicker _picker = ImagePicker();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _checkMembershipStatus();
    _loadRecentActivity();
    _historyService.addListener(_loadRecentActivity);
  }

  @override
  void dispose() {
    _historyService.removeListener(_loadRecentActivity);
    _barcodeService.dispose();
    super.dispose();
  }

  Future<void> _checkMembershipStatus() async {
    try {
      final isPlus = await ProfileService().checkIsPlus();
      if (mounted) {
        setState(() {
          _isPlus = isPlus;
        });
      }
    } catch (e) {
      debugPrint('Error checking membership: $e');
    }
  }

  Future<void> _loadRecentActivity() async {
    try {
      final items = await _historyService.getHistory(limit: 50);

      if (mounted) {
        setState(() {
          _recentActivities = items.where((item) => item.isDocument).toList();
          _recentActivities.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (_recentActivities.length > 5) {
            _recentActivities = _recentActivities.take(5).toList();
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> pages = [
      _buildHomeContent(context, isDark),
      const AiChatListScreen(),
      const SupplierSearchScreen(),
      const NewsScreen(),
    ];

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: IndexedStack(index: _currentIndex, children: pages),
              ),
              if (_currentIndex != 1)
                const AdBanner(),
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomNav(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, bool isDark) {
    return CustomScrollView(
      slivers: [
        // Header
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: CustomHeader(),
          ),
        ),

        // Greeting
        const SliverToBoxAdapter(
          child: GreetingSection(),
        ),

        // Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomSearchBar(
              onScannerTap: () {
                _showScanOptions(context);
              },
              onSubmitted: (query) {
                if (query.isNotEmpty) {
                  NavigationUtils.pushWithSlide(
                    context,
                    RawMaterialDetailScreen(productName: query),
                  );
                }
              },
            ),
          ),
        ),

        // AI Promo Banner
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: AiPromoBanner(
              showButton: !_isPlus,
              onTap: () {
                NavigationUtils.pushWithSlide(
                  context,
                  const PlusMembershipScreen(),
                );
              },
            ),
          ),
        ),

        // AI Tools Section
        AiToolsSection(
          currentIndex: _currentIndex,
          onIndexChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),

        // Recent Documents
        RecentDocumentsSection(
          recentActivities: _recentActivities,
          pdfCache: _pdfCache,
        ),
      ],
    );
  }

  void _showScanOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.45,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Row(
                  children: [
                    Text(
                      'TARAMA SEÇENEKLERİ',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildScanOptionTile(
                      icon: Symbols.barcode_scanner,
                      title: 'Canlı Barkod Tara',
                      subtitle: 'Hızlı hammadde tanımlama',
                      color: AppColors.primary,
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        _handleCameraScan();
                      },
                    ),
                    _buildScanOptionTile(
                      icon: Symbols.image,
                      title: 'Galeriden Barkod Oku',
                      subtitle: 'Mevcut resimleri tarayın',
                      color: Colors.orange,
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        _handleGalleryScan();
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      child: Divider(height: 1),
                    ),
                    _buildScanOptionTile(
                      icon: Symbols.photo_camera,
                      title: 'Kamera ile AI Analizi',
                      subtitle: 'Etiket ve metin çözümleme',
                      color: Colors.purple,
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        _handleCameraOcrScan();
                      },
                    ),
                    _buildScanOptionTile(
                      icon: Symbols.auto_awesome,
                      title: 'Galeriden AI Analizi',
                      subtitle: 'Resimden veri çıkartma',
                      color: AppColors.emeraldText,
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        _handleGalleryOcrScan();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: isDark ? Colors.white : AppColors.textMainLight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white38 : Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: isDark ? Colors.white12 : Colors.grey[300],
      ),
      onTap: onTap,
    );
  }

  Future<void> _handleCameraScan() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      if (!mounted) return;
      final String? result = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const FractionallySizedBox(
          heightFactor: 0.85,
          child: BarcodeScannerScreen(),
        ),
      );
      if (result != null) {
        if (result == 'action:ocr') {
          // Barkod tarayıcıdan AI analizine geçiş
          Future.delayed(const Duration(milliseconds: 300), () => _handleCameraOcrScan());
        } else {
          _handleScanResult(result);
        }
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kamera izni verilmedi')),
      );
    }
  }

  Future<void> _handleGalleryScan() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final String? result = await _barcodeService.scanImage(image.path);
      if (result != null) {
        _handleScanResult(result);
      } else {
        _showErrorSnackBar('Resimde barkod bulunamadı');
      }
    }
  }

  Future<void> _handleCameraOcrScan() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _showErrorSnackBar('Kamera izni verilmedi');
      return;
    }

    if (!mounted) return;
    final String? imagePath = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FractionallySizedBox(
        heightFactor: 0.85,
        child: OcrScannerScreen(),
      ),
    );

    if (imagePath != null) {
      _performOcrAnalysis(imagePath);
    }
  }

  Future<void> _handleGalleryOcrScan() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _performOcrAnalysis(image.path);
    }
  }

  Future<void> _performOcrAnalysis(String path) async {
    if (!mounted) return;
    debugPrint('HomeScreen: Starting OCR analysis for $path');
    _showLoadingDialog('Metin ve kimyasallar analiz ediliyor...');
    
    try {
      debugPrint('HomeScreen: Extracting text from image...');
      final String? extractedText = await _barcodeService.extractTextFromImage(path);
      
      if (extractedText == null || extractedText.isEmpty) {
        debugPrint('HomeScreen: No text extracted.');
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop(); // close loading
        _showErrorSnackBar('Resimde okunabilir metin bulunamadı.');
        return;
      }

      debugPrint('HomeScreen: Extracted text length: ${extractedText.length}');
      final language = LanguageUtils.getLanguageString(context);
      final apiService = ApiService();
      
      debugPrint('HomeScreen: Calling identifyChemicalFromText API...');
      final identifiedData = await apiService.identifyChemicalFromText(extractedText, language);
      debugPrint('HomeScreen: API returned identifiedData: $identifiedData');

      if (!mounted) return;
      debugPrint('HomeScreen: Popping loading dialog...');
      try {
        // Use rootNavigator: true to ensure we're popping the dialog shown by _showLoadingDialog
        Navigator.of(context, rootNavigator: true).pop(); 
      } catch (popError) {
        debugPrint('HomeScreen: Non-critical error popping loading dialog: $popError');
      }

      if (identifiedData != null) {
        final String? name = identifiedData['chemicalName'] ?? identifiedData['productName'];
        
        if (name != null && name.isNotEmpty && name.toLowerCase() != 'null') {
          debugPrint('HomeScreen: Product identified successfully: $name. Showing result dialog.');
          _handleScanResult(name);
        } else {
          debugPrint('HomeScreen: Product identified but name is invalid/empty: $name');
          _showErrorSnackBar('Kimyasal hammadde adı tam olarak belirlenemedi.');
        }
      } else {
        debugPrint('HomeScreen: API returned null identifiedData.');
        _showErrorSnackBar('Kimyasal hammadde bilgisi saptanamadı.');
      }
    } catch (e) {
      debugPrint('HomeScreen: Error during OCR analysis: $e');
      if (!mounted) return;
      try {
        Navigator.of(context, rootNavigator: true).pop(); // close loading
      } catch (popError) {
        debugPrint('HomeScreen: Error popping dialog: $popError');
      }
      _showErrorSnackBar('Analiz sırasında hata oluştu.');
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AiLoadingAnimation(
        message: message,
        type: AiLoadingType.ocr,
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _handleScanResult(String result) {
    _showResultDialog(result);
  }

  void _showResultDialog(String code) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.45,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Icon(Symbols.check_circle, color: Colors.green, size: 54),
              const SizedBox(height: 12),
              Text(
                'Ürün Tanımlandı',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                code.length < 20 ? 'Bulunan Ürün' : 'Belirlenen Kimyasal',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                code,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _buildResultActionButton(
                      icon: Symbols.description,
                      label: 'SDS',
                      bgColor: AppColors.orangeLight,
                      textColor: AppColors.orangeText,
                      onTap: () {
                        Navigator.pop(context);
                        NavigationUtils.pushWithSlide(context, SafetyDataScreen(initialQuery: code));
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildResultActionButton(
                      icon: Symbols.lab_profile,
                      label: 'TDS',
                      bgColor: AppColors.emeraldLight,
                      textColor: AppColors.emeraldText,
                      onTap: () {
                        Navigator.pop(context);
                        NavigationUtils.pushWithSlide(context, TdsScreen(initialQuery: code));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _buildResultActionButton(
                  icon: Symbols.info,
                  label: 'Kapsamlı Ürün Detayları',
                  bgColor: const Color(0xFFE0F2FE),
                  textColor: AppColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    NavigationUtils.pushWithSlide(context, RawMaterialDetailScreen(productName: code));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultActionButton({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
