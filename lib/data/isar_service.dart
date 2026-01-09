import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'attachment.dart';
import 'entry.dart';

class IsarService {
  IsarService._(this.isar);

  final Isar isar;

  static Future<IsarService> open() async {
    final directory = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [EntrySchema, AttachmentSchema],
      directory: directory.path,
    );
    return IsarService._(isar);
  }
}
