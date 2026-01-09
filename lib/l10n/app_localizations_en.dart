// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'My Day One';

  @override
  String get searchEntriesHint => 'Search entries';

  @override
  String get noEntriesTitle => 'No entries yet';

  @override
  String get noEntriesBody => 'Tap + to start your first journal entry.';

  @override
  String get newEntry => 'New entry';

  @override
  String get untitled => 'Untitled';

  @override
  String get noContent => 'No content yet';

  @override
  String get editEntryTitle => 'Edit entry';

  @override
  String get newEntryTitle => 'New entry';

  @override
  String get entryTitleLabel => 'Title';

  @override
  String get insertImage => 'Insert image';

  @override
  String get entryDetailTitle => 'Entry';

  @override
  String get entryNotFound => 'Entry not found.';

  @override
  String get deleteEntryTitle => 'Delete entry?';

  @override
  String get deleteEntryMessage =>
      'This will remove the entry from your journal.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appLockTitle => 'App lock';

  @override
  String get appLockSubtitleChecking => 'Checking device security...';

  @override
  String get appLockSubtitleEnabled => 'Require biometrics or device passcode';

  @override
  String get appLockSubtitleUnavailable =>
      'Device authentication is not available';

  @override
  String get lockAfterLabel => 'Lock after';

  @override
  String get lockAfterImmediately => 'Immediately';

  @override
  String get lockAfter1Min => 'After 1 minute';

  @override
  String get lockAfter5Min => 'After 5 minutes';

  @override
  String get lockAfter15Min => 'After 15 minutes';

  @override
  String get appLockTipsTitle => 'App lock tips';

  @override
  String get appLockTipsBody =>
      '- Uses device biometrics or passcode\n- Lock after only applies when the app is in background\n- Keep device security enabled for best protection';

  @override
  String get learnMore => 'Learn more';

  @override
  String get appLockHelpTitle => 'App lock help';

  @override
  String get appLockHelpBody =>
      'App lock requires device authentication. If you disable biometrics or passcode at the system level, app lock will stop working.\n\nLock after only triggers when the app is backgrounded. It does not lock while you are actively using the app.';

  @override
  String get ok => 'OK';

  @override
  String get journalLockedTitle => 'Journal locked';

  @override
  String get journalLockedBody => 'Authenticate to continue.';

  @override
  String get unlock => 'Unlock';

  @override
  String get unlockReason => 'Unlock your journal';

  @override
  String get enableAppLockReason => 'Enable app lock';

  @override
  String get disableAppLockReason => 'Disable app lock';
}
