import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/product_service.dart';
import '../../services/user_service.dart';

class SellerProductsTab extends StatefulWidget {
  const SellerProductsTab({super.key});

  @override
  State<SellerProductsTab> createState() => SellerProductsTabState();
}

class SellerProductsTabState extends State<SellerProductsTab> {
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _sellerProducts = [];
  bool _isLoading = true;
  String _error = '';
  String? _currentSellerId;

  @override
  void initState() {
    super.initState();
    _loadSellerInfo();
  }

  Future<void> _loadSellerInfo() async {
    try {
      // Get seller ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _currentSellerId =
          prefs.getString('user_id') ?? prefs.getString('current_user_id');

      if (_currentSellerId != null) {
        print('🔍 Current seller ID: $_currentSellerId');
        _loadProducts();
      } else {
        setState(() {
          _error = 'Unable to identify seller. Please login again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading seller information: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      print('🔍 Loading products for seller: $_currentSellerId');
      final products = await ProductService.getAllProducts();

      // Debug: Print all products and their seller IDs
      print('📦 Total products fetched: ${products.length}');
      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        print(
            'Product $i: ${product['name']} - Seller: ${product['seller']} - Current Seller: $_currentSellerId');
      }

      // For now, show ALL products since seller filtering might not work correctly
      // Remove this later when you want to filter by seller
      final sellerProducts = products; // Show all products for testing

      // Uncomment this when you want to filter by seller:
      // final sellerProducts = products.where((product) {
      //   final productSeller = product['seller']?.toString();
      //   return productSeller == _currentSellerId;
      // }).toList();

      print('👤 Displaying products: ${sellerProducts.length}');

      setState(() {
        _allProducts = products;
        _sellerProducts = sellerProducts;
        _isLoading = false;
      });

      // Debug: Print the products that will be displayed
      if (sellerProducts.isNotEmpty) {
        print('✅ Products to display:');
        for (var product in sellerProducts) {
          print('   - ${product['name']} (\$${product['price']})');
        }
      } else {
        print('❌ No products to display');
      }
    } catch (e) {
      print('❌ Error loading products: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Public method to refresh products from parent widget
  void refreshProducts() {
    if (mounted) {
      _loadProducts();
    }
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      // Show confirmation dialog
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Product'),
          content: const Text('Are you sure you want to delete this product?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Remove from local storage for now (until DELETE API is available)
        await ProductService.deleteProduct(productId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        _loadProducts(); // Refresh the list
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your products...'),
                ],
              ),
            )
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading products',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProducts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _sellerProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_outlined,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No products found',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total products in API: ${_allProducts.length}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Current Seller ID: $_currentSellerId',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadProducts,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProducts,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: Colors.deepPurple.withOpacity(0.1),
                            child: Row(
                              children: [
                                const Icon(Icons.inventory,
                                    color: Colors.deepPurple),
                                const SizedBox(width: 8),
                                Text(
                                  'Products (${_sellerProducts.length})',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Total: ${_allProducts.length}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: _loadProducts,
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.refresh, size: 16),
                                      SizedBox(width: 4),
                                      Text('Refresh'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _sellerProducts.length,
                              itemBuilder: (context, index) {
                                final product = _sellerProducts[index];
                                // Get the correct image URL
                                String imageUrl =
                                    'https://via.placeholder.com/150';
                                if (product['image'] is Map) {
                                  imageUrl =
                                      product['image']['url'] ?? imageUrl;
                                } else if (product['image'] is String) {
                                  imageUrl = product['image'];
                                }

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // Product Image
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            imageUrl,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.grey[300],
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              );
                                            },
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              print('Image load error: $error');
                                              return Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.grey[300],
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.grey[600],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Product Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product['name'] ??
                                                    'Unknown Product',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '\$${product['price']?.toString() ?? '0.00'}',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.deepPurple,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                product['category'] ??
                                                    'Uncategorized',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if (product['description'] !=
                                                  null) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  product['description'],
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  if (product['status'] != null)
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            product['status'] ==
                                                                    'Active'
                                                                ? Colors.green
                                                                : Colors.orange,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: Text(
                                                        product['status'],
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '${product['views'] ?? 0} views',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    'ID: ${product['seller'] ?? 'N/A'}',
                                                    style: TextStyle(
                                                      color: Colors.grey[500],
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Action Buttons
                                        Column(
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                // Edit functionality
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Edit functionality coming soon'),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.edit),
                                              color: Colors.blue,
                                            ),
                                            IconButton(
                                              onPressed: () => _deleteProduct(
                                                  product['_id'] ??
                                                      product['id']),
                                              icon: const Icon(Icons.delete),
                                              color: Colors.red,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
