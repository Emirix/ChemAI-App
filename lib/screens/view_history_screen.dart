import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:chem_ai/core/constants/app_colors.dart';
import 'package:chem_ai/services/view_history_service.dart';
import 'package:chem_ai/widgets/activity_item.dart';
import 'package:chem_ai/services/pdf_service.dart';
import 'package:chem_ai/services/api_service.dart';
import 'package:chem_ai/core/enums/msds_template.dart';
import 'package:chem_ai/core/enums/tds_template.dart';
import 'package:printing/printing.dart';
import 'package:chem_ai/core/utils/language_utils.dart';
import 'dart:typed_data';
import 'package:chem_ai/models/safety_data.dart';
import 'package:chem_ai/models/tds_data.dart';

class ViewHistoryScreen extends StatefulWidget {
  const ViewHistoryScreen({super.key});

  @override
  State<ViewHistoryScreen> createState() => _ViewHistoryScreenState();
}

class _ViewHistoryScreenState extends State<ViewHistoryScreen> {
  final ViewHistoryService _historyService = ViewHistoryService();
  final PdfService _pdfService = PdfService();
  final ApiService _apiService = ApiService();
  List<ViewHistoryItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _historyService.addListener(_loadHistory);
  }

  @override
  void dispose() {
    _historyService.removeListener(_loadHistory);
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final items = await _historyService.getHistory(limit: 100);
      setState(() {
        _items = items.where((item) => item.isDocument).toList();
        _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Tüm Aktiviteler',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Symbols.arrow_back,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? Center(
              child: Text(
                'Henüz aktivite yok',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _items[index];
                return ActivityItem(
                  icon: item.type.contains('msds')
                      ? Symbols.science
                      : (item.type.contains('tds')
                            ? Symbols.description
                            : Symbols.info),
                  title: item.title,
                  category: item.type.toUpperCase().replaceAll(
                    '_PDF',
                    ' BELGESİ',
                  ),
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
                );
              },
            ),
    );
  }

  Future<void> _handleDocumentAction(ViewHistoryItem item, bool isShare) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final language = LanguageUtils.getLanguageString(context);
      final templateStr = item.metadata['template'] ?? 'standard';

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

      if (bytes != null && fileName != null) {
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
