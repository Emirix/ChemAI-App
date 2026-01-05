import 'package:flutter/material.dart';

class LanguageUtils {
  static String getLanguageString(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    switch (locale) {
      case 'tr':
        return 'Turkish';
      case 'en':
        return 'English';
      default:
        return 'English';
    }
  }
}
