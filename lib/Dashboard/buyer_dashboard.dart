// ignore_for_file: deprecated_member_use, unused_element

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
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({super.key});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  int _currentIndex = 0;
  List<dynamic> _notifications = [];
  int _cartItemCount = 0;
  Map<String, dynamic>? _currentLocation;
  List<Map<String, dynamic>> _nearbySellers = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadCartCount();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    final location = await MapsService.getCurrentLocation();
    setState(() {
      _currentLocation = location;
    });
    _loadNearbySellers();
  }

  Future<void> _loadNearbySellers() async {
    if (_currentLocation != null) {
      final sellers = await MapsService.getNearbySellers(
        _currentLocation!['latitude'],
        _currentLocation!['longitude'],
      );
      setState(() {
        _nearbySellers = sellers;
      });
    }
  }

  Future<void> _loadNotifications() async {
    final notifications = await NotificationService.getNotifications();
    // Store notifications in local storage for offline access
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_notifications', json.encode(notifications));
    setState(() {
      _notifications = notifications;
    });
  }

  Future<void> _loadCartCount() async {
    final count = await CartService.getCartItemCount();
    // Cache cart count
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_cart_count', json.encode(count));
    setState(() {
      _cartItemCount = count;
    });
  }

  Widget _buildHomeTab() {
    return Column(
      children: [
        if (_currentLocation != null)
          Container(
            height: 200,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FutureBuilder(
                future: MapsService.getStaticMap(
                  _currentLocation!['latitude'],
                  _currentLocation!['longitude'],
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading map'));
                  }
                  return Image.network(
                    snapshot.data ?? '',
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
          ),
        if (_nearbySellers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nearby Sellers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _nearbySellers.length,
                    itemBuilder: (context, index) {
                      final seller = _nearbySellers[index];
                      return Card(
                        margin: const EdgeInsets.only(right: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                seller['businessName'] ?? 'Unknown',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${seller['distance']?.toStringAsFixed(1) ?? '0'} km away',
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
        Expanded(
          child: FutureBuilder(
            future: ProductService.getProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final products = snapshot.data ?? [];
              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Image.network(
                            product['imageUrl'] ?? '',
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text('\$${product['price']?.toString() ?? '0'}'),
                              ElevatedButton(
                                onPressed: () => CartService.addToCart(product),
                                child: const Text('Add to Cart'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesTab() {
    return FutureBuilder(
      future: ProductService.getFavoriteProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final favorites = snapshot.data ?? [];
        return ListView.builder(
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final product = favorites[index];
            return ListTile(
              leading: Image.network(product['imageUrl'] ?? '', width: 50),
              title: Text(product['name'] ?? ''),
              subtitle: Text('\$${product['price']?.toString() ?? '0'}'),
              trailing: IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red),
                onPressed: () =>
                    ProductService.removeFromFavorites(product['id']),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return FutureBuilder(
      future: UserService.getUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final profile = snapshot.data ?? {};
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(profile['photoUrl'] ?? ''),
              ),
              const SizedBox(height: 16),
              Text(
                profile['name'] ?? 'User',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(profile['email'] ?? ''),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _showEditProfileModal(context),
                child: const Text('Edit Profile'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentsTab() {
    return FutureBuilder(
      future: PaymentService.getPaymentHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final payments = snapshot.data ?? [];
        return ListView.builder(
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            return ListTile(
              leading: const Icon(Icons.payment),
              title: Text('Order #${payment['orderId']}'),
              subtitle: Text(payment['date'] ?? ''),
              trailing: Text('\$${payment['amount']?.toString() ?? '0'}'),
              onTap: () => showModalBottomSheet(
                context: context,
                builder: (context) => OrderStatusModal(
                  orderId: payment['orderId'],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditProfileModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => FutureBuilder<Map<String, dynamic>>(
        future: UserService.getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return EditProfileModal(user: snapshot.data ?? {});
        },
      ),
    );
  }

  void _showPaymentDetails(BuildContext context, Map<String, dynamic> payment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => PaymentModal(
        totalAmount: payment['amount'] ?? 0.0,
        onPaymentComplete: (String orderId) {
          Navigator.pop(context);
          // Refresh payment history
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyer Dashboard'),
        backgroundColor: Colors.deepPurple,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  // TODO: Navigate to cart screen
                },
              ),
              if (_cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _cartItemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) =>
                        NotificationList(notifications: _notifications),
                  );
                },
              ),
              if (_notifications.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _notifications.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
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
              icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payments'),
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

class NotificationList extends StatelessWidget {
  final List<dynamic> notifications;

  const NotificationList({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text(notification['title'] ?? ''),
                  subtitle: Text(notification['message'] ?? ''),
                  trailing: Text(notification['time'] ?? ''),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
