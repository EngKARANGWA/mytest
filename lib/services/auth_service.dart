// ignore_for_file: avoid_print

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'https://e-linkapp-backend.onrender.com/api';
  static const String _sellerDataKey = 'seller_data';

  static Future<Map<String, dynamic>> registerBuyer({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String location,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/buyers/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'address': address,
          'location': location,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to register buyer: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error registering buyer: $e');
    }
  }

  static Future<Map<String, dynamic>> registerSeller({
    required String name,
    required String businessName,
    required String email,
    required String phone,
    required String businessAddress,
    required String location,
    required String password,
  }) async {
    try {
      print('Attempting to register seller with API...');
      print('API Endpoint: $baseUrl/sellers/register');
      print('Request Data: {');
      print('  name: $name');
      print('  businessName: $businessName');
      print('  email: $email');
      print('  phone: $phone');
      print('  businessAddress: $businessAddress');
      print('  location: $location');
      print('}');

      final response = await http.post(
        Uri.parse('$baseUrl/sellers/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'businessName': businessName,
          'email': email,
          'phone': phone,
          'businessAddress': businessAddress,
          'location': location,
          'password': password,
        }),
      );

      print('API Response Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('Registration successful! Response data: $responseData');

        // Store in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_sellerDataKey, jsonEncode(responseData));
        print('Seller data stored in local storage');

        return responseData;
      } else {
        print('Registration failed with status code: ${response.statusCode}');
        print('Error response: ${response.body}');
        throw Exception('Failed to register seller: ${response.body}');
      }
    } catch (e) {
      print('Error in registerSeller: $e');
      throw Exception('Error registering seller: $e');
    }
  }

  // Get stored seller data
  static Future<Map<String, dynamic>?> getStoredSellerData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sellerData = prefs.getString(_sellerDataKey);
      if (sellerData != null) {
        return jsonDecode(sellerData);
      }
      return null;
    } catch (e) {
      print('Error getting stored seller data: $e');
      return null;
    }
  }
}
