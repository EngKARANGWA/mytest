// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';
import '../Dashboard/buyer_dashboard.dart';
import '../Dashboard/seller_dashboard.dart';

// Define BuyerInfo class
class BuyerInfo {
  final String fullName;
  final String phoneNumber;
  final String address;

  BuyerInfo({
    required this.fullName,
    required this.phoneNumber,
    required this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'address': address,
    };
  }
}

class UserRegistration extends StatefulWidget {
  final String userType; // 'buyer' or 'seller'

  const UserRegistration({super.key, required this.userType});

  @override
  State<UserRegistration> createState() => _UserRegistrationState();
}

class _UserRegistrationState extends State<UserRegistration> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _locationController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _locationController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Validate all required fields are not empty after trimming
        final name = _nameController.text.trim();
        final email = _emailController.text.trim();
        final phone = _phoneController.text.trim();
        final location = _locationController.text.trim();
        final password = _passwordController.text;

        if (name.isEmpty ||
            email.isEmpty ||
            phone.isEmpty ||
            location.isEmpty ||
            password.isEmpty) {
          throw Exception('Please fill in all required fields');
        }

        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registering your account...'),
            duration: Duration(seconds: 1),
          ),
        );

        Map<String, dynamic>? response;

        if (widget.userType == 'buyer') {
          final address = _addressController.text.trim();
          if (address.isEmpty) {
            throw Exception('Please fill in all required fields');
          }

          response = await UserService.registerBuyer(
            name: name,
            email: email,
            phone: phone,
            address: address,
            location: location,
            password: password,
          );
        } else {
          final businessName = _businessNameController.text.trim();
          final businessAddress = _businessAddressController.text.trim();

          if (businessName.isEmpty || businessAddress.isEmpty) {
            throw Exception('Please fill in all required fields');
          }

          response = await UserService.registerSeller(
            name: name,
            businessName: businessName,
            email: email,
            phone: phone,
            businessAddress: businessAddress,
            location: location,
            password: password,
          );
        }

        if (response != null && mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Registration successful!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to appropriate dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => widget.userType == 'buyer'
                  ? const BuyerDashboard()
                  : const SellerDashboard(),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = 'Registration failed. ';
          String errorString = e.toString();

          if (errorString.contains('email already exists') ||
              errorString.contains('already registered')) {
            errorMessage += 'This email is already registered.';
          } else if (errorString.contains('Network error')) {
            errorMessage += 'Please check your internet connection.';
          } else if (errorString.contains('validation failed')) {
            errorMessage += 'Please ensure all fields are properly filled.';
          } else {
            errorMessage += errorString.replaceAll('Exception: ', '');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          '${widget.userType.capitalize()} Registration',
          style: const TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create Your ${widget.userType.capitalize()} Account',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fill in the details below to register as a ${widget.userType}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name *',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  if (widget.userType == 'seller') ...[
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _businessNameController,
                      label: 'Business Name *',
                      icon: Icons.business,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your business name';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email *',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value.trim())) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number *',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    hintText: '+250789123456',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (!RegExp(r'^\+250\d{9}$').hasMatch(value.trim())) {
                        return 'Please enter a valid phone number (+250xxxxxxxxx)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _addressController,
                    label: widget.userType == 'seller'
                        ? 'Business Address *'
                        : 'Address *',
                    icon: Icons.location_on,
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return widget.userType == 'seller'
                            ? 'Please enter your business address'
                            : 'Please enter your address';
                      }
                      return null;
                    },
                  ),
                  if (widget.userType == 'seller') ...[
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _businessAddressController,
                      label: 'Business Address *',
                      icon: Icons.business,
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your business address';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _locationController,
                    label: 'Location *',
                    icon: Icons.place,
                    hintText: 'Kigali, Rwanda',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password *',
                    icon: Icons.lock,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password *',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Colors.deepPurple, Colors.purple],
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Register as ${widget.userType.capitalize()}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '* Required fields',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    int maxLines = 1,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

final FirebaseAuth _auth = FirebaseAuth.instance;

Future<void> registerUser({
  required String email,
  required String password,
  required String role,
  required BuyerInfo? buyerInfo,
}) async {
  try {
    print('Starting user registration process...');

    if (role == 'buyer' && buyerInfo == null) {
      throw Exception('Buyer information is required');
    }

    // Create user account
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Add user role and additional info to Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .set({
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      ...(role == 'buyer' ? buyerInfo!.toMap() : {}),
    });

    print('User registration completed successfully');
  } catch (e) {
    print('Error in registerUser: $e');
    rethrow;
  }
}
