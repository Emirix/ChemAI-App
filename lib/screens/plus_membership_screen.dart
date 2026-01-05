import 'package:chem_ai/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:chem_ai/screens/faq_screen.dart';

class PlusMembershipScreen extends StatefulWidget {
  const PlusMembershipScreen({super.key});

  @override
  State<PlusMembershipScreen> createState() => _PlusMembershipScreenState();
}

class _PlusMembershipScreenState extends State<PlusMembershipScreen> {
  String _selectedPlan = 'annual'; // 'annual' or 'monthly'

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final Color textColor = isDark
        ? AppColors.textMainDark
        : AppColors.textMainLight;
    final Color textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final Color cardColor = isDark ? AppColors.surfaceDark : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Symbols.arrow_back, color: textColor),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'ChemAI Plus',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for centering
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  100,
                ), // Bottom padding for sticky footer
                child: Column(
                  children: [
                    // Hero Section
                    Text(
                      'Laboratuvarınızın Tüm Potansiyelini Ortaya Çıkarın',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Profesyoneller için geliştirilmiş yapay zeka araçlarıyla araştırmalarınızı hızlandırın.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        color: textSecondary,
                      ),
                    ),

                    // Gradient Line
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(vertical: 24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.primary.withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    // Benefits List
                    _buildBenefitItem(
                      icon: Symbols.all_inclusive,
                      title: 'Sınırsız AI Sohbeti',
                      description:
                          'Karmaşık kimyasal sorularınızı sınırsızca sorun.',
                      isDark: isDark,
                      textColor: textColor,
                      textSecondary: textSecondary,
                      cardColor: cardColor,
                    ),
                    const SizedBox(height: 12),
                    _buildBenefitItem(
                      icon: Symbols.science,
                      title: 'Deney Planlayıcı',
                      description:
                          'AI destekli protokoller ve güvenlik kontrolleri.',
                      isDark: isDark,
                      textColor: textColor,
                      textSecondary: textSecondary,
                      cardColor: cardColor,
                    ),
                    const SizedBox(height: 12),
                    _buildBenefitItem(
                      icon: Symbols.support_agent,
                      title: 'Öncelikli Destek',
                      description: 'Bilimsel destek ekibimize doğrudan erişim.',
                      isDark: isDark,
                      textColor: textColor,
                      textSecondary: textSecondary,
                      cardColor: cardColor,
                    ),
                    const SizedBox(height: 12),
                    _buildBenefitItem(
                      icon: Symbols.analytics,
                      title: 'Detaylı Raporlar',
                      description:
                          'Araştırma verileriniz için derinlemesine analizler.',
                      isDark: isDark,
                      textColor: textColor,
                      textSecondary: textSecondary,
                      cardColor: cardColor,
                    ),

                    const SizedBox(height: 32),

                    // Pricing Section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Planınızı Seçin',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Annual Plan
                    _buildPlanCard(
                      id: 'annual',
                      title: 'Yıllık',
                      price: '₺199.99',
                      period: '/ yıl',
                      subtitle: 'Yıllık faturalandırılır. Ayda ~16.66₺.',
                      badge: 'En Popüler',
                      save: '%20 İndirim',
                      isDark: isDark,
                      textColor: textColor,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 16),

                    // Monthly Plan
                    _buildPlanCard(
                      id: 'monthly',
                      title: 'Aylık',
                      price: '₺19.99',
                      period: '/ ay',
                      subtitle:
                          'Esnek faturalandırma. İstediğiniz zaman iptal edin.',
                      isDark: isDark,
                      textColor: textColor,
                      textSecondary: textSecondary,
                    ),

                    const SizedBox(height: 32),

                    // FAQ Link
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FaqScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Sorularınız mı var? SSS sayfamızı inceleyin',
                        style: GoogleFonts.notoSans(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sticky Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey[200]!,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          // Purchase Logic
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          shadowColor: AppColors.primary.withOpacity(0.5),
                        ),
                        child: Text(
                          'Plus\'a Yükselt',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFooterLink(
                          'Satın Alımı Geri Yükle',
                          textSecondary,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '•',
                            style: TextStyle(color: textSecondary),
                          ),
                        ),
                        _buildFooterLink('Kullanım Koşulları', textSecondary),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '•',
                            style: TextStyle(color: textSecondary),
                          ),
                        ),
                        _buildFooterLink('Gizlilik', textSecondary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
    required Color textColor,
    required Color textSecondary,
    required Color cardColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String id,
    required String title,
    required String price,
    required String period,
    required String subtitle,
    String? badge,
    String? save,
    required bool isDark,
    required Color textColor,
    required Color textSecondary,
  }) {
    final bool isSelected = _selectedPlan == id;
    final Color borderColor = isSelected
        ? AppColors.primary
        : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!);
    final Color backgroundColor = isSelected
        ? AppColors.primary.withOpacity(isDark ? 0.1 : 0.05)
        : (isDark ? AppColors.surfaceDark : Colors.white);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = id;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.notoSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: textColor,
                  ),
                ),
                if (save != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      save,
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  )
                else
                  // Radio button circle for visual choice
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  period,
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.notoSans(fontSize: 13, color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterLink(String text, Color color) {
    return GestureDetector(
      onTap: () {},
      child: Text(text, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}
