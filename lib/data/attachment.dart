import 'package:isar/isar.dart';

part 'attachment.g.dart';

@collection
class Attachment {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late String localPath;
  late String sha256;
  late int sizeBytes;
  String? mimeType;

  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;

  DateTime? deletedAt;

  bool isDirty = true;
  int? serverRevision;
}
