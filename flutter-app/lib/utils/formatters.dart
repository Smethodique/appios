import 'package:intl/intl.dart';

class Formatters {
  static String date(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final parsed = DateTime.tryParse(iso);
      if (parsed == null) return iso;
      return DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {
      return iso;
    }
  }

  static String dateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final parsed = DateTime.tryParse(iso);
      if (parsed == null) return iso;
      return DateFormat('dd/MM/yyyy · HH:mm').format(parsed);
    } catch (_) {
      return iso;
    }
  }

  static String fileSize(num? bytes) {
    if (bytes == null || bytes <= 0) return '-';
    if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '$bytes B';
  }

  static String price(num? value) {
    if (value == null) return '-';
    return '${value.toStringAsFixed(2)} €';
  }
}