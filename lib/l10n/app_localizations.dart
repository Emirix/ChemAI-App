import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'ChemAI'**
  String get appTitle;

  /// No description provided for @goodMorning.
  ///
  /// In tr, this message translates to:
  /// **'Merhaba,'**
  String get goodMorning;

  /// No description provided for @drSmith.
  ///
  /// In tr, this message translates to:
  /// **'Dr. Emir'**
  String get drSmith;

  /// No description provided for @searchHint.
  ///
  /// In tr, this message translates to:
  /// **'CAS#, İsim veya Formül Ara'**
  String get searchHint;

  /// No description provided for @aiTools.
  ///
  /// In tr, this message translates to:
  /// **'AI Araçları'**
  String get aiTools;

  /// No description provided for @viewAll.
  ///
  /// In tr, this message translates to:
  /// **'Hepsini Gör'**
  String get viewAll;

  /// No description provided for @reactionAssistant.
  ///
  /// In tr, this message translates to:
  /// **'Reaksiyon Asistanı'**
  String get reactionAssistant;

  /// No description provided for @reactionAssistantDesc.
  ///
  /// In tr, this message translates to:
  /// **'Sonuçları tahmin et ve optimize et.'**
  String get reactionAssistantDesc;

  /// No description provided for @safetyData.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik Verileri'**
  String get safetyData;

  /// No description provided for @safetyDataDesc.
  ///
  /// In tr, this message translates to:
  /// **'Anlık SDS ve GHS bilgileri.'**
  String get safetyDataDesc;

  /// No description provided for @visionAi.
  ///
  /// In tr, this message translates to:
  /// **'Görüntü İşleme AI'**
  String get visionAi;

  /// No description provided for @visionAiDesc.
  ///
  /// In tr, this message translates to:
  /// **'Etiketleri ve yapıları tara.'**
  String get visionAiDesc;

  /// No description provided for @reportsAnalysis.
  ///
  /// In tr, this message translates to:
  /// **'Raporlar ve Analiz'**
  String get reportsAnalysis;

  /// No description provided for @reportsAnalysisDesc.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik detaylı raporlar oluştur.'**
  String get reportsAnalysisDesc;

  /// No description provided for @recentActivity.
  ///
  /// In tr, this message translates to:
  /// **'Son Aktiviteler'**
  String get recentActivity;

  /// No description provided for @synthesisOfIbuprofen.
  ///
  /// In tr, this message translates to:
  /// **'Sentez Analizi'**
  String get synthesisOfIbuprofen;

  /// No description provided for @reactionAnalysis.
  ///
  /// In tr, this message translates to:
  /// **'Reaksiyon Analizi'**
  String get reactionAnalysis;

  /// No description provided for @benzeneMsdsLookup.
  ///
  /// In tr, this message translates to:
  /// **'Benzen SDS Sorgulama'**
  String get benzeneMsdsLookup;

  /// No description provided for @safetyCheck.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik Kontrolü'**
  String get safetyCheck;

  /// No description provided for @twoHoursAgo.
  ///
  /// In tr, this message translates to:
  /// **'2 saat önce'**
  String get twoHoursAgo;

  /// No description provided for @fiveHoursAgo.
  ///
  /// In tr, this message translates to:
  /// **'5 saat önce'**
  String get fiveHoursAgo;

  /// No description provided for @home.
  ///
  /// In tr, this message translates to:
  /// **'Anasayfa'**
  String get home;

  /// No description provided for @history.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// No description provided for @hazardsGhs.
  ///
  /// In tr, this message translates to:
  /// **'TEHLİKELER (GHS)'**
  String get hazardsGhs;

  /// No description provided for @requiredPpe.
  ///
  /// In tr, this message translates to:
  /// **'GEREKEN KKD'**
  String get requiredPpe;

  /// No description provided for @handling.
  ///
  /// In tr, this message translates to:
  /// **'KULLANIM VE TAŞIMA'**
  String get handling;

  /// No description provided for @storage.
  ///
  /// In tr, this message translates to:
  /// **'DEPOLAMA'**
  String get storage;

  /// No description provided for @viewFullMsds.
  ///
  /// In tr, this message translates to:
  /// **'Tam SDS PDF\'ini Görüntüle'**
  String get viewFullMsds;

  /// No description provided for @quickReference.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı Referans'**
  String get quickReference;

  /// No description provided for @incompatibleMixture.
  ///
  /// In tr, this message translates to:
  /// **'Uyumsuz Karışım'**
  String get incompatibleMixture;

  /// No description provided for @aiRiskAlert.
  ///
  /// In tr, this message translates to:
  /// **'AI RİSK UYARISI'**
  String get aiRiskAlert;

  /// No description provided for @viewDetails.
  ///
  /// In tr, this message translates to:
  /// **'DETAYLARI GÖR'**
  String get viewDetails;

  /// No description provided for @firstAid.
  ///
  /// In tr, this message translates to:
  /// **'İlk Yardım'**
  String get firstAid;

  /// No description provided for @firefighting.
  ///
  /// In tr, this message translates to:
  /// **'Yangınla Mücadele'**
  String get firefighting;

  /// No description provided for @emergency.
  ///
  /// In tr, this message translates to:
  /// **'Acil Durum'**
  String get emergency;

  /// No description provided for @quickLook.
  ///
  /// In tr, this message translates to:
  /// **'Genel Bakış'**
  String get quickLook;

  /// No description provided for @physicalProperties.
  ///
  /// In tr, this message translates to:
  /// **'Fiziksel Özellikler'**
  String get physicalProperties;

  /// No description provided for @addItem.
  ///
  /// In tr, this message translates to:
  /// **'Öğe Ekle'**
  String get addItem;

  /// No description provided for @edit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get edit;

  /// No description provided for @status.
  ///
  /// In tr, this message translates to:
  /// **'Durum'**
  String get status;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// No description provided for @aiGeneratingSds.
  ///
  /// In tr, this message translates to:
  /// **'Yapay Zeka tarafından SDS oluşturuluyor...'**
  String get aiGeneratingSds;

  /// No description provided for @aiGeneratingTds.
  ///
  /// In tr, this message translates to:
  /// **'Yapay Zeka tarafından TDS oluşturuluyor...'**
  String get aiGeneratingTds;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
