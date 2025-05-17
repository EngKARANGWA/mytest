import 'package:flutter/material.dart';
import 'dart:convert';
import '../../services/product_service.dart';

class SellerProductsTab extends StatefulWidget {
  const SellerProductsTab({super.key});

  @override
  State<SellerProductsTab> createState() => _SellerProductsTabState();
}

class _SellerProductsTabState extends State<SellerProductsTab> {
  List<Map<String, dynamic>> _myProducts = [];

  // Statistics data
  final Map<String, dynamic> _stats = {
    'totalSales': 1250.00,
    'totalProducts': 15,
    'totalViews': 1200,
    'totalInCart': 8,
    'rating': 4.7,
  };

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await ProductService.getProducts();
    if (mounted) {
      setState(() {
        _myProducts =
            products.where((product) => product['status'] == 'Active').toList();
      });
    }
  }

  Widget _buildStatsCard() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Total Sales', '\$${_stats['totalSales']}'),
                _buildStatItem('Products', _stats['totalProducts'].toString()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Views', _stats['totalViews'].toString()),
                _buildStatItem('In Cart', _stats['totalInCart'].toString()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '${_stats['rating']} Rating',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: product['isLocalImage'] == true
                      ? Image.memory(
                          base64Decode(product['image'] ?? ''),
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          product['image']?.toString() ??
                              'https://via.placeholder.com/150',
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                ),
                // ...existing code...
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '\$${(product['price'] ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.visibility, size: 16),
                        const SizedBox(width: 4),
                        Text('${product['views'] ?? 0}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product['name']?.toString() ?? 'Unnamed Product',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          switch (value) {
                            case 'edit':
                              // Edit product logic would go here
                              break;
                            case 'delete':
                              await ProductService.deleteProduct(
                                product['id']?.toString() ?? '',
                              );
                              await _loadProducts();
                              break;
                            case 'deactivate':
                              product['status'] = 'Inactive';
                              await ProductService.updateProduct(product);
                              await _loadProducts();
                              break;
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit Product'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete Product'),
                          ),
                          const PopupMenuItem(
                            value: 'deactivate',
                            child: Text('Deactivate'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // ...existing product details code...
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Tooltip(
                          message:
                              product['address']?.toString() ?? 'No address',
                          child: Text(
                            product['address']?.toString() ?? 'No address',
                            style: const TextStyle(color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.shopping_cart, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${product['inCart'] ?? 0} in cart',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.category, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        product['category']?.toString() ?? 'Uncategorized',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        product['status']?.toString() ?? 'Unknown',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildStatsCard(),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _myProducts.length,
          itemBuilder: (context, index) {
            return _buildProductCard(_myProducts[index]);
          },
        ),
      ],
    );
  }
}
