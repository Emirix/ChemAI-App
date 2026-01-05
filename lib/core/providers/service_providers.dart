import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chem_ai/services/api_service.dart';
import 'package:chem_ai/services/analytics_service.dart';
import 'package:chem_ai/services/barcode_service.dart';
import 'package:chem_ai/services/chat_service.dart';
import 'package:chem_ai/services/chemical_service.dart';
import 'package:chem_ai/services/company_service.dart';
import 'package:chem_ai/services/favorites_service.dart';
import 'package:chem_ai/services/feedback_service.dart';
import 'package:chem_ai/services/news_service.dart';
import 'package:chem_ai/services/notification_service.dart';
import 'package:chem_ai/services/pdf_service.dart';
import 'package:chem_ai/services/search_history_service.dart';
import 'package:chem_ai/services/storage_service.dart';
import 'package:chem_ai/services/view_history_service.dart';
import 'package:chem_ai/core/services/profile_service.dart';

/// Provides the global Supabase client instance.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Streams authentication state changes from Supabase.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

/// Provides the current authenticated user.
final userProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  return authState?.session?.user;
});

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final analyticsServiceProvider = Provider<AnalyticsService>((ref) => AnalyticsService());
final barcodeServiceProvider = Provider<BarcodeService>((ref) {
  final service = BarcodeService();
  ref.onDispose(() => service.dispose());
  return service;
});
final chatServiceProvider = Provider<ChatService>((ref) => ChatService());
final chemicalServiceProvider = Provider<ChemicalService>((ref) => ChemicalService());
final companyServiceProvider = Provider<CompanyService>((ref) => CompanyService());
final favoritesServiceProvider = ChangeNotifierProvider<FavoritesService>((ref) => FavoritesService());
final feedbackServiceProvider = Provider<FeedbackService>((ref) => FeedbackService());
final newsServiceProvider = Provider<NewsService>((ref) => NewsService());
final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());
final pdfServiceProvider = Provider<PdfService>((ref) => PdfService());
final searchHistoryServiceProvider = ChangeNotifierProvider<SearchHistoryService>((ref) => SearchHistoryService());
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final viewHistoryServiceProvider = ChangeNotifierProvider<ViewHistoryService>((ref) => ViewHistoryService());
final profileServiceProvider = Provider<ProfileService>((ref) => ProfileService());
