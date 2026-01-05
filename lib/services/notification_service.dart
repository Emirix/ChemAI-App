import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:chem_ai/main.dart';
import 'package:chem_ai/screens/safety_data_screen.dart';
import 'package:chem_ai/screens/tds_screen.dart';
import 'package:chem_ai/core/utils/navigation_utils.dart';
import 'package:chem_ai/core/services/profile_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. İzin iste (iOS/Android için)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('🔔 User granted notification permission');
    }

    // 2. Local Notifications Ayarları
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Bildirime tıklandığında yapılacak işlemler
        debugPrint('🔔 Local Notification clicked: ${details.payload}');
        if (details.payload != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(details.payload!);
            _handleNotificationClick(data);
          } catch (e) {
            debugPrint('❌ Error parsing notification payload: $e');
          }
        }
      },
    );

    // 3. Ön Plandayken (Foreground) Bildirimleri Al
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 Foreground Message received: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // 4. Arka Plandayken Bildirime Tıklandığında
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 Background Message clicked: ${message.notification?.title}');
      _handleNotificationClick(message.data);
    });

    // 4.1. Uygulama kapalıyken (Terminated) bildirime tıklandıysa
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('🔔 Initial Message received: ${message.notification?.title}');
        // Biraz bekle navigator Key hazır olsun
        Future.delayed(const Duration(milliseconds: 1000), () {
          _handleNotificationClick(message.data);
        });
      }
    });

    // 5. Token Güncelleme
    _fcm.onTokenRefresh.listen((newToken) {
      _saveTokenToSupabase(newToken);
    });

    // 6. Giriş durumunu takip et ve tokenı kaydet
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) {
        final token = await _fcm.getToken();
        if (token != null) {
          _saveTokenToSupabase(token);
        }
      }
    });

    // İlk açılışta tokenı al (Eğer zaten giriş yapılmışsa)
    final token = await _fcm.getToken();
    if (token != null) {
      debugPrint('🔔 FCM Token: $token');
      _saveTokenToSupabase(token);
    }

    // 7. Haberler başlığına abone ol
    await _fcm.subscribeToTopic('news');
    debugPrint('🔔 Subscribed to "news" topic');
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'chemai_notifications',
      'ChemAI Bildirimleri',
      channelDescription: 'Uygulama bildirimleri için kanal',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformDetails,
      payload: jsonEncode(message.data),
    );
  }

  void _handleNotificationClick(Map<String, dynamic> data) {
    debugPrint('🔔 Handling notification click with data: $data');
    
    final String? type = data['type'];
    final String? productName = data['product_name'];

    if (type == null || productName == null) return;

    // Navigator hazır olana kadar bekle (özellikle cold start için)
    if (navigatorKey.currentState == null) {
      debugPrint('⚠️ Navigator state is null, retrying in 500ms');
      Future.delayed(const Duration(milliseconds: 500), () => _handleNotificationClick(data));
      return;
    }

    final context = navigatorKey.currentContext!;

    // Kullanıcı giriş yapmamışsa yönlendirme yapma
    if (ProfileService().userId == null) {
      debugPrint('⚠️ User not logged in, skipping navigation');
      return;
    }

    if (type == 'sds') {
      NavigationUtils.pushWithSlide(
        context,
        SafetyDataScreen(initialQuery: productName),
      );
    } else if (type == 'tds') {
      NavigationUtils.pushWithSlide(
        context,
        TdsScreen(initialQuery: productName),
      );
    }
  }

  Future<void> _saveTokenToSupabase(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client
            .from('profiles')
            .update({'fcm_token': token})
            .eq('id', user.id);
        debugPrint('✅ FCM Token saved to Supabase');
      } catch (e) {
        debugPrint('❌ Error saving token to Supabase: $e');
      }
    }
  }
}
