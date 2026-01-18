class ChecklistItem {
  ChecklistItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
    this.position = 0,
  });

  final String id;
  final String text;
  final bool isCompleted;
  final int position;

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isCompleted': isCompleted,
    'position': position,
  };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
    id: json['id'] as String,
    text: json['text'] as String,
    isCompleted: json['isCompleted'] as bool? ?? false,
    position: json['position'] as int? ?? 0,
  );

  ChecklistItem copyWith({
    String? id,
    String? text,
    bool? isCompleted,
    int? position,
  }) => ChecklistItem(
    id: id ?? this.id,
    text: text ?? this.text,
    isCompleted: isCompleted ?? this.isCompleted,
    position: position ?? this.position,
  );
}
