import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chem_ai/core/services/subscription_service.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  bool _showAd = false;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    final isPlus = await SubscriptionService().isPlus();
    if (mounted) {
      setState(() {
        _showAd = !isPlus; // Show ad if NOT plus
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showAd) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.grey[200],
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'REKLAM',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'ChemAI Plus ile reklamsız deneyimin tadını çıkarın.',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
