import 'package:isar/isar.dart';

part 'entry.g.dart';

@collection
class Entry {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  @Index()
  late String journalId;

  late String payloadEncrypted;
  int payloadVersion = 1;

  List<String> attachmentIds = [];

  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;

  DateTime? deletedAt;

  bool isDirty = true;
  int? serverRevision;

  @ignore
  String title = '';

  @ignore
  String contentDeltaJson = '';

  @ignore
  String plainText = '';

  @ignore
  String? mood;

  @ignore
  List<String> tags = [];
}
