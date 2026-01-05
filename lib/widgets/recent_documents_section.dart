import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:chem_ai/core/constants/app_colors.dart';
import 'package:chem_ai/widgets/activity_item.dart';
import 'package:chem_ai/services/view_history_service.dart';
import 'package:chem_ai/screens/view_history_screen.dart';
import 'package:chem_ai/core/utils/navigation_utils.dart';
import 'package:chem_ai/services/pdf_service.dart';
import 'package:chem_ai/core/enums/msds_template.dart';
import 'package:chem_ai/core/enums/tds_template.dart';
import 'package:chem_ai/services/api_service.dart';
import 'package:printing/printing.dart';
import 'package:chem_ai/core/utils/language_utils.dart';
import 'package:chem_ai/models/safety_data.dart';
import 'package:chem_ai/models/tds_data.dart';

/// Recent documents section with optimized PDF caching
class RecentDocumentsSection extends StatefulWidget {
  final List<ViewHistoryItem> recentActivities;
  final Map<String, Map<String, dynamic>> pdfCache;

  const RecentDocumentsSection({
    super.key,
    required this.recentActivities,
    required this.pdfCache,
  });

  @override
  State<RecentDocumentsSection> createState() => _RecentDocumentsSectionState();
}

class _RecentDocumentsSectionState extends State<RecentDocumentsSection> {
  final PdfService _pdfService = PdfService();
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverMainAxisGroup(
      slivers: [
        // Section Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Oluşturulan Belgeler',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    NavigationUtils.pushWithSlide(
                      context,
                      const ViewHistoryScreen(),
                    );
                  },
                  child: const Text(
                    'Tümünü Gör',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Documents List
        if (widget.recentActivities.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'Henüz belge oluşturulmadı',
                  style: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = widget.recentActivities[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ActivityItem(
                      icon: item.type.contains('msds')
                          ? Symbols.science
                          : (item.type.contains('tds')
                              ? Symbols.description
                              : Symbols.info),
                      title: item.title,
                      category: item.type
                          .toUpperCase()
                          .replaceAll('_PDF', ' BELGESİ')
                          .replaceAll('MSDS', 'SDS'),
                      time: _formatTime(item.createdAt),
                      iconBgColor: item.type.contains('msds')
                          ? const Color(0xFFEFF6FF)
                          : (item.type.contains('tds')
                              ? const Color(0xFFDCFCE7)
                              : Colors.orange.shade50),
                      iconColor: item.type.contains('msds')
                          ? AppColors.primary
                          : (item.type.contains('tds')
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFEA580C)),
                      onViewTap: item.isDocument
                          ? () => _handleDocumentAction(item, false)
                          : null,
                      onShareTap: item.isDocument
                          ? () => _handleDocumentAction(item, true)
                          : null,
                    ),
                  );
                },
                childCount: widget.recentActivities.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Future<void> _handleDocumentAction(ViewHistoryItem item, bool isShare) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final language = LanguageUtils.getLanguageString(context);
    final templateStr = item.metadata['template'] ?? 'standard';

    // Create cache key
    final cacheKey = '${item.title}_${item.type}_$templateStr';

    // Check cache first
    if (widget.pdfCache.containsKey(cacheKey)) {
      final cached = widget.pdfCache[cacheKey]!;
      final bytes = cached['bytes'] as Uint8List;
      final fileName = cached['fileName'] as String;

      try {
        if (isShare) {
          await Printing.sharePdf(bytes: bytes, filename: fileName);
        } else {
          await Printing.layoutPdf(onLayout: (format) => bytes, name: fileName);
        }
        return;
      } catch (e) {
        debugPrint('Error using cached PDF: $e');
      }
    }

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Belge hazırlanıyor...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      Uint8List? bytes;
      String? fileName;

      if (item.type == 'msds_pdf') {
        final response = await _apiService.getSafetyData(item.title, language);
        if (response != null && response['data'] != null) {
          final data = response['data'] as SafetyData;
          final msdsTemplate = MsdsTemplate.values.firstWhere(
            (e) => e.name == templateStr,
            orElse: () => MsdsTemplate.standard,
          );
          final result = await _pdfService.generateMsds(
            data,
            language,
            template: msdsTemplate,
          );
          bytes = result['bytes'];
          fileName = result['fileName'];
        }
      } else if (item.type == 'tds_pdf') {
        final response = await _apiService.getTdsData(item.title, language);
        if (response != null && response['data'] != null) {
          final data = response['data'] as TdsData;
          final tdsTemplate = TdsTemplate.values.firstWhere(
            (e) => e.name == templateStr,
            orElse: () => TdsTemplate.standard,
          );
          final result = await _pdfService.generateTds(
            data,
            language,
            template: tdsTemplate,
          );
          bytes = result['bytes'];
          fileName = result['fileName'];
        }
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (bytes != null && fileName != null) {
        // Cache the PDF
        widget.pdfCache[cacheKey] = {'bytes': bytes, 'fileName': fileName};

        if (isShare) {
          await Printing.sharePdf(bytes: bytes, filename: fileName);
        } else {
          await Printing.layoutPdf(
            onLayout: (format) => bytes!,
            name: fileName,
          );
        }
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Belge verileri alınamadı.')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      debugPrint('Error handling document action: $e');
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    final minutes = diff.inMinutes;

    if (minutes < 1) {
      return 'Az önce';
    } else if (minutes < 60) {
      return '$minutes dk önce';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} sa önce';
    } else {
      return '${diff.inDays} gn önce';
    }
  }
}
