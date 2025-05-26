// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test/Signup_page/user_registration.dart';
import 'auth_service.dart';

class UserService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Dio _dio = Dio();

  static const String _usersKey = 'users';
  static const String _currentUserKey = 'current_user_id';
  static const String baseUrl = 'https://e-linkapp-backend.onrender.com';

  static Future<void> registerUser({
    required String email,
    required String password,
    required String name,
    required String userType,
    Map<String, dynamic>? additionalInfo,
    required String role,
    BuyerInfo? buyerInfo,
  }) async {
    try {
      print('Starting user registration process...');

      if (userType == 'seller') {
        print('Registering seller...');
        // Use AuthService for seller registration
        final apiResponse = await AuthService.registerSeller(
          name: name,
          businessName: additionalInfo?['businessName'] ?? '',
          email: email,
          phone: additionalInfo?['phone'] ?? '',
          businessAddress: additionalInfo?['businessAddress'] ?? '',
          location: additionalInfo?['location'] ?? '',
          password: password,
        );

        print('API registration successful, storing in local storage...');

        // Store in local storage
        final prefs = await SharedPreferences.getInstance();
        final usersJson = prefs.getString(_usersKey);
        List<Map<String, dynamic>> users = [];

        if (usersJson != null) {
          users = (json.decode(usersJson) as List)
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }

        final newUser = {
          'id': apiResponse['id'] ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          'email': email,
          'name': name,
          'userType': userType,
          'createdAt': DateTime.now().toIso8601String(),
          ...?additionalInfo,
          'apiData': apiResponse, // Store API response data
        };

        users.add(newUser);
        await prefs.setString(_usersKey, json.encode(users));
        print('User data stored in local storage successfully');

        // Verify local storage
        final storedUsers = prefs.getString(_usersKey);
        if (storedUsers != null) {
          final decodedUsers = json.decode(storedUsers) as List;
          final storedUser = decodedUsers.firstWhere(
            (user) => user['email'] == email,
            orElse: () => null,
          );
          if (storedUser != null) {
            print('Verification successful: User found in local storage');
            print('Stored user data: $storedUser');
          } else {
            print('Warning: User not found in local storage after saving');
          }
        }
      } else {
        // Use AuthService for buyer registration
        print('Registering buyer with additional info: $additionalInfo');

        if (additionalInfo == null) {
          print('Error: additionalInfo is null');
          throw Exception('Registration data is missing');
        }

        // Extract and validate required fields
        final phone = additionalInfo['phone']?.toString().trim();
        final address = additionalInfo['address']?.toString().trim();
        final location = additionalInfo['location']?.toString().trim();

        print('Validating fields:');
        print('Phone: $phone');
        print('Address: $address');
        print('Location: $location');

        // Validate each field
        if (phone == null || phone.isEmpty) {
          print('Error: Phone number is missing or empty');
          throw Exception('Phone number is required');
        }
        if (address == null || address.isEmpty) {
          print('Error: Address is missing or empty');
          throw Exception('Address is required');
        }
        if (location == null || location.isEmpty) {
          print('Error: Location is missing or empty');
          throw Exception('Location is required');
        }

        try {
          print('Calling AuthService.registerBuyer with:');
          print('Name: $name');
          print('Email: $email');
          print('Phone: $phone');
          print('Address: $address');
          print('Location: $location');

          final userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          if (userCredential.user != null) {
            // Store user data in Firestore
            await _firestore
                .collection('users')
                .doc(userCredential.user!.uid)
                .set({
              'name': name,
              'email': email,
              'phone': phone,
              'address': address,
              'location': location,
              'userType': 'buyer',
              'createdAt': FieldValue.serverTimestamp(),
            });

            print('Buyer registration successful');
          }
        } catch (e) {
          print('Error in buyer registration: $e');
          throw Exception('Failed to register buyer: $e');
        }
      }
    } catch (e) {
      print('Error in registerUser: $e');
      throw Exception('Error registering user: $e');
    }
  }

  static Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      print('Attempting to login user...');
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        print('Firebase authentication successful');
        // Get user data from Firestore
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          print('User data found in Firestore');
          final userData = {
            'uid': userCredential.user!.uid,
            ...userDoc.data()!,
          };
          print('User data: $userData');
          return userData;
        } else {
          print('Warning: User document not found in Firestore');
        }
      }
      return null;
    } catch (e) {
      print('Error in loginUser: $e');
      throw Exception('Error logging in: $e');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString(_currentUserKey);
    final usersJson = prefs.getString(_usersKey);

    if (currentUserId == null || usersJson == null) return null;

    final users = (json.decode(usersJson) as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    return users.firstWhere(
      (user) => user['id'] == currentUserId,
      orElse: () => {},
    );
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserKey) != null;
  }

  static Future<void> updateUser(Map<String, dynamic> updates) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString(_currentUserKey);
    final usersJson = prefs.getString(_usersKey);

    if (currentUserId == null || usersJson == null) return;

    List<Map<String, dynamic>> users = (json.decode(usersJson) as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    final index = users.indexWhere((user) => user['id'] == currentUserId);
    if (index != -1) {
      users[index].addAll(updates);
      await prefs.setString(_usersKey, json.encode(users));
    }
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      return {
        'name': 'Guest User',
        'email': '',
        'photoUrl': 'https://via.placeholder.com/150',
      };
    }
    return currentUser;
  }

  static Future<Map<String, dynamic>?> registerSeller({
    required String name,
    required String businessName,
    required String email,
    required String phone,
    required String businessAddress,
    required String location,
    required String password,
  }) async {
    try {
      print(
          'Sending seller registration request to: $baseUrl/api/sellers/register');
      print(
          'Request data: {name: $name, businessName: $businessName, email: $email, phone: $phone, businessAddress: $businessAddress, location: $location}');

      final response = await _dio.post(
        '$baseUrl/api/sellers/register',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'name': name,
          'businessName': businessName,
          'email': email,
          'phone': phone,
          'businessAddress': businessAddress,
          'location': location,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        print('=== SELLER REGISTRATION SUCCESS ===');
        print('Status Code: ${response.statusCode}');
        print('Response Data: ${json.encode(data)}');
        print('Message: ${data['message']}');
        if (data['seller'] != null) {
          print('Seller ID: ${data['seller']['id']}');
          print('Seller Name: ${data['seller']['name']}');
          print('Seller Email: ${data['seller']['email']}');
          print('Business Name: ${data['seller']['businessName']}');
        }
        if (data['token'] != null) {
          print('Token received: ${data['token'].substring(0, 20)}...');
        }
        print('======================================');

        // Store comprehensive data in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token'] ?? '');
        await prefs.setString('user_type', 'seller');
        await prefs.setString('user_id', data['seller']['id'] ?? '');
        await prefs.setString('user_email', data['seller']['email'] ?? '');
        await prefs.setString('user_name', data['seller']['name'] ?? '');
        await prefs.setString(
            'business_name', data['seller']['businessName'] ?? '');
        await prefs.setString('seller_full_response', json.encode(data));
        print('Seller data stored in SharedPreferences successfully');

        return data;
      } else {
        print('Registration failed with status code: ${response.statusCode}');
        print('Error response: ${response.data}');
        throw Exception(response.data['message'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      print('DioException in registerSeller: ${e.message}');
      if (e.response != null) {
        print('Error status code: ${e.response?.statusCode}');
        print('Error response data: ${e.response?.data}');
        throw Exception(e.response!.data['message'] ?? 'Registration failed');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      print('Unexpected error in registerSeller: $e');
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>?> registerBuyer({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String location,
    required String password,
  }) async {
    try {
      print(
          'Sending buyer registration request to: $baseUrl/api/buyers/register');
      print(
          'Request data: {name: $name, email: $email, phone: $phone, address: $address, location: $location}');

      final response = await _dio.post(
        '$baseUrl/api/buyers/register',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'address': address,
          'location': location,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        print('=== BUYER REGISTRATION SUCCESS ===');
        print('Status Code: ${response.statusCode}');
        print('Response Data: ${json.encode(data)}');
        print('Message: ${data['message']}');
        if (data['buyer'] != null) {
          print('Buyer ID: ${data['buyer']['id']}');
          print('Buyer Name: ${data['buyer']['name']}');
          print('Buyer Email: ${data['buyer']['email']}');
        }
        if (data['token'] != null) {
          print('Token received: ${data['token'].substring(0, 20)}...');
        }
        print('===================================');

        // Store comprehensive data in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token'] ?? '');
        await prefs.setString('user_type', 'buyer');
        await prefs.setString('user_id', data['buyer']['id'] ?? '');
        await prefs.setString('user_email', data['buyer']['email'] ?? '');
        await prefs.setString('user_name', data['buyer']['name'] ?? '');
        await prefs.setString('buyer_full_response', json.encode(data));
        print('Buyer data stored in SharedPreferences successfully');

        return data;
      } else {
        print('Registration failed with status code: ${response.statusCode}');
        print('Error response: ${response.data}');
        throw Exception(response.data['message'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      print('DioException in registerBuyer: ${e.message}');
      if (e.response != null) {
        print('Error status code: ${e.response?.statusCode}');
        print('Error response data: ${e.response?.data}');
        throw Exception(e.response!.data['message'] ?? 'Registration failed');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      print('Unexpected error in registerBuyer: $e');
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  // Add helper methods to retrieve data from SharedPreferences
  static Future<String?> getSecureData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      print('Error reading from SharedPreferences for key $key: $e');
      return null;
    }
  }

  static Future<Map<String, String>> getAllSecureData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      Map<String, String> data = {};

      for (String key in keys) {
        final value = prefs.getString(key);
        if (value != null) {
          data[key] = value;
        }
      }
      return data;
    } catch (e) {
      print('Error reading all data from SharedPreferences: $e');
      return {};
    }
  }

  static Future<void> clearSecureStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('SharedPreferences cleared');
    } catch (e) {
      print('Error clearing SharedPreferences: $e');
    }
  }

  static Future<Map<String, dynamic>?> getStoredUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('user_type');
      if (userType == null) return null;

      final responseKey =
          userType == 'seller' ? 'seller_response' : 'buyer_response';
      final storedResponse = prefs.getString(responseKey);

      if (storedResponse != null) {
        return json.decode(storedResponse);
      }
      return null;
    } catch (e) {
      print('Error getting stored user data: $e');
      return null;
    }
  }

  // Helper methods to retrieve stored data
  static Future<String?> getStoredData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> clearStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('All stored data cleared');
  }
}
