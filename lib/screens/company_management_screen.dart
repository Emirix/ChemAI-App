import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chem_ai/core/constants/app_colors.dart';
import 'package:chem_ai/models/company.dart';
import 'package:chem_ai/services/company_service.dart';
import 'package:chem_ai/core/services/profile_service.dart';
import 'package:chem_ai/core/utils/navigation_utils.dart';

class CompanyManagementScreen extends StatefulWidget {
  const CompanyManagementScreen({super.key});

  @override
  State<CompanyManagementScreen> createState() =>
      _CompanyManagementScreenState();
}

class _CompanyManagementScreenState extends State<CompanyManagementScreen> {
  final CompanyService _companyService = CompanyService();
  final ProfileService _profileService = ProfileService();

  List<Company> _companies = [];
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // First try to get userId from service
      _userId = _profileService.userId;

      if (_userId != null) {
        final companies = await _companyService.getCompanies(_userId!);
        setState(() {
          _companies = companies;
        });
      } else {
        // Fallback: try fetching profile if auth userId is somehow null
        final profile = await _profileService.getProfile();
        if (profile != null) {
          _userId = profile['id'] as String?;
          if (_userId != null) {
            final companies = await _companyService.getCompanies(_userId!);
            setState(() {
              _companies = companies;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCompany(Company company) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Firmayı Sil'),
        content: Text(
          '"${company.companyName}" firmasını silmek istediğinize emin misiniz?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && company.id != null && _userId != null) {
      try {
        final success = await _companyService.deleteCompany(
          company.id!,
          _userId!,
        );
        if (success) {
          _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Firma başarıyla silindi'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      }
    }
  }

  Future<void> _setDefaultCompany(Company company) async {
    if (company.id == null || _userId == null) return;

    try {
      final updated = await _companyService.setDefaultCompany(
        company.id!,
        _userId!,
      );
      if (updated != null) {
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Varsayılan firma güncellendi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  void _showCompanyForm({Company? company}) {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kullanıcı bilgisi yüklenemedi. Lütfen tekrar deneyin.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CompanyFormScreen(company: company, userId: _userId!),
      ),
    ).then((value) {
      if (value == true) {
        _loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _companies.isEmpty
                  ? _buildEmptyState(isDark)
                  : _buildCompanyList(isDark),
            ),
          ],
        ),
      ),
      floatingActionButton: _userId != null
          ? FloatingActionButton.extended(
              onPressed: () => _showCompanyForm(),
              backgroundColor: AppColors.primary,
              icon: const Icon(Symbols.add, color: Colors.white),
              label: const Text(
                'Yeni Firma',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: isDark ? Colors.white : Colors.black87,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Firma Yönetimi',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                Text(
                  '${_companies.length} firma',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Symbols.business, size: 80, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz firma eklenmedi',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'TDS ve SDS belgelerine eklemek için firma bilgilerinizi kaydedin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showCompanyForm(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Symbols.add),
              label: const Text('İlk Firmayı Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: _companies.length,
      itemBuilder: (context, index) {
        final company = _companies[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCompanyCard(company, isDark),
        );
      },
    );
  }

  Widget _buildCompanyCard(Company company, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: company.isDefault
              ? AppColors.primary
              : isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          width: company.isDefault ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: company.isDefault
                ? AppColors.primary.withOpacity(0.1)
                : Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showCompanyForm(company: company),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Symbols.business,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  company.companyName,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (company.isDefault)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'VARSAYILAN',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            company.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (company.getFullAddress().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Symbols.location_on,
                        size: 16,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          company.getFullAddress(),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (company.phone != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Symbols.phone,
                        size: 16,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        company.phone!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (!company.isDefault)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _setDefaultCompany(company),
                          icon: const Icon(Symbols.star, size: 16),
                          label: const Text('Varsayılan Yap'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    if (!company.isDefault) const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showCompanyForm(company: company),
                        icon: const Icon(Symbols.edit, size: 16),
                        label: const Text('Düzenle'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? Colors.white
                              : Colors.black87,
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _deleteCompany(company),
                      icon: const Icon(Symbols.delete, color: Colors.red),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Company Form Screen
class CompanyFormScreen extends StatefulWidget {
  final Company? company;
  final String userId;

  const CompanyFormScreen({super.key, this.company, required this.userId});

  @override
  State<CompanyFormScreen> createState() => _CompanyFormScreenState();
}

class _CompanyFormScreenState extends State<CompanyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final CompanyService _companyService = CompanyService();

  late TextEditingController _companyNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;
  late TextEditingController _websiteController;
  late TextEditingController _faxController;

  bool _isDefault = false;
  bool _isSaving = false;
  String? _logoUrl;
  String? _signatureUrl;
  bool _isUploadingLogo = false;
  bool _isUploadingSignature = false;
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    final company = widget.company;

    _companyNameController = TextEditingController(
      text: company?.companyName ?? '',
    );
    _emailController = TextEditingController(text: company?.email ?? '');
    _phoneController = TextEditingController(text: company?.phone ?? '');
    _emergencyPhoneController = TextEditingController(
      text: company?.emergencyPhone ?? '',
    );
    _addressController = TextEditingController(text: company?.address ?? '');
    _cityController = TextEditingController(text: company?.city ?? '');
    _postalCodeController = TextEditingController(
      text: company?.postalCode ?? '',
    );
    _countryController = TextEditingController(text: company?.country ?? '');
    _websiteController = TextEditingController(text: company?.website ?? '');
    _faxController = TextEditingController(text: company?.fax ?? '');
    _isDefault = company?.isDefault ?? false;
    _logoUrl = company?.logoUrl;
    _signatureUrl = company?.signatureUrl;
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _emergencyPhoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _websiteController.dispose();
    _faxController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 512,
    );

    if (image != null && mounted) {
      setState(() => _isUploadingLogo = true);
      try {
        final url = await _profileService.uploadImage(
          File(image.path),
          'company_logos',
          widget.userId,
        );

        if (url != null && mounted) {
          setState(() => _logoUrl = url);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Logo yükleme hatası: $e')));
        }
      } finally {
        if (mounted) setState(() => _isUploadingLogo = false);
      }
    }
  }

  Future<void> _pickSignature() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 512,
    );

    if (image != null && mounted) {
      setState(() => _isUploadingSignature = true);
      try {
        final url = await _profileService.uploadImage(
          File(image.path),
          'company_logos',
          widget.userId,
        );

        if (url != null && mounted) {
          setState(() => _signatureUrl = url);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('İmza yükleme hatası: $e')));
        }
      } finally {
        if (mounted) setState(() => _isUploadingSignature = false);
      }
    }
  }

  Future<void> _saveCompany() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final company = Company(
        id: widget.company?.id,
        userId: widget.userId,
        companyName: _companyNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        emergencyPhone: _emergencyPhoneController.text.trim().isEmpty
            ? null
            : _emergencyPhoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        postalCode: _postalCodeController.text.trim().isEmpty
            ? null
            : _postalCodeController.text.trim(),
        country: _countryController.text.trim().isEmpty
            ? null
            : _countryController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        fax: _faxController.text.trim().isEmpty
            ? null
            : _faxController.text.trim(),
        logoUrl: _logoUrl,
        signatureUrl: _signatureUrl,
        isDefault: _isDefault,
      );

      Company? result;
      if (widget.company == null) {
        result = await _companyService.createCompany(company);
      } else {
        result = await _companyService.updateCompany(company);
      }

      if (result != null && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.company == null
                  ? 'Firma başarıyla eklendi'
                  : 'Firma başarıyla güncellendi',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Temel Bilgiler *', isDark),
                      const SizedBox(height: 12),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildImagePicker(
                            isDark: isDark,
                            label: 'Logo',
                            imageUrl: _logoUrl,
                            isUploading: _isUploadingLogo,
                            onTap: _pickImage,
                            onRemove: () => setState(() => _logoUrl = null),
                          ),
                          const SizedBox(width: 32),
                          _buildImagePicker(
                            isDark: isDark,
                            label: 'Dijital İmza',
                            imageUrl: _signatureUrl,
                            isUploading: _isUploadingSignature,
                            onTap: _pickSignature,
                            onRemove: () => setState(() => _signatureUrl = null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: _companyNameController,
                        label: 'Şirket Adı',
                        hint: 'Kimya Grup A.Ş.',
                        icon: Symbols.business,
                        isDark: isDark,
                        isRequired: true,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _emailController,
                        label: 'E-posta',
                        hint: 'info@kimyagrup.com',
                        icon: Symbols.email,
                        isDark: isDark,
                        isRequired: true,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('İletişim Bilgileri', isDark),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Telefon',
                        hint: '+90 212 XXX XX XX',
                        icon: Symbols.phone,
                        isDark: isDark,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _emergencyPhoneController,
                        label: 'Acil Durum Telefonu',
                        hint: '+90 212 XXX XX XX',
                        icon: Symbols.emergency,
                        isDark: isDark,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _websiteController,
                        label: 'Website',
                        hint: 'www.kimyagrup.com',
                        icon: Symbols.language,
                        isDark: isDark,
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _faxController,
                        label: 'Fax (Opsiyonel)',
                        hint: '+90 212 XXX XX XX',
                        icon: Symbols.fax,
                        isDark: isDark,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Adres Bilgileri', isDark),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _addressController,
                        label: 'Adres',
                        hint: 'Örnek Mahallesi, Kimya Sokak No:1',
                        icon: Symbols.location_on,
                        isDark: isDark,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              controller: _cityController,
                              label: 'Şehir',
                              hint: 'İstanbul',
                              icon: Symbols.location_city,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _postalCodeController,
                              label: 'Posta Kodu',
                              hint: '34000',
                              icon: Symbols.markunread_mailbox,
                              isDark: isDark,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _countryController,
                        label: 'Ülke',
                        hint: 'Türkiye',
                        icon: Symbols.public,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),
                      _buildDefaultCheckbox(isDark),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveCompany,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  widget.company == null
                                      ? 'Firmayı Ekle'
                                      : 'Değişiklikleri Kaydet',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: isDark ? Colors.white : Colors.black87,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            widget.company == null ? 'Yeni Firma Ekle' : 'Firmayı Düzenle',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label gereklidir';
              }
              if (label == 'E-posta' && !value.contains('@')) {
                return 'Geçerli bir e-posta adresi girin';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildDefaultCheckbox(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          'Varsayılan firma olarak ayarla',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'TDS ve SDS belgelerinde otomatik kullanılsın',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        value: _isDefault,
        onChanged: (value) {
          setState(() => _isDefault = value ?? false);
        },
        activeColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildImagePicker({
    required bool isDark,
    required String label,
    required String? imageUrl,
    required bool isUploading,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: isUploading ? null : onTap,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.3),
                width: 2,
              ),
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.contain,
                    )
                  : null,
            ),
            child: isUploading
                ? const Center(child: CircularProgressIndicator())
                : imageUrl == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Symbols.add_a_photo,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        ),
        if (imageUrl != null)
          TextButton(
            onPressed: onRemove,
            child: Text(
              '$label Kaldır',
              style: const TextStyle(color: Colors.red, fontSize: 11),
            ),
          ),
      ],
    );
  }
}
