import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import '../models/safety_data.dart';
import '../models/tds_data.dart';
import '../core/enums/msds_template.dart';
import '../core/enums/tds_template.dart';
import 'analytics_service.dart';

import 'package:flutter/foundation.dart';

class PdfService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> generateMsds(
    SafetyData data,
    String language, {
    Map<String, dynamic>? companyInfo,
    MsdsTemplate template = MsdsTemplate.standard,
  }) async {
    AnalyticsService().logEvent(
      name: 'generate_msds',
      parameters: {
        'product_name': data.chemicalName,
        'language': language,
        'template': template.toString(),
      },
    );
    final String companyName =
        companyInfo?['companyName'] ??
        companyInfo?['company_name'] ??
        companyInfo?['name'] ??
        'Firma Bilgisi Yok';
    final String? logoUrl = companyInfo?['logoUrl'] ?? companyInfo?['logo_url'];
    final String? signatureUrl =
        companyInfo?['signatureUrl'] ?? companyInfo?['signature_url'];

    // Composite language key for caching to avoid schema changes
    // e.g. "Turkish_minimalist"
    final String cacheLanguageKey = '${language}_${template.name}';

    // 2. Check Cache
    try {
      final cachedPdf = await _supabase
          .from('pdf_cache')
          .select('storage_path')
          .eq('company_name', companyName)
          .eq('logo_url', logoUrl ?? '')
          .eq('chemical_name', data.chemicalName)
          .eq('cas_number', data.casNumber)
          .eq('language', cacheLanguageKey)
          .maybeSingle();

      if (cachedPdf != null) {
        final storagePath = cachedPdf['storage_path'] as String;
        debugPrint('PdfService: Cache HIT! Downloading PDF from: $storagePath');
        final bytes = await _supabase.storage
            .from('msds')
            .download(storagePath);
        return {
          'bytes': bytes,
          'fileName': storagePath.split('/').last,
          'cached': true,
        };
      }
    } catch (e) {
      debugPrint('PdfService: Cache check failed (continuing to generate): $e');
    }

    debugPrint(
      'PdfService: Cache MISS. Generating new PDF for template ${template.name}...',
    );
    final pdf = pw.Document();

    // Load fonts - Using NotoSans for better Turkish and special character support
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    pw.MemoryImage? logoImage;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(logoUrl));
        if (response.statusCode == 200) {
          logoImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        debugPrint('PdfService: Logo indirilemedi: $e');
      }
    }

    pw.MemoryImage? signatureImage;
    if (signatureUrl != null && signatureUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(signatureUrl));
        if (response.statusCode == 200) {
          signatureImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        debugPrint('PdfService: İmza indirilemedi: $e');
      }
    }

    // Select Layout Builder
    switch (template) {
      case MsdsTemplate.standard:
        _buildStandardLayout(
          pdf,
          data,
          font,
          boldFont,
          logoImage,
          signatureImage,
          companyName,
          companyInfo,
        );
        break;
      case MsdsTemplate.professional:
        _buildProfessionalLayout(
          pdf,
          data,
          font,
          boldFont,
          logoImage,
          signatureImage,
          companyName,
          companyInfo,
        );
        break;
    }

    final Uint8List bytes = await pdf.save();
    final String fileName =
        '${data.chemicalName.replaceAll(' ', '_')}_${template.name}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final storagePath = 'pdfs/$fileName';

    // 3. Save to Cache & Storage
    try {
      await _supabase.storage
          .from('msds')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(contentType: 'application/pdf'),
          );

      await _supabase.from('pdf_cache').insert({
        'company_name': companyName,
        'logo_url': logoUrl ?? '',
        'chemical_name': data.chemicalName,
        'cas_number': data.casNumber,
        'language': cacheLanguageKey, // Store the composite key
        'storage_path': storagePath,
      });
      debugPrint('PdfService: New PDF generated and cached: $storagePath');
    } catch (e) {
      debugPrint('PdfService: Caching failed (ignoring): $e');
    }

    return {'bytes': bytes, 'fileName': fileName, 'cached': false};
  }

  Future<Map<String, dynamic>> generateTds(
    TdsData data,
    String language, {
    Map<String, dynamic>? companyInfo,
    TdsTemplate template = TdsTemplate.standard,
  }) async {
    AnalyticsService().logEvent(
      name: 'generate_tds',
      parameters: {
        'product_name': data.productName,
        'language': language,
        'template': template.toString(),
      },
    );
    final String companyName =
        companyInfo?['companyName'] ??
        companyInfo?['company_name'] ??
        companyInfo?['name'] ??
        'Firma Bilgisi Yok';
    final String? logoUrl = companyInfo?['logoUrl'] ?? companyInfo?['logo_url'];
    final String? signatureUrl =
        companyInfo?['signatureUrl'] ?? companyInfo?['signature_url'];

    // Composite language key for caching
    final String cacheLanguageKey = 'TDS_${language}_${template.name}';

    // 2. Check Cache
    try {
      final cachedPdf = await _supabase
          .from('pdf_cache')
          .select('storage_path')
          .eq('company_name', companyName)
          .eq('logo_url', logoUrl ?? '')
          .eq('chemical_name', data.productName)
          .eq('language', cacheLanguageKey)
          .maybeSingle();

      if (cachedPdf != null) {
        final storagePath = cachedPdf['storage_path'] as String;
        debugPrint(
          'PdfService: TDS Cache HIT! Downloading PDF from: $storagePath',
        );
        final bytes = await _supabase.storage
            .from('msds')
            .download(storagePath);
        return {
          'bytes': bytes,
          'fileName': storagePath.split('/').last,
          'cached': true,
        };
      }
    } catch (e) {
      debugPrint('PdfService: TDS Cache check failed: $e');
    }

    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    pw.MemoryImage? logoImage;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(logoUrl));
        if (response.statusCode == 200) {
          logoImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        debugPrint('PdfService: Logo indirilemedi: $e');
      }
    }

    pw.MemoryImage? signatureImage;
    if (signatureUrl != null && signatureUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(signatureUrl));
        if (response.statusCode == 200) {
          signatureImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        debugPrint('PdfService: İmza indirilemedi: $e');
      }
    }

    switch (template) {
      case TdsTemplate.standard:
        _buildTdsStandardLayout(
          pdf,
          data,
          font,
          boldFont,
          logoImage,
          signatureImage,
          companyName,
          companyInfo,
        );
        break;
      case TdsTemplate.professional:
        _buildTdsProfessionalLayout(
          pdf,
          data,
          font,
          boldFont,
          logoImage,
          signatureImage,
          companyName,
          companyInfo,
        );
        break;
    }

    final Uint8List bytes = await pdf.save();
    final String fileName =
        '${data.productName.replaceAll(' ', '_')}_TDS_${template.name}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final storagePath = 'tds/$fileName';

    // 3. Save to Cache & Storage
    try {
      await _supabase.storage
          .from('msds')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(contentType: 'application/pdf'),
          );

      await _supabase.from('pdf_cache').insert({
        'company_name': companyName,
        'logo_url': logoUrl ?? '',
        'chemical_name': data.productName,
        'language': cacheLanguageKey,
        'storage_path': storagePath,
      });
    } catch (e) {
      debugPrint('PdfService: TDS Caching failed: $e');
    }

    return {'bytes': bytes, 'fileName': fileName, 'cached': false};
  }

  // --- Layouts ---

  void _buildStandardLayout(
    pw.Document pdf,
    SafetyData data,
    pw.Font font,
    pw.Font boldFont,
    pw.MemoryImage? logoImage,
    pw.MemoryImage? signatureImage,
    String companyName,
    Map<String, dynamic>? companyInfo,
  ) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'GÜVENLİK BİLGİ FORMU (SDS)',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'ChemAI',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (logoImage != null)
                    pw.Container(
                      height: 50,
                      width: 100,
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Ürün: ${data.chemicalName}',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'CAS Numarası: ${data.casNumber}',
              style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 20),
            pw.Header(level: 1, text: '1. Ürün ve Firma Tanımı'),
            pw.Text(
              'Ürün Adı: ${data.chemicalName}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('CAS No: ${data.casNumber}'),
            pw.SizedBox(height: 8),
            pw.Text(
              'Tedarikçi Bilgileri:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('Firma: ${data.supplierInformation.companyName}'),
            pw.Text('Adres: ${data.supplierInformation.address}'),
            pw.Text('Telefon: ${data.supplierInformation.phone}'),
            pw.Text(
              'Acil Durum Tel: ${data.supplierInformation.emergencyPhone}',
              style: pw.TextStyle(color: PdfColors.red),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Kullanım Alanları:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Paragraph(text: data.description),

            pw.Header(level: 1, text: '2. Tehlike Tanımlama'),
            ...data.hazards.map(
              (h) => pw.Bullet(
                text: '${h.label}: ${h.description}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),

            pw.Header(level: 1, text: '3. Bileşimi / İçindekiler'),
            if (data.composition.isNotEmpty) ...[
              pw.TableHelper.fromTextArray(
                context: context,
                headers: [
                  'Bileşen',
                  'CAS No',
                  'Konsantrasyon',
                  'Sınıflandırma',
                ],
                data: data.composition
                    .map(
                      (c) => [
                        c.componentName,
                        c.casNumber,
                        c.concentration,
                        c.classification,
                      ],
                    )
                    .toList(),
                cellStyle: pw.TextStyle(font: font, fontSize: 10),
                headerStyle: pw.TextStyle(
                  font: boldFont,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ] else ...[
              pw.Paragraph(
                text:
                    'Kimyasal Adı: ${data.chemicalName}\nCAS No: ${data.casNumber}',
              ),
            ],

            pw.Header(level: 1, text: '4. İlk Yardım Önlemleri'),
            ...data.firstAid.map((step) => pw.Bullet(text: step)),

            pw.Header(level: 1, text: '5. Yangınla Mücadele Önlemleri'),
            ...data.firefighting.map((step) => pw.Bullet(text: step)),

            pw.Header(
              level: 1,
              text: '6. Kaza Sonucu Yayılmaya Karşı Önlemler',
            ),
            pw.Paragraph(text: data.accidentalRelease),

            pw.Header(level: 1, text: '7. Elleçleme ve Depolama'),
            pw.Text(
              'Kullanım:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Paragraph(text: data.handling),
            pw.Text(
              'Depolama:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Paragraph(text: data.storage),

            pw.Header(
              level: 1,
              text: '8. Maruziyet Kontrolleri / Kişisel Korunma',
            ),
            pw.Text(
              'Maruziyet Limitleri:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(data.exposureControls.occupationalExposureLimit),
            pw.SizedBox(height: 8),
            pw.Text(
              'Mühendislik Kontrolleri:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(data.exposureControls.engineeringControls),
            pw.SizedBox(height: 8),
            pw.Text(
              'Kişisel Koruyucu Ekipman:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            ...data.ppe.map((p) => pw.Bullet(text: p.label)),
            pw.SizedBox(height: 8),
            pw.Text(
              'Ek Önlemler:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(data.exposureControls.ppeNotes),

            pw.Header(level: 1, text: '9. Fiziksel ve Kimyasal Özellikler'),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Özellik', 'Değer'],
              data: data.properties.map((p) => [p.label, p.value]).toList(),
              cellStyle: pw.TextStyle(font: font),
              headerStyle: pw.TextStyle(
                font: boldFont,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.Header(level: 1, text: '10. Kararlılık ve Tepkime'),
            pw.Paragraph(text: data.stabilityAndReactivity),

            pw.Header(level: 1, text: '11. Toksikolojik Bilgiler'),
            pw.Paragraph(text: data.toxicologicalInformation),

            pw.Header(level: 1, text: '12. Ekolojik Bilgiler'),
            pw.Paragraph(text: data.ecologicalInformation),

            pw.Header(level: 1, text: '13. Bertaraf Bilgileri'),
            pw.Paragraph(text: data.disposalConsiderations),

            pw.Header(level: 1, text: '14. Taşımacılık Bilgileri'),
            pw.Paragraph(text: data.transportInformation),

            pw.Header(level: 1, text: '15. Mevzuat Bilgileri'),
            pw.Paragraph(text: data.regulatoryInformation),

            pw.Header(level: 1, text: '16. Diğer Bilgiler'),
            pw.Text(
              'Revizyon Bilgileri:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('Versiyon: ${data.revisionInformation.sdsVersion}'),
            pw.Text('Tarih: ${data.revisionInformation.revisionDate}'),
            pw.Text('Değişiklikler: ${data.revisionInformation.changes}'),

            pw.SizedBox(height: 40),
            pw.Divider(),
            _buildFooter(companyName, companyInfo, signatureImage),
          ];
        },
      ),
    );
  }

  void _buildProfessionalLayout(
    pw.Document pdf,
    SafetyData data,
    pw.Font font,
    pw.Font boldFont,
    pw.MemoryImage? logoImage,
    pw.MemoryImage? signatureImage,
    String companyName,
    Map<String, dynamic>? companyInfo,
  ) {
    // Top border color line
    final PdfColor corporateColor = PdfColors.blue900;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (pw.Context context) {
          return [
            // Professional Header
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: corporateColor, width: 2),
                ),
              ),
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logoImage != null)
                        pw.Container(
                          height: 40,
                          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                        )
                      else
                        pw.Text(
                          companyName,
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: corporateColor,
                          ),
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'GÜVENLİK BİLGİ FORMU (SDS)',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'GHS/CLP Regülasyonlarına Uygundur',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.Text(
                        'Tarih: ${DateTime.now().toIso8601String().substring(0, 10)}',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Product Identity Badge
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              color: PdfColors.grey100,
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          data.chemicalName.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: corporateColor,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'CAS: ${data.casNumber}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          data.description,
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // QR Code placeholder using Barcode
                  pw.Container(
                    height: 60,
                    width: 60,
                    child: pw.BarcodeWidget(
                      data:
                          'https://pubchem.ncbi.nlm.nih.gov/#query=${Uri.encodeComponent(data.casNumber)}',
                      barcode: pw.Barcode.qrCode(),
                      color: corporateColor,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Section 1: Supplier Information
            _buildProfHeader(
              '1. ÜRÜN VE FİRMA BİLGİLERİ',
              corporateColor,
              boldFont,
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Tedarikçi: ${data.supplierInformation.companyName}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Adres: ${data.supplierInformation.address}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'Tel: ${data.supplierInformation.phone}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'Acil Tel: ${data.supplierInformation.emergencyPhone}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Section 3: Composition
            if (data.composition.isNotEmpty) ...[
              _buildProfHeader(
                '3. BİLEŞİM / İÇİNDEKİLER',
                corporateColor,
                boldFont,
              ),
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: corporateColor.shade(0.9),
                ),
                headers: ['Bileşen', 'CAS', 'Konsantrasyon', 'Sınıflandırma'],
                data: data.composition
                    .map(
                      (c) => [
                        c.componentName,
                        c.casNumber,
                        c.concentration,
                        c.classification,
                      ],
                    )
                    .toList(),
                cellStyle: pw.TextStyle(font: font, fontSize: 8),
                headerStyle: pw.TextStyle(
                  font: boldFont,
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                cellPadding: const pw.EdgeInsets.all(3),
              ),
              if (signatureImage != null) ...[
                pw.SizedBox(height: 30),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      children: [
                        pw.Container(
                          height: 50,
                          width: 100,
                          child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Authorized Signature',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 8,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
              pw.SizedBox(height: 16),
            ],

            // 2 Columns: Hazards & First Aid
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildProfHeader(
                        'TEHLİKE TANIMLARI',
                        corporateColor,
                        boldFont,
                      ),
                      ...data.hazards.map(
                        (h) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Container(
                                width: 14,
                                height: 14,
                                decoration: const pw.BoxDecoration(
                                  color: PdfColors.red,
                                  shape: pw.BoxShape.circle,
                                ),
                                margin: const pw.EdgeInsets.only(
                                  right: 6,
                                  top: 2,
                                ),
                                child: pw.Center(
                                  child: pw.Text(
                                    '!',
                                    style: pw.TextStyle(
                                      color: PdfColors.white,
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              pw.Expanded(
                                child: pw.Text(
                                  '${h.label}: ${h.description}',
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      _buildProfHeader(
                        '8. MARUZİYET KONTROLLERİ',
                        corporateColor,
                        boldFont,
                      ),
                      pw.Text(
                        'OEL: ${data.exposureControls.occupationalExposureLimit}',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      pw.Text(
                        'Mühendislik: ${data.exposureControls.engineeringControls}',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      pw.SizedBox(height: 8),
                      _buildProfHeader(
                        'ÖNLEMLER (P-CODES)',
                        corporateColor,
                        boldFont,
                      ),
                      // Assuming we don't have explicit P-codes, mapping PPE
                      ...data.ppe.map(
                        (p) => pw.Text(
                          '• ${p.label}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Ek Önlemler: ${data.exposureControls.ppeNotes}',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildProfHeader(
                        'İLK YARDIM (Acil)',
                        corporateColor,
                        boldFont,
                      ),
                      ...data.firstAid.map(
                        (f) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Text(
                            '• $f',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      _buildProfHeader(
                        'YANGIN MÜDAHALE',
                        corporateColor,
                        boldFont,
                      ),
                      ...data.firefighting.map(
                        (f) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Text(
                            '• $f',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // Full Width Table for Properties
            _buildProfHeader(
              'FİZİKSEL VE KİMYASAL ÖZELLİKLER',
              corporateColor,
              boldFont,
            ),
            pw.TableHelper.fromTextArray(
              context: context,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey100),
              headers: ['Özellik', 'Değer'],
              data: data.properties.map((p) => [p.label, p.value]).toList(),
              cellStyle: pw.TextStyle(font: font, fontSize: 9),
              headerStyle: pw.TextStyle(
                font: boldFont,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: corporateColor,
              ),
              cellPadding: const pw.EdgeInsets.all(4),
            ),

            pw.SizedBox(height: 20),
            pw.SizedBox(height: 20),
            _buildProfHeader(
              'DEPOLAMA VE TAŞIMA (7, 14)',
              corporateColor,
              boldFont,
            ),
            pw.Text(data.storage, style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 10),
            pw.Text(
              'ELLEÇLEME:',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(data.handling, style: const pw.TextStyle(fontSize: 9)),

            pw.SizedBox(height: 10),
            _buildProfHeader(
              'EK BİLGİLER (10, 11, 12, 13, 15)',
              corporateColor,
              boldFont,
            ),
            pw.Text(
              '10. Kararlılık: ${data.stabilityAndReactivity}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              '11. Toksikoloji: ${data.toxicologicalInformation}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              '12. Ekoloji: ${data.ecologicalInformation}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              '13. Bertaraf: ${data.disposalConsiderations}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              '15. Mevzuat: ${data.regulatoryInformation}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              '14. Taşımacılık: ${data.transportInformation}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              '6. Kaza Önlemleri: ${data.accidentalRelease}',
              style: const pw.TextStyle(fontSize: 9),
            ),

            pw.SizedBox(height: 16),
            _buildProfHeader(
              '16. REVİZYON BİLGİLERİ',
              corporateColor,
              boldFont,
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Versiyon: ${data.revisionInformation.sdsVersion}',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Tarih: ${data.revisionInformation.revisionDate}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      '  ${data.revisionInformation.changes}',
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),
            pw.Divider(color: corporateColor),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Acil Durum Tel: 112 / 114 (UZEM)',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                    color: PdfColors.red,
                  ),
                ),
                pw.Text(
                  'Sayfa 1 / 1',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                ),
              ],
            ),
            _buildFooter(companyName, companyInfo, signatureImage),
          ];
        },
      ),
    );
  }

  pw.Widget _buildProfHeader(String text, PdfColor color, pw.Font font) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      margin: const pw.EdgeInsets.only(bottom: 6),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 10,
          font: font,
        ),
      ),
    );
  }

  pw.Widget _buildFooter(
    String companyName,
    Map<String, dynamic>? companyInfo,
    pw.MemoryImage? signatureImage,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              companyName,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
            pw.Text(
              companyInfo?['address'] ?? '',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
          ],
        ),
        if (signatureImage != null)
          pw.Column(
            children: [
              pw.Container(
                height: 40,
                width: 80,
                child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
              ),
              pw.Text(
                'Yetkili İmzası',
                style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey),
              ),
            ],
          ),
        pw.Text(
          'ChemAI Yapay Zeka Asistanı tarafından oluşturulmuştur',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
        ),
      ],
    );
  }
  // --- TDS Layouts ---

  void _buildTdsStandardLayout(
    pw.Document pdf,
    TdsData data,
    pw.Font font,
    pw.Font boldFont,
    pw.MemoryImage? logo,
    pw.MemoryImage? signatureImage,
    String companyName,
    Map<String, dynamic>? companyInfo,
  ) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        header: (pw.Context context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (logo != null)
                pw.Image(logo, width: 80)
              else
                pw.Expanded(
                  child: pw.Text(
                    companyName,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'TECHNICAL DATA SHEET',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      data.productName,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        build: (pw.Context context) {
          return [
            pw.Text(
              data.subtitle,
              style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic),
            ),
            pw.SizedBox(height: 20),
            _buildTdsColoredHeader(
              'Product Identity',
              PdfColors.blue800,
              boldFont,
            ),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Parameter', 'Value'],
              data: [
                ['CAS Number', data.identity.casNumber],
                ['EC Number', data.identity.ecNumber],
                ['Molecular Formula', data.identity.formula],
                ['Molecular Weight', data.identity.molecularWeight],
              ],
            ),
            pw.SizedBox(height: 20),
            _buildTdsColoredHeader(
              'Technical Specifications',
              PdfColors.blue800,
              boldFont,
            ),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Property', 'Value'],
              data: data.technicalSpecs.map((s) => [s.label, s.value]).toList(),
            ),
            pw.SizedBox(height: 20),
            _buildTdsColoredHeader(
              'Storage & Shelf Life',
              PdfColors.blue800,
              boldFont,
            ),
            ...data.storageInfo.conditions.map((c) => pw.Bullet(text: c)),
            pw.Text(
              'Shelf Life: ${data.storageInfo.shelfLife}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),

            // NEW: Supplier Information Section
            pw.SizedBox(height: 20),
            _buildTdsColoredHeader(
              'Supplier Information',
              PdfColors.blue800,
              boldFont,
            ),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Field', 'Information'],
              data: [
                ['Company Name', data.supplierInformation.companyName],
                ['Address', data.supplierInformation.address],
                ['Phone', data.supplierInformation.phone],
                ['Email', data.supplierInformation.email],
                ['Website', data.supplierInformation.website],
              ],
              cellStyle: pw.TextStyle(font: font, fontSize: 9),
              headerStyle: pw.TextStyle(
                font: boldFont,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            // NEW: Document Information Section
            pw.SizedBox(height: 20),
            _buildTdsColoredHeader(
              'Document Information',
              PdfColors.blue800,
              boldFont,
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                color: PdfColors.grey50,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Document No: ${data.documentInformation.documentNumber}',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Revision: ${data.documentInformation.revisionNumber}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Issue Date: ${data.documentInformation.issueDate}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        'Supersedes: ${data.documentInformation.supersedes}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // NEW: Regulatory Compliance Section
            pw.SizedBox(height: 20),
            _buildTdsColoredHeader(
              'Regulatory Compliance',
              PdfColors.blue800,
              boldFont,
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 100,
                        child: pw.Text(
                          'REACH Status:',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          data.regulatoryCompliance.reach,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 100,
                        child: pw.Text(
                          'KKDİK Status:',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          data.regulatoryCompliance.kkdik,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                  if (data.regulatoryCompliance.standards.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Standards:',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    ...data.regulatoryCompliance.standards.map(
                      (std) => pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 10, top: 2),
                        child: pw.Text(
                          '• $std',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // NEW: Transport Information Section
            pw.SizedBox(height: 20),
            _buildTdsColoredHeader(
              'Transport Information',
              PdfColors.blue800,
              boldFont,
            ),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Classification', 'Details'],
              data: [
                ['UN Number', data.transportInformation.unNumber],
                [
                  'Proper Shipping Name',
                  data.transportInformation.properShippingName,
                ],
                ['Transport Class', data.transportInformation.transportClass],
                ['Packing Group', data.transportInformation.packingGroup],
              ],
              cellStyle: pw.TextStyle(font: font, fontSize: 9),
              headerStyle: pw.TextStyle(
                font: boldFont,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ];
        },
      ),
    );
  }

  void _buildTdsProfessionalLayout(
    pw.Document pdf,
    TdsData data,
    pw.Font font,
    pw.Font boldFont,
    pw.MemoryImage? logo,
    pw.MemoryImage? signatureImage,
    String companyName,
    Map<String, dynamic>? companyInfo,
  ) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (pw.Context context) {
          return [
            // Header with Border
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColor.fromInt(0xFF2563EB),
                  width: 2,
                ),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        companyName,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (companyInfo?['address'] != null)
                        pw.Text(
                          companyInfo!['address'],
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                    ],
                  ),
                  if (logo != null) pw.Image(logo, width: 60),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Center(
              child: pw.Text(
                'TECHNICAL DATA SHEET',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 2,
                  color: PdfColors.blue700,
                ),
              ),
            ),
            pw.Center(
              child: pw.Text(
                data.productName,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 40),

            _buildProfessionalTdsRow('Product Identification', [
              ['CAS Registry No.', data.identity.casNumber],
              ['EINECS No.', data.identity.ecNumber],
              ['Chemical Formula', data.identity.formula],
            ]),

            pw.SizedBox(height: 25),
            _buildProfessionalTdsRow(
              'Physical Properties',
              data.physicalProperties.map((p) => [p.label, p.value]).toList(),
            ),

            pw.SizedBox(height: 25),
            _buildProfessionalTdsRow(
              'Technical Data',
              data.technicalSpecs.map((s) => [s.label, s.value]).toList(),
            ),

            // NEW: Supplier Information
            pw.SizedBox(height: 25),
            _buildProfessionalTdsRow('Supplier Information', [
              ['Company Name', data.supplierInformation.companyName],
              ['Address', data.supplierInformation.address],
              ['Phone', data.supplierInformation.phone],
              ['Email', data.supplierInformation.email],
            ]),

            // NEW: Document & Regulatory Info
            pw.SizedBox(height: 25),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Document Information',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Doc No: ${data.documentInformation.documentNumber}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Revision: ${data.documentInformation.revisionNumber}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Date: ${data.documentInformation.issueDate}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Regulatory Compliance',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'REACH: ${data.regulatoryCompliance.reach}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'KKDİK: ${data.regulatoryCompliance.kkdik}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // NEW: Transport Information
            pw.SizedBox(height: 25),
            _buildProfessionalTdsRow('Transport Information', [
              ['UN Number', data.transportInformation.unNumber],
              ['Shipping Name', data.transportInformation.properShippingName],
              ['Transport Class', data.transportInformation.transportClass],
              ['Packing Group', data.transportInformation.packingGroup],
            ]),

            pw.Spacer(),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated by ChemAI AI Systems',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
                pw.Text(
                  'Date: ${DateTime.now().toString().split(' ').first}',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
              ],
            ),
            if (signatureImage != null) ...[
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(
                        height: 50,
                        width: 100,
                        child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Authorized Signature',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ];
        },
      ),
    );
  }

  pw.Widget _buildTdsColoredHeader(String title, PdfColor color, pw.Font font) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(5),
      decoration: pw.BoxDecoration(color: color),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          font: font,
        ),
      ),
    );
  }

  pw.Widget _buildProfessionalTdsRow(String title, List<List<String>> rows) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 8),
        ...rows.map(
          (row) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 150,
                  child: pw.Text(
                    row[0],
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ),
                pw.Text(': ', style: const pw.TextStyle(fontSize: 11)),
                pw.Expanded(
                  child: pw.Text(
                    row[1],
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
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
