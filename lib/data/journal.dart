import 'package:isar/isar.dart';

part 'journal.g.dart';

@collection
class Journal {
  Journal();

  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late String name;
  String? color;

  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;

  DateTime? deletedAt;

  bool isDirty = true;
  int? serverRevision;

  factory Journal.fromJson(Map<String, dynamic> json) {
    return Journal()
      ..uuid = json['uuid'] as String? ?? ''
      ..name = json['name'] as String? ?? ''
      ..color = json['color'] as String?
      ..createdAt = DateTime.parse(json['createdAt'] as String)
      ..updatedAt = DateTime.parse(json['updatedAt'] as String)
      ..deletedAt = json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String)
      ..isDirty = false
      ..serverRevision = json['revision'] as int?;
  }
}
