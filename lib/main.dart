import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chem_ai/core/constants/app_colors.dart';
import 'package:chem_ai/l10n/app_localizations.dart';
import 'package:chem_ai/screens/home_screen.dart';
import 'package:chem_ai/screens/login_screen.dart';
import 'package:chem_ai/screens/onboarding_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:chem_ai/firebase_options.dart';
import 'package:chem_ai/services/notification_service.dart';
import 'package:chem_ai/services/analytics_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:chem_ai/core/services/http_client_service.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Semantik yapıyı zorunlu olarak başlatalım.
  // Bu, ekran alma (ss) araçlarının ve asistan özelliklerinin çalışmasını sağlar.
  RendererBinding.instance.pipelineOwner.ensureSemantics();

  // Initialize HTTP client service for connection pooling
  HttpClientService().initialize();

  await Supabase.initialize(
    url: 'https://lvwlwdnhgvzmlcskttgk.supabase.co',
    anonKey: 'sb_publishable_urTn579iK7lnioxH3nlynw_9Q4gdLQ2',
  );
  
  // Firebase Başlatma
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Crashlytics Yapılandırması
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    
    // Asenkron hataları yakalamak için
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('⚠️ Firebase başlatılamadı: $e');
  }

  FlutterNativeSplash.remove();
  runApp(const ChemAIApp());
}

class ChemAIApp extends StatefulWidget {
  const ChemAIApp({super.key});

  @override
  State<ChemAIApp> createState() => ChemAIAppState();

  static ChemAIAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<ChemAIAppState>();
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ChemAIAppState extends State<ChemAIApp> {
  Locale _locale = const Locale('tr');

  void setLocale(Locale newLocale) {
    setState(() {
      _locale = newLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChemAI',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorObservers: [AnalyticsService().analyticsObserver],
      locale: _locale,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surfaceLight,
        ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
        textTheme: GoogleFonts.notoSansTextTheme(),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surfaceDark,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.backgroundDark,
        textTheme: GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme),
      ),
      themeMode: ThemeMode.system,
      home: const OnboardingWrapper(),
    );
  }
}

class OnboardingWrapper extends StatelessWidget {
  const OnboardingWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkOnboardingStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final hasCompletedOnboarding = snapshot.data ?? false;

        if (!hasCompletedOnboarding) {
          return const OnboardingScreen();
        }

        return const AuthWrapper();
      },
    );
  }

  Future<bool> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;
        if (session != null) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

