class EntryPayload {
  EntryPayload({
    required this.title,
    required this.contentDeltaJson,
    required this.plainText,
    this.mood,
    List<String>? tags,
  }) : tags = tags ?? const <String>[];

  final String title;
  final String contentDeltaJson;
  final String plainText;
  final String? mood;
  final List<String> tags;

  Map<String, dynamic> toJson() => {
        'title': title,
        'contentDeltaJson': contentDeltaJson,
        'plainText': plainText,
      };

  factory EntryPayload.fromJson(Map<String, dynamic> json) {
    return EntryPayload(
      title: json['title'] as String? ?? '',
      contentDeltaJson: json['contentDeltaJson'] as String? ?? '',
      plainText: json['plainText'] as String? ?? '',
      mood: json['mood'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const <String>[],
    );
  }
}
