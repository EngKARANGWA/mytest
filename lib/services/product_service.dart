import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ProductService {
  static const String _productsKey = 'products';
  static const String _nextIdKey = 'nextProductId';

  // Save a new product
  static Future<void> saveProduct(Map<String, dynamic> product) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing products
    final productsJson = prefs.getString(_productsKey);
    List<Map<String, dynamic>> products = [];

    if (productsJson != null) {
      products = (json.decode(productsJson) as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    // Get next ID
    int nextId = prefs.getInt(_nextIdKey) ?? 1;
    product['id'] = nextId.toString();

    // Add seller information
    product['sellerId'] =
        prefs.getString('current_user_id') ?? 'default_seller';

    // Handle image
    if (product['image'] is File) {
      try {
        // Convert File to base64
        final bytes = await (product['image'] as File).readAsBytes();
        product['image'] = base64Encode(bytes);
        product['isLocalImage'] = true;
      } catch (e) {
        // ignore: avoid_print
        print('Error converting image to base64: $e');
        product['image'] = 'https://via.placeholder.com/150';
        product['isLocalImage'] = false;
      }
    } else if (product['image'] is String) {
      if (product['image'].toString().startsWith('http')) {
        product['isLocalImage'] = false;
      } else {
        product['isLocalImage'] = true;
      }
    } else {
      product['image'] = 'https://via.placeholder.com/150';
      product['isLocalImage'] = false;
    }

    // Add new product
    products.add(product);

    // Save updated products list
    await prefs.setString(_productsKey, json.encode(products));
    await prefs.setInt(_nextIdKey, nextId + 1);
  }

  // Get all products
  static Future<List<Map<String, dynamic>>> getProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson = prefs.getString(_productsKey);

    if (productsJson == null) {
      return [];
    }

    return (json.decode(productsJson) as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // Update a product
  static Future<void> updateProduct(Map<String, dynamic> updatedProduct) async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson = prefs.getString(_productsKey);

    if (productsJson == null) {
      return;
    }

    List<Map<String, dynamic>> products = (json.decode(productsJson) as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    // Find and update the product
    final index = products.indexWhere((p) => p['id'] == updatedProduct['id']);
    if (index != -1) {
      products[index] = updatedProduct;
      await prefs.setString(_productsKey, json.encode(products));
    }
  }

  // Delete a product
  static Future<void> deleteProduct(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson = prefs.getString(_productsKey);

    if (productsJson == null) {
      return;
    }

    List<Map<String, dynamic>> products = (json.decode(productsJson) as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    // Remove the product
    products.removeWhere((p) => p['id'] == productId);
    await prefs.setString(_productsKey, json.encode(products));
  }
}
