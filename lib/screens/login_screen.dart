import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:chem_ai/core/constants/app_colors.dart';
import 'package:chem_ai/core/services/auth_service.dart';
import 'package:chem_ai/screens/signup_screen.dart';
import 'package:chem_ai/core/utils/navigation_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // AuthWrapper will handle navigation
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Image Section
            Container(
              height: 260,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    "https://lh3.googleusercontent.com/aida-public/AB6AXuDM6rj8nKC8twStD8AImFi2Neft0r6m_YHxkM4uUb2UHVmhxX-kc6fOmh7mt9m-RYYCLESaXZhFzdNGUyZY2j5GDh-0Tjm1_pVfQtjg2aZ01_REZ6k6Rg9Sr5DU48haKDw20Oq2jupGm6kQw5vqvQW37Usl0ToTxQVTZHPa20kXh0p3zbel3l3wSTEOL9Ho0dAMx32larXtuG_yEJt5qFXQHsYoBtCCSAlOYyTQ_lfdnqReaZVHHb5drpf-o7b39YKIveEyHxnKc1Wi",
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      isDark
                          ? AppColors.backgroundDark
                          : AppColors.backgroundLight,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.9],
                  ),
                ),
              ),
            ),

            // Headline Section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Symbols.science,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ChemAI',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tekrar hoş geldin.',
                    style: GoogleFonts.notoSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.grey[400]
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),

            // Form Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Email Field
                  _buildLabel('E-posta Adresi', isDark),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'name@lab.com',
                    icon: Symbols.mail,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),

                  // Password Field
                  _buildLabel('Şifre', isDark),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _passwordController,
                    hintText: '••••••••••',
                    icon: Symbols.lock,
                    isDark: isDark,
                    isPassword: true,
                    isPasswordVisible: _isPasswordVisible,
                    onTogglePassword: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
                  ),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Şifremi Unuttum',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Giriş Yap',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),

                  // Biometric Login
                  const SizedBox(height: 24),
                  Center(
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Symbols.face, size: 32),
                      color: isDark
                          ? Colors.grey[400]
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ChemAI\'da yeni misiniz?',
                  style: TextStyle(
                    color: isDark
                        ? Colors.grey[400]
                        : AppColors.textSecondaryLight,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    NavigationUtils.pushWithSlide(
                      context,
                      const SignupScreen(),
                    );
                  },
                  child: const Text(
                    'Hesap Oluştur',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : AppColors.textMainLight,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isDark,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePassword,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2632) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : const Color(0xFFdce1e5),
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Icon(icon, color: Colors.grey[500], size: 20),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword && !isPasswordVisible,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textMainLight,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
          if (isPassword)
            IconButton(
              onPressed: onTogglePassword,
              icon: Icon(
                isPasswordVisible ? Symbols.visibility : Symbols.visibility_off,
                color: Colors.grey[500],
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}
