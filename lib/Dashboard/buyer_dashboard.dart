// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../services/notification_service.dart';
import '../services/product_service.dart';
import '../services/payment_service.dart';
import '../services/user_service.dart';
import '../services/maps_service.dart';
import '../Modals/payment_modal.dart';
import '../Modals/order_status_modal.dart';
import '../Modals/edit_profile_modal.dart';
import 'dart:convert';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({super.key});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Electronics',
    'Furniture',
    'Clothing',
    'Books',
  ];

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await ProductService.getProducts();
    setState(() {
      _products =
          products.where((product) => product['status'] == 'Active').toList();
      _filteredProducts = _products;
    });
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) {
        final matchesCategory = _selectedCategory == 'All' ||
            product['category'] == _selectedCategory;
        final matchesSearch = product['name'].toLowerCase().contains(query) ||
            product['description']?.toLowerCase().contains(query) == true;
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showCart() async {
    final cartItems = await CartService.getCart();
    if (!mounted) return;

    // Calculate total amount
    double totalAmount = 0;
    for (var item in cartItems) {
      totalAmount += (item['price'] ?? 0.0) * (item['quantity'] ?? 1);
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Shopping Cart',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (cartItems.isEmpty)
                const Text('Your cart is empty')
              else
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return ListTile(
                        leading: item['isLocalImage'] == true
                            ? Image.memory(
                                base64Decode(item['image'] ?? ''),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                item['image']?.toString() ??
                                    'https://via.placeholder.com/150',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                        title:
                            Text(item['name']?.toString() ?? 'Unnamed Product'),
                        subtitle: Text(
                            '\$${(item['price'] ?? 0.0).toStringAsFixed(2)} x ${item['quantity'] ?? 1}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await CartService.removeFromCart(
                                item['id']?.toString() ?? '');
                            setState(() {});
                          },
                        ),
                      );
                    },
                  ),
                ),
              if (cartItems.isNotEmpty) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => PaymentModal(
                        totalAmount: totalAmount,
                        onPaymentComplete: (orderId) {
                          showDialog(
                            context: context,
                            builder: (context) => OrderStatusModal(
                              orderId: orderId,
                            ),
                          );
                        },
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Proceed to Payment'),
                ),
              ],
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    await CartService.addToCart(product);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to cart!')),
    );
  }

  Future<void> _showNotifications() async {
    final notifications = await NotificationService.getNotifications();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (notifications.isEmpty)
                const Text('No notifications')
              else
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return ListTile(
                        title: Text(notification['message']),
                        subtitle: Text(DateTime.parse(notification['timestamp'])
                            .toString()),
                        trailing: notification['read']
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.check),
                                onPressed: () async {
                                  await NotificationService.markAsRead(
                                      notification['id']);
                                  setState(() {});
                                },
                              ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFilterDialog() async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filter Products',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
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
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                      _filterProducts();
                    });
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showProductDetails(Map<String, dynamic> product) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  product['isLocalImage'] == true
                      ? Image.memory(
                          base64Decode(product['image'] ?? ''),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          product['image']?.toString() ??
                              'https://via.placeholder.com/150',
                          height: 200,
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
                ],
              ),
              const SizedBox(height: 16),
              Text(
                product['name']?.toString() ?? 'Unnamed Product',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${(product['price'] ?? 0.0).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  if (product['latitude'] != null &&
                      product['longitude'] != null) {
                    MapsService.openLocationInMaps(
                      product['latitude'],
                      product['longitude'],
                      product['name']?.toString() ?? 'Product Location',
                    );
                  } else {
                    MapsService.openAddressInMaps(
                      product['address']?.toString() ?? '',
                    );
                  }
                },
                child: Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 16, color: Colors.deepPurple),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        product['address']?.toString() ?? 'No address',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    const Icon(Icons.map, size: 16, color: Colors.deepPurple),
                  ],
                ),
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _addToCart(product),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Add to Cart',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) {
                    _filterProducts();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ChoiceChip(
                  label: Text(_categories[index]),
                  selected: _selectedCategory == _categories[index],
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = _categories[index];
                      _filterProducts();
                    });
                  },
                ),
              );
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) {
              final product = _filteredProducts[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        product['isLocalImage'] == true
                            ? Image.memory(
                                base64Decode(product['image'] ?? ''),
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                product['image']?.toString() ??
                                    'https://via.placeholder.com/150',
                                height: 200,
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
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name']?.toString() ?? 'Unnamed Product',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                product['address']?.toString() ?? 'No address',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: () => _showProductDetails(product),
                                icon: const Icon(Icons.visibility),
                                label: const Text('View Details'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _addToCart(product),
                                icon: const Icon(Icons.shopping_cart,
                                    color: Colors.white),
                                label: const Text('Add to Cart',
                                    style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesTab() {
    return const Center(
      child: Text('Favorites Tab'),
    );
  }

  Widget _buildProfileTab() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: UserService.getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No user data found'));
        }

        final user = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.deepPurple,
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                          Icons.person, 'Name', user['name'] ?? 'Not set'),
                      const Divider(),
                      _buildInfoRow(
                          Icons.email, 'Email', user['email'] ?? 'Not set'),
                      const Divider(),
                      _buildInfoRow(
                          Icons.phone, 'Phone', user['phone'] ?? 'Not set'),
                      const Divider(),
                      _buildInfoRow(Icons.location_on, 'Address',
                          user['address'] ?? 'Not set'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.account_circle, 'User Type', 'Buyer'),
                      const Divider(),
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Member Since',
                        DateTime.parse(user['createdAt'] ??
                                DateTime.now().toIso8601String())
                            .toString()
                            .split(' ')[0],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => EditProfileModal(user: user),
                  );
                  if (result == true) {
                    setState(() {}); // Refresh profile data
                  }
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: PaymentService.getPayments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No payment history'));
        }

        final payments = snapshot.data!;
        return ListView.builder(
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order ID: ${payment['id']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: payment['status'] == 'Approved'
                                ? Colors.green.withOpacity(0.2)
                                : payment['status'] == 'Rejected'
                                    ? Colors.red.withOpacity(0.2)
                                    : Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            payment['status'],
                            style: TextStyle(
                              color: payment['status'] == 'Approved'
                                  ? Colors.green
                                  : payment['status'] == 'Rejected'
                                      ? Colors.red
                                      : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Amount: \$${(payment['amount'] as double).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Payment Method: ${payment['paymentMethod']}'),
                    const SizedBox(height: 8),
                    Text('Payment Timing: ${payment['paymentTiming']}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => OrderStatusModal(
                            orderId: payment['id'],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('View Details'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Buyer Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: _showCart,
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: _showNotifications,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          _buildFavoritesTab(),
          _buildProfileTab(),
          _buildPaymentsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.blue,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Payments',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
