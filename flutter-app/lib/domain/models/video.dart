class Video {
  final int id;
  final String title;
  final String? description;
  final String? category;
  final String? ageRange;
  final String visibility;
  final int? size;
  final String? thumbnail;
  final String? thumbnailUrl;
  final String? videoUrl;
  final bool locked;

  Video({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.ageRange,
    required this.visibility,
    this.size,
    this.thumbnail,
    this.thumbnailUrl,
    this.videoUrl,
    this.locked = false,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      category: json['category'],
      ageRange: json['age_range'],
      visibility: json['visibility'] ?? 'public',
      size: json['size'],
      thumbnail: json['thumbnail'],
      thumbnailUrl: json['thumbnail_url'],
      videoUrl: json['video_url'],
      locked: json['locked'] ?? false,
    );
  }

  String get sizeDisplay =>
      size != null ? '${(size! / 1048576).toStringAsFixed(1)} MB' : '-';

  bool get isFree => visibility == 'public';
  bool get isPremium => visibility == 'family' || visibility == 'family_plus';
}
