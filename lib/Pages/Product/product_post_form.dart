import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import '../../services/product_service.dart';

class ProductPostForm extends StatefulWidget {
  const ProductPostForm({super.key});

  @override
  State<ProductPostForm> createState() => _ProductPostFormState();
}

class _ProductPostFormState extends State<ProductPostForm> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void dispose() {
    _productNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _getImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      String imageUrl =
          'https://via.placeholder.com/150'; // Default placeholder

      if (_imageFile != null) {
        setState(() {
          _isUploading = true;
        });
        try {
          String fileName =
              'products/${DateTime.now().millisecondsSinceEpoch}_${_imageFile!.path.split('/').last}';
          firebase_storage.Reference ref = firebase_storage
              .FirebaseStorage
              .instance
              .ref()
              .child(fileName);

          await ref.putFile(_imageFile!); // Upload the file
          imageUrl = await ref.getDownloadURL(); // Get the download URL
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image upload failed: ${e.toString()}')),
          );
        } finally {
          if (mounted) {
            setState(() {
              _isUploading = false;
            });
          }
        }
        if (imageUrl == 'https://via.placeholder.com/150' &&
            _imageFile != null) {
          return;
        }
      }

      final product = {
        'name': _productNameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'category': _categoryController.text,
        'image': imageUrl,
        'status': 'Active',
        'views': 0,
        'inCart': 0,
      };

      await ProductService.saveProduct(product);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product posted successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isLandscape = screenSize.width > screenSize.height;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200;
    final isDesktop = screenSize.width >= 1200;
    final padding = isSmallScreen ? 16.0 : 24.0;
    final maxWidth = isDesktop ? 600.0 : (isTablet ? 500.0 : double.infinity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post New Product'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                padding: EdgeInsets.all(padding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Post Your Product",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isDesktop ? 32 : (isTablet ? 28 : 24),
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      SizedBox(height: isLandscape ? 16 : 24),

                      GestureDetector(
                        onTap: _isUploading ? null : _getImage,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child:
                              _imageFile == null
                                  ? const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate,
                                        size: 50,
                                        color: Colors.white,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Tap to add product image',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  )
                                  : ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      _imageFile!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                        ),
                      ),
                      SizedBox(height: isLandscape ? 16 : 24),

                      TextFormField(
                        controller: _productNameController,
                        decoration: const InputDecoration(
                          labelText: "Product Name",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.shopping_bag),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter product name";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: isLandscape ? 12 : 16),

                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: "Description",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter product description";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: isLandscape ? 12 : 16),

                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: "Price",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter product price";
                          }
                          if (double.tryParse(value) == null) {
                            return "Please enter a valid price";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: isLandscape ? 12 : 16),

                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: "Category",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter product category";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: isLandscape ? 16 : 24),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: EdgeInsets.symmetric(
                            vertical: isLandscape ? 12 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isUploading ? null : _submitForm,
                        child: Text(
                          "Post Product",
                          style: TextStyle(
                            fontSize: isLandscape ? 16 : 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isUploading)
            Container(
              color: Color.fromRGBO(0, 0, 0, 0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
