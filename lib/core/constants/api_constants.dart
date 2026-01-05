import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiConstants {
  // Base API URL configuration
  static String get baseUrl {
    // Port 3006 is used for ChemAI main API
    const String port = '3006';

    if (kIsWeb) return 'http://localhost:$port/api';

    try {
      if (Platform.isAndroid || Platform.isIOS || Platform.isWindows) {
        // 
        return 'http://192.168.1.9:$port/api';
       // return 'https://chemai.flowgenix.fun/api';
      }
    } catch (e) {
      // Platform check can fail on web, but kIsWeb handles it above
    }
    return 'http://192.168.1.9:$port/api';
  }

  // Endpoints
  static const String chat = '/chat';
  static const String analyzeSds = '/analyze-sds';
  static const String safetyData = '/safety-data';
  static const String rawMaterialDetails = '/raw-material-details';
  static const String tdsData = '/tds-data';
  static const String generateMetadata = '/chat/generate-metadata';
}
