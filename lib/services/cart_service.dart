import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class CartService {
  static const String _cartKey = 'cart';

  static Future<void> addToCart(Map<String, dynamic> product) async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(_cartKey);
    List<Map<String, dynamic>> cart = [];

    if (cartJson != null) {
      cart = (json.decode(cartJson) as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    // Check if product already exists in cart
    final existingIndex =
        cart.indexWhere((item) => item['id'] == product['id']);
    if (existingIndex != -1) {
      cart[existingIndex]['quantity'] =
          (cart[existingIndex]['quantity'] ?? 1) + 1;
    } else {
      cart.add({...product, 'quantity': 1});

      // Send notification to seller
      if (product['sellerId'] != null) {
        // Get user ID from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id') ??
            prefs.getString('current_user_id') ??
            'default_user';

        // Replace addNotification with saveNotification
        await NotificationService.saveNotification(
          sellerId: userId,
          notification: {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'title': 'Item Added to Cart',
            'body': 'Product has been added to your cart',
            'type': 'cart_update',
            'timestamp': DateTime.now().toIso8601String(),
            'read': false,
          },
        );
      }
    }

    await prefs.setString(_cartKey, json.encode(cart));
  }

  static Future<List<Map<String, dynamic>>> getCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(_cartKey);

    if (cartJson == null) return [];

    return (json.decode(cartJson) as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<void> removeFromCart(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(_cartKey);

    if (cartJson == null) return;

    List<Map<String, dynamic>> cart = (json.decode(cartJson) as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    cart.removeWhere((item) => item['id'] == productId);
    await prefs.setString(_cartKey, json.encode(cart));
  }

  static Future<int> getCartItemCount() async {
    final cart = await getCart();
    return cart.fold<int>(
        0, (sum, item) => sum + (item['quantity'] as int? ?? 1));
  }
}
