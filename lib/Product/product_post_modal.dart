// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/product_service.dart';
import '../services/notification_service.dart';

class ProductPostModal extends StatefulWidget {
  const ProductPostModal({super.key});

  @override
  State<ProductPostModal> createState() => _ProductPostModalState();
}

class _ProductPostModalState extends State<ProductPostModal> {
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = [
    'Electronics',
    'Furniture',
    'Clothing',
    'Books',
    'Home & Garden',
    'Sports',
    'Toys',
    'Other',
  ];

  @override
  void dispose() {
    _productNameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _getImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Post New AAProduct',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _productNameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _categoryController.text = newValue ?? '';
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _getImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _imageFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to add product image',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (_productNameController.text.isEmpty ||
                    _priceController.text.isEmpty ||
                    _categoryController.text.isEmpty ||
                    _descriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Validate price format
                final price = double.tryParse(_priceController.text);
                if (price == null || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid price'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  // Show loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Creating product...'),
                      duration: Duration(seconds: 1),
                    ),
                  );

                  final response = await ProductService.createProduct(
                    name: _productNameController.text.trim(),
                    description: _descriptionController.text.trim(),
                    price: price,
                    category: _categoryController.text,
                    image: _imageFile,
                  );

                  if (response != null && mounted) {
                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    // Send push notification for successful product creation
                    try {
                      await _sendProductCreatedNotification(
                        productName: _productNameController.text.trim(),
                        price: price,
                        category: _categoryController.text,
                      );
                    } catch (notificationError) {
                      print('Failed to send notification: $notificationError');
                      // Don't fail the whole process if notification fails
                    }

                    // Close modal with success result
                    navigator.pop(true);

                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(response['message'] ??
                                  'Product created successfully'),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;

                  String errorMessage = 'Error creating product. ';
                  String errorString = e.toString();

                  if (errorString.contains('Network error')) {
                    errorMessage += 'Please check your internet connection.';
                  } else if (errorString.contains('validation')) {
                    errorMessage += 'Please check your input data.';
                  } else if (errorString.contains('Authentication required')) {
                    errorMessage += 'Please login again.';
                  } else {
                    errorMessage += errorString.replaceAll('Exception: ', '');
                  }

                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(child: Text(errorMessage)),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Post Product',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendProductCreatedNotification({
    required String productName,
    required double price,
    required String category,
  }) async {
    try {
      print('📱 Sending product created notification...');

      // Create notification data
      final notificationData = {
        'title': '🎉 Product Created Successfully!',
        'body': '$productName (\$$price) in $category is now live',
        'type': 'product_created',
        'productName': productName,
        'price': price.toString(),
        'category': category,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Send local notification
      await NotificationService.showProductCreatedNotification(
        productName: productName,
        price: price,
        category: category,
      );

      // Send push notification to all users (if implemented)
      await _sendPushNotificationToUsers(notificationData);

      print('✅ Product created notification sent successfully');
    } catch (e) {
      print('❌ Error sending product created notification: $e');
      throw e;
    }
  }

  Future<void> _sendPushNotificationToUsers(
      Map<String, String> notificationData) async {
    try {
      // This would typically send to a backend service that handles push notifications
      // For now, we'll just simulate it and send local notifications

      print('📤 Sending push notification to users...');

      // You can integrate with services like:
      // - Firebase Cloud Messaging (FCM)
      // - OneSignal
      // - Pusher
      // - Custom backend service

      // Example of what the backend call might look like:
      // await PushNotificationService.sendToAllUsers(
      //   title: notificationData['title']!,
      //   body: notificationData['body']!,
      //   data: notificationData,
      // );

      // For demonstration, we'll just log it
      print('Push notification data: $notificationData');
    } catch (e) {
      print('❌ Error sending push notification: $e');
      // Don't throw here to avoid breaking the product creation flow
    }
  }
}
