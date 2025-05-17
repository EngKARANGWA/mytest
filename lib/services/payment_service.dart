import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentService {
  static const String _paymentsKey = 'payments';

  static Future<String> processPayment({
    required double amount,
    required String paymentMethod,
    required String paymentTiming,
    required File paymentReference,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final paymentsJson = prefs.getString(_paymentsKey);
    List<Map<String, dynamic>> payments = [];

    if (paymentsJson != null) {
      payments = (json.decode(paymentsJson) as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    // Convert image to base64 for storage
    final bytes = await paymentReference.readAsBytes();
    final base64Image = base64Encode(bytes);

    final orderId = DateTime.now().millisecondsSinceEpoch.toString();
    final payment = {
      'id': orderId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentTiming': paymentTiming,
      'paymentReference': base64Image,
      'status': 'Pending',
      'createdAt': DateTime.now().toIso8601String(),
    };

    payments.add(payment);
    await prefs.setString(_paymentsKey, json.encode(payments));
    return orderId;
  }

  static Future<List<Map<String, dynamic>>> getPayments() async {
    final prefs = await SharedPreferences.getInstance();
    final paymentsJson = prefs.getString(_paymentsKey);

    if (paymentsJson == null) return [];

    return (json.decode(paymentsJson) as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<void> updatePaymentStatus(String orderId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final paymentsJson = prefs.getString(_paymentsKey);

    if (paymentsJson == null) return;

    List<Map<String, dynamic>> payments = (json.decode(paymentsJson) as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    final index = payments.indexWhere((payment) => payment['id'] == orderId);
    if (index != -1) {
      payments[index]['status'] = status;
      await prefs.setString(_paymentsKey, json.encode(payments));
    }
  }
}
