import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_day_one/l10n/app_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'data/auth_session.dart';
import 'data/entry_repository.dart';
import 'data/journal_api_client.dart';
import 'security/app_lock_service.dart';
import 'ui/app_lock_gate.dart';
import 'ui/entry_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiClient = JournalApiClient.fromConfig();
  final authSession = AuthSession(client: apiClient);
  final repository = await EntryRepository.open(
    journalApiClient: apiClient,
    authSession: authSession,
  );
  final appLockService = await AppLockService.create();
  runApp(MyApp(repository: repository, appLockService: appLockService));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.repository,
    required this.appLockService,
  });

  final EntryRepository repository;
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
          appLockService: appLockService,
        ),
      ),
    );
  }
}
