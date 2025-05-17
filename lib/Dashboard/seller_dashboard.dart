// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import 'tabs/seller_products_tab.dart';
import 'tabs/seller_add_product_tab.dart';
import 'tabs/seller_payments_tab.dart';
import 'tabs/seller_profile_tab.dart';
import 'widgets/seller_dashboard_widgets.dart';
import '../Product/product_post_modal.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  int _currentIndex = 0;
  bool _notificationsEnabled = true;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
    _loadThemePreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });
  }

  Future<void> _loadThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    setState(() {
      _isDarkMode = value;
    });
  }

  Future<void> _showNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final sellerId = prefs.getString('current_user_id') ?? 'default_seller';
    final notifications = await NotificationService.getNotifications(
      sellerId: sellerId,
    );
    if (!mounted) return;

    showNotificationsDialog(context, notifications);
  }

  Future<void> _showSettings() async {
    showSettingsDialog(context, _notificationsEnabled, _isDarkMode,
        _toggleNotifications, _toggleTheme);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Seller Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: _showNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          // My Products Tab
          SellerProductsTab(),
          // Add Product Tab
          SellerAddProductTab(),
          // Payments Tab
          SellerPaymentsTab(),
          // Profile Tab
          SellerProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.blue,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'My Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Add Product',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payments'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const ProductPostModal(),
          );
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
