import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_day_one/l10n/app_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:uuid/uuid.dart';

import 'data/auth_session.dart';
import 'data/entry.dart';
import 'data/entry_repository.dart';
import 'data/journal_api_client.dart';
import 'data/journal_repository.dart';
import 'data/isar_service.dart';
import 'security/app_lock_service.dart';
import 'ui/app_lock_gate.dart';
import 'ui/entry_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiClient = JournalApiClient.fromConfig();
  final authSession = AuthSession(client: apiClient);
  final isarService = await IsarService.open();
  final journalRepository = await JournalRepository.open(isarService.isar);
  final repository = await EntryRepository.open(
    journalApiClient: apiClient,
    authSession: authSession,
    journalRepository: journalRepository,
  );
  final appLockService = await AppLockService.create();
  await _createWelcomeEntryIfNeeded(repository);
  runApp(
    MyApp(
      repository: repository,
      journalRepository: journalRepository,
      appLockService: appLockService,
    ),
  );
}

Future<void> _createWelcomeEntryIfNeeded(EntryRepository repository) async {
  const storage = FlutterSecureStorage();
  const key = 'has_created_welcome_entry_v1';

  final hasCreated = await storage.read(key: key);
  if (hasCreated == 'true') {
    return;
  }

  final now = DateTime.now();
  final entry = Entry()
    ..uuid = const Uuid().v4()
    ..journalId = ''
    ..title = 'Daily Check-in'
    ..plainText = '👋 这是您的 Day One\n\n很高兴您选择使用 Day One。写日记可能是您一生之中最重要的决定之一。'
    ..contentDeltaJson = ''
    ..payloadEncrypted = ''
    ..entryType = 'diary'
    ..createdAt = now
    ..updatedAt = now;

  await repository.saveEntry(entry);
  await storage.write(key: key, value: 'true');
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.repository,
    required this.journalRepository,
    required this.appLockService,
  });

  final EntryRepository repository;
  final JournalRepository journalRepository;
  final AppLockService appLockService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale != null) {
          for (final supported in supportedLocales) {
            if (supported.languageCode == locale.languageCode) {
              return supported;
            }
          }
        }
        return const Locale('zh');
      },
      home: AppLockGate(
        appLockService: appLockService,
        child: EntryListScreen(
          repository: repository,
          journalRepository: journalRepository,
          appLockService: appLockService,
        ),
      ),
    );
  }
}
