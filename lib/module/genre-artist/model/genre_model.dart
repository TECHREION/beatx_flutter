/// One entry of `GET /genre`.
class GenreModel {
  const GenreModel({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
    this.version = 0,
  });

  final String id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int version;

  factory GenreModel.fromJson(Map<String, dynamic> json) {
    return GenreModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      version: json['__v'] is num ? (json['__v'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    '__v': version,
  };

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
