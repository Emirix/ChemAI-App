import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:chem_ai/core/constants/app_colors.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Symbols.arrow_back,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sıkça Sorulan Sorular',
          style: GoogleFonts.spaceGrotesk(
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFaqItem(
            context,
            isDark,
            question: 'Plus üyelik neleri kapsar?',
            answer:
                'Plus üyelik ile sınırsız AI sohbeti, gelişmiş deney planlayıcı, öncelikli destek ve detaylı analiz raporlarına erişim sağlarsınız.',
          ),
          _buildFaqItem(
            context,
            isDark,
            question: 'Üyeliğimi istediğim zaman iptal edebilir miyim?',
            answer:
                'Evet, üyeliğinizi dilediğiniz zaman profil ayarlarından iptal edebilirsiniz. İptal işlemi bir sonraki fatura döneminden itibaren geçerli olur.',
          ),
          _buildFaqItem(
            context,
            isDark,
            question: 'Ödemelerim güvende mi?',
            answer:
                'Kesinlikle. Ödemeleriniz endüstri standardı şifreleme yöntemleri ile korunmaktadır ve güvenli ödeme altyapısı üzerinden işlenir.',
          ),
          _buildFaqItem(
            context,
            isDark,
            question: 'Fatura alabilir miyim?',
            answer:
                'Evet, ödeme işleminiz tamamlandıktan sonra kayıtlı e-posta adresinize faturanız otomatik olarak gönderilecektir.',
          ),
          _buildFaqItem(
            context,
            isDark,
            question: 'Öğrenci indirimi var mı?',
            answer:
                'Şu an için doğrudan öğrenci indirimi bulunmamaktadır ancak dönemsel kampanyalarımızı takip edebilirsiniz.',
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(
    BuildContext context,
    bool isDark, {
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: GoogleFonts.notoSans(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
