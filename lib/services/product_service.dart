import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductService {
  static final Dio _dio = Dio();
  static const String baseUrl = 'https://e-linkapp-backend.onrender.com/api';

  static Future<Map<String, dynamic>?> createProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    File? image,
  }) async {
    try {
      print('=== STARTING PRODUCT CREATION ===');
      print('Sending product creation request to: $baseUrl/products');
      print(
          'Request data: {name: $name, description: $description, price: $price, category: $category}');

      // Get auth token from SharedPreferences
      String? authToken;
      final prefs = await SharedPreferences.getInstance();
      authToken = prefs.getString('auth_token');
      print('✓ Token retrieved from SharedPreferences');

      if (authToken != null) {
        print('✓ Auth token found: ${authToken.substring(0, 20)}...');
      } else {
        print('✗ Warning: No auth token found');
        throw Exception('Authentication required. Please login again.');
      }

      FormData formData = FormData.fromMap({
        'name': name,
        'description': description,
        'price': price,
        'category': category,
      });

      // Add image if provided
      if (image != null) {
        String fileName = image.path.split('/').last;
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(
            image.path,
            filename: fileName,
          ),
        ));
        print('✓ Image file added: $fileName');
      } else {
        print('ℹ No image provided');
      }

      print('📤 Sending request to API...');
      final response = await _dio.post(
        '$baseUrl/products',
        options: Options(
          headers: {
            'accept': '*/*',
            'Content-Type': 'multipart/form-data',
            'Authorization': 'Bearer $authToken',
          },
        ),
        data: formData,
      );

      print('📥 Response received with status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        print('');
        print('🎉 === PRODUCT CREATION SUCCESS === 🎉');
        print('Status Code: ${response.statusCode}');
        print('Success: ${data['success']}');
        print('Message: ${data['message']}');
        print('');

        if (data['product'] != null) {
          final product = data['product'];
          print('📦 PRODUCT DETAILS:');
          print('   • Product ID: ${product['_id']}');
          print('   • Name: ${product['name']}');
          print('   • Description: ${product['description']}');
          print('   • Price: \$${product['price']}');
          print('   • Category: ${product['category']}');
          print('   • Created At: ${product['createdAt']}');
          if (product['image'] != null) {
            print('   • Image URL: ${product['image']['url']}');
            print('   • Image Public ID: ${product['image']['public_id']}');
          }
        }
        print('');
        print('Full Response: ${json.encode(data)}');
        print('======================================');

        // Store product data in SharedPreferences
        await prefs.setString('last_product_created', json.encode(data));
        print('✓ Product data stored in SharedPreferences');

        return data;
      } else {
        print('');
        print('❌ === PRODUCT CREATION FAILED ===');
        print('Status Code: ${response.statusCode}');
        print('Error Response: ${response.data}');
        print('==================================');
        throw Exception(response.data['message'] ?? 'Product creation failed');
      }
    } on DioException catch (e) {
      print('');
      print('❌ === DIO EXCEPTION ===');
      print('Error: ${e.message}');
      if (e.response != null) {
        print('Status Code: ${e.response?.statusCode}');
        print('Response Data: ${e.response?.data}');
        throw Exception(
            e.response!.data['message'] ?? 'Product creation failed');
      } else {
        print('Network Error: No response received');
        throw Exception('Network error: Please check your internet connection');
      }
    } catch (e) {
      print('');
      print('❌ === UNEXPECTED ERROR ===');
      print('Error: $e');
      print('==========================');
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  static const String _productsKey = 'products';
  static const String _nextIdKey = 'nextProductId';
  static const String _favoritesKey = 'favorites';

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

  static Future<List<Map<String, dynamic>>> getFavoriteProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString(_favoritesKey);
    final products = await getProducts();

    if (favoritesJson == null) {
      return [];
    }

    final favoriteIds = (json.decode(favoritesJson) as List).cast<String>();
    return products
        .where((product) => favoriteIds.contains(product['id']))
        .toList();
  }

  static Future<void> removeFromFavorites(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString(_favoritesKey);

    if (favoritesJson == null) {
      return;
    }

    List<String> favorites =
        (json.decode(favoritesJson) as List).cast<String>();
    favorites.remove(productId);
    await prefs.setString(_favoritesKey, json.encode(favorites));
  }

  static Future<List<Map<String, dynamic>>> fetchProductsFromAPI() async {
    try {
      print('=== FETCHING PRODUCTS FROM API ===');
      print('Sending GET request to: $baseUrl/products');

      final response = await _dio.get(
        '$baseUrl/products',
        options: Options(
          headers: {
            'accept': '*/*',
          },
        ),
      );

      print('📥 Response received with status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        print('');
        print('✅ === PRODUCTS FETCH SUCCESS === ✅');
        print('Total products found: ${data.length}');
        print('');

        // Process and normalize the product data
        List<Map<String, dynamic>> products = [];

        for (int i = 0; i < data.length; i++) {
          final product = Map<String, dynamic>.from(data[i]);

          // Normalize image field
          if (product['image'] is Map) {
            product['imageUrl'] = product['image']['url'];
            product['imagePublicId'] = product['image']['public_id'];
          } else if (product['image'] is String) {
            product['imageUrl'] = product['image'];
          } else {
            product['imageUrl'] = 'https://via.placeholder.com/150';
          }

          // Add additional fields for compatibility
          product['id'] = product['_id'];
          product['sellerId'] = product['seller'] ?? 'unknown';

          products.add(product);

          print('Product ${i + 1}:');
          print('   • ID: ${product['_id']}');
          print('   • Name: ${product['name']}');
          print('   • Price: \$${product['price']}');
          print('   • Category: ${product['category']}');
          print(
              '   • Description: ${product['description'] ?? 'No description'}');
          print('   • Image: ${product['imageUrl']}');
          print('   • Status: ${product['status'] ?? 'N/A'}');
          print('   • Views: ${product['views'] ?? 0}');
          print('   • Created: ${product['createdAt']}');
          print('');
        }

        print('Full Response: ${json.encode(data)}');
        print('====================================');

        // Store products locally for offline access
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('api_products', json.encode(products));
        print('✓ Products cached locally');

        return products;
      } else {
        print('');
        print('❌ === PRODUCTS FETCH FAILED ===');
        print('Status Code: ${response.statusCode}');
        print('Error Response: ${response.data}');
        print('================================');
        throw Exception('Failed to fetch products: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('');
      print('❌ === DIO EXCEPTION ===');
      print('Error: ${e.message}');
      if (e.response != null) {
        print('Status Code: ${e.response?.statusCode}');
        print('Response Data: ${e.response?.data}');
        throw Exception('Network error: ${e.response?.statusCode}');
      } else {
        print('Network Error: No response received');
        throw Exception('Network error: Please check your internet connection');
      }
    } catch (e) {
      print('');
      print('❌ === UNEXPECTED ERROR ===');
      print('Error: $e');
      print('==========================');
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  // Get products with API integration
  static Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      // Try to fetch from API first
      return await fetchProductsFromAPI();
    } catch (e) {
      print('⚠ API fetch failed, falling back to local storage: $e');

      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final cachedProducts = prefs.getString('api_products');

      if (cachedProducts != null) {
        print('✓ Using cached products');
        return (json.decode(cachedProducts) as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      // Fallback to original local products
      return await getProducts();
    }
  }
}
