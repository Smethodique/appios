import 'package:medcin_app/core/network/api_service.dart';

class PaymentService {
  static String? lastError;

  static String? referenceFromUrl(String url) =>
      Uri.tryParse(url)?.queryParameters['ref'];

  static Future<String?> waitUntilFinished(String reference) async {
    for (var attempt = 0; attempt < 180; attempt++) {
      final status = await check(reference);
      if (status == 'paid' || status == 'failed') return status;
      await Future.delayed(const Duration(seconds: 4));
    }
    return null;
  }

  static Future<String?> check(String reference) async {
    try {
      final data = await ApiService.get(
        'payment-status',
        queryParams: {'reference': reference},
      );
      if (data is! Map) return null;
      final status = data['status']?.toString();
      if (status == 'paid' || status == 'failed') return status;
      return 'pending';
    } catch (e) {
      lastError = e.toString();
      return null;
    }
  }
}
