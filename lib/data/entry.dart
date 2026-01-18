import 'package:isar/isar.dart';

import 'checklist_item.dart';

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

  @ignore
  String entryType = 'diary';

  @ignore
  String? location;

  @ignore
  List<ChecklistItem> checklist = const [];

  @ignore
  double? latitude;

  @ignore
  double? longitude;
}
