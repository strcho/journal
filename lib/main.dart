import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'data/entry_repository.dart';
import 'security/app_lock_service.dart';
import 'ui/app_lock_gate.dart';
import 'ui/entry_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await EntryRepository.open();
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
      title: 'My Day One',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
      ],
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
