import 'checklist_item.dart';

class EntryPayload {
  EntryPayload({
    required this.title,
    required this.contentDeltaJson,
    required this.plainText,
    this.mood,
    List<String>? tags,
    this.entryType = 'diary',
    this.location,
    List<ChecklistItem>? checklist,
    this.latitude,
    this.longitude,
  }) : tags = tags ?? const <String>[],
       checklist = checklist ?? const <ChecklistItem>[];

  final String title;
  final String contentDeltaJson;
  final String plainText;
  final String? mood;
  final List<String> tags;
  final String entryType;
  final String? location;
  final List<ChecklistItem> checklist;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() => {
    'title': title,
    'contentDeltaJson': contentDeltaJson,
    'plainText': plainText,
    'entryType': entryType,
    'location': location,
    'checklist': checklist.map((e) => e.toJson()).toList(),
    'latitude': latitude,
    'longitude': longitude,
  };

  factory EntryPayload.fromJson(Map<String, dynamic> json) {
    return EntryPayload(
      title: json['title'] as String? ?? '',
      contentDeltaJson: json['contentDeltaJson'] as String? ?? '',
      plainText: json['plainText'] as String? ?? '',
      mood: json['mood'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.whereType<String>().toList() ??
          const <String>[],
      entryType: json['entryType'] as String? ?? 'diary',
      location: json['location'] as String?,
      checklist:
          (json['checklist'] as List<dynamic>?)
              ?.map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ChecklistItem>[],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
