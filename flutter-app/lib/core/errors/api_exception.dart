class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, List<String>> errors;

  ApiException({
    required this.message,
    required this.statusCode,
    this.errors = const {},
  });

  String? firstErrorFor(String field) {
    final list = errors[field];
    if (list == null || list.isEmpty) return null;
    return list.first;
  }

  @override
  String toString() => message;
}