class MedcinDocument {
  final int id;
  final int childId;
  final String type;
  final String title;
  final String? mimeType;
  final int? size;
  final String? originalName;
  final String? signedUrl;
  final String? createdAt;

  MedcinDocument({
    required this.id,
    required this.childId,
    required this.type,
    required this.title,
    this.mimeType,
    this.size,
    this.originalName,
    this.signedUrl,
    this.createdAt,
  });

  factory MedcinDocument.fromJson(Map<String, dynamic> json) {
    return MedcinDocument(
      id: json['id'] ?? 0,
      childId: json['child_id'] ?? 0,
      type: json['type'] ?? 'autre',
      title: json['title'] ?? '',
      mimeType: json['mime_type'],
      size: (json['size'] as num?)?.toInt(),
      originalName: json['original_name'],
      signedUrl: json['signed_url'],
      createdAt: json['created_at'],
    );
  }

  bool get isPdf => (mimeType ?? '').contains('pdf') || (originalName ?? '').toLowerCase().endsWith('.pdf');
  bool get isImage => (mimeType ?? '').startsWith('image/');

  String get typeLabel {
    switch (type) {
      case 'ordonnance':
        return 'Ordonnance';
      case 'analyse':
        return 'Analyse';
      case 'guide':
        return 'Guide';
      default:
        return 'Document';
    }
  }
}