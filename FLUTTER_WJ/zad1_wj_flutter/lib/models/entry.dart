class Entry {
  final int id;
  final String title;
  final String description;
  final DateTime createdAt;
  final String? photoBase64;

  Entry({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.photoBase64,
  });

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    throw FormatException("Cannot parse int from: $v");
  }

  static DateTime _asDateTime(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.parse(v);
    throw FormatException("Cannot parse DateTime from: $v");
  }

  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
      id: _asInt(json['id']),
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      createdAt: _asDateTime(json['createdAt']),
      photoBase64: json['photoBase64'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "description": description,
        "createdAt": createdAt.toUtc().toIso8601String(),
        "photoBase64": photoBase64,
      };
}
