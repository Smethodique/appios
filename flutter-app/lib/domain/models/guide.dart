class Guide {
  final int id;
  final String title;
  final String? description;
  final String? category;
  final String? ageRange;
  final String visibility;
  final int? size;
  final String? originalName;
  final String? thumbnailUrl;
  final String? url;
  final bool locked;

  Guide({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.ageRange,
    required this.visibility,
    this.size,
    this.originalName,
    this.thumbnailUrl,
    this.url,
    this.locked = false,
  });

  factory Guide.fromJson(Map<String, dynamic> json) {
    return Guide(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      category: json['category'],
      ageRange: json['age_range'],
      visibility: json['visibility'] ?? 'public',
      size: json['size'],
      originalName: json['original_name'],
      thumbnailUrl: json['thumbnail_url'],
      url: json['url'],
      locked: json['locked'] ?? false,
    );
  }

  bool get isFree => visibility == 'public';
  bool get isPremium => visibility == 'family' || visibility == 'family_plus';

  String get sizeDisplay =>
      size != null ? '${(size! / 1048576).toStringAsFixed(1)} MB' : '-';
}