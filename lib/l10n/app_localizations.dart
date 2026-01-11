import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

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
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'My Day One'**
  String get appTitle;

  /// No description provided for @searchEntriesHint.
  ///
  /// In en, this message translates to:
  /// **'Search entries'**
  String get searchEntriesHint;

  /// No description provided for @noEntriesTitle.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get noEntriesTitle;

  /// No description provided for @noEntriesBody.
  ///
  /// In en, this message translates to:
  /// **'Tap + to start your first journal entry.'**
  String get noEntriesBody;

  /// No description provided for @newEntry.
  ///
  /// In en, this message translates to:
  /// **'New entry'**
  String get newEntry;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @noContent.
  ///
  /// In en, this message translates to:
  /// **'No content yet'**
  String get noContent;

  /// No description provided for @editEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get editEntryTitle;

  /// No description provided for @newEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'New entry'**
  String get newEntryTitle;

  /// No description provided for @entryTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get entryTitleLabel;

  /// No description provided for @entryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Entry date'**
  String get entryDateLabel;

  /// No description provided for @entryDatePickerHelp.
  ///
  /// In en, this message translates to:
  /// **'Select entry date'**
  String get entryDatePickerHelp;

  /// Shown when the selected date is today
  ///
  /// In en, this message translates to:
  /// **'{date} (Today)'**
  String entryDateTodayLabel(String date);

  /// No description provided for @insertImage.
  ///
  /// In en, this message translates to:
  /// **'Insert image'**
  String get insertImage;

  /// No description provided for @moreFormatting.
  ///
  /// In en, this message translates to:
  /// **'More formatting'**
  String get moreFormatting;

  /// No description provided for @entryDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Entry'**
  String get entryDetailTitle;

  /// No description provided for @entryNotFound.
  ///
  /// In en, this message translates to:
  /// **'Entry not found.'**
  String get entryNotFound;

  /// No description provided for @deleteEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete entry?'**
  String get deleteEntryTitle;

  /// No description provided for @deleteEntryMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove the entry from your journal.'**
  String get deleteEntryMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @appLockTitle.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get appLockTitle;

  /// No description provided for @appLockSubtitleChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking device security...'**
  String get appLockSubtitleChecking;

  /// No description provided for @appLockSubtitleEnabled.
  ///
  /// In en, this message translates to:
  /// **'Require biometrics or device passcode'**
  String get appLockSubtitleEnabled;

  /// No description provided for @appLockSubtitleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Device authentication is not available'**
  String get appLockSubtitleUnavailable;

  /// No description provided for @lockAfterLabel.
  ///
  /// In en, this message translates to:
  /// **'Lock after'**
  String get lockAfterLabel;

  /// No description provided for @lockAfterImmediately.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get lockAfterImmediately;

  /// No description provided for @lockAfter1Min.
  ///
  /// In en, this message translates to:
  /// **'After 1 minute'**
  String get lockAfter1Min;

  /// No description provided for @lockAfter5Min.
  ///
  /// In en, this message translates to:
  /// **'After 5 minutes'**
  String get lockAfter5Min;

  /// No description provided for @lockAfter15Min.
  ///
  /// In en, this message translates to:
  /// **'After 15 minutes'**
  String get lockAfter15Min;

  /// No description provided for @appLockTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'App lock tips'**
  String get appLockTipsTitle;

  /// No description provided for @appLockTipsBody.
  ///
  /// In en, this message translates to:
  /// **'- Uses device biometrics or passcode\n- Lock after only applies when the app is in background\n- Keep device security enabled for best protection'**
  String get appLockTipsBody;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get learnMore;

  /// No description provided for @appLockHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'App lock help'**
  String get appLockHelpTitle;

  /// No description provided for @appLockHelpBody.
  ///
  /// In en, this message translates to:
  /// **'App lock requires device authentication. If you disable biometrics or passcode at the system level, app lock will stop working.\n\nLock after only triggers when the app is backgrounded. It does not lock while you are actively using the app.'**
  String get appLockHelpBody;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @journalLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Journal locked'**
  String get journalLockedTitle;

  /// No description provided for @journalLockedBody.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to continue.'**
  String get journalLockedBody;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @unlockReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock your journal'**
  String get unlockReason;

  /// No description provided for @enableAppLockReason.
  ///
  /// In en, this message translates to:
  /// **'Enable app lock'**
  String get enableAppLockReason;

  /// No description provided for @disableAppLockReason.
  ///
  /// In en, this message translates to:
  /// **'Disable app lock'**
  String get disableAppLockReason;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// Title for a day-based entries list
  ///
  /// In en, this message translates to:
  /// **'Entries on {date}'**
  String entriesOnDateTitle(String date);
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
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
