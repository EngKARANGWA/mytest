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
        await NotificationService.addNotification(
          'Your product "${product['name']}" was added to a cart',
          sellerId: product['sellerId'],
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
}
