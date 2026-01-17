import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'attachment.dart';
import 'entry.dart';
import 'journal.dart';

class IsarService {
  IsarService._internal(this.isar);

  final Isar isar;

  static IsarService? _instance;

  static Future<IsarService> open() async {
    if (_instance != null && _instance!.isar.isOpen) {
      return _instance!;
    }

    final directory = await getApplicationDocumentsDirectory();
    final isar = await Isar.open([
      EntrySchema,
      AttachmentSchema,
      JournalSchema,
    ], directory: directory.path);
    _instance = IsarService._internal(isar);
    return _instance!;
  }

  static void reset() {
    _instance = null;
  }
}
