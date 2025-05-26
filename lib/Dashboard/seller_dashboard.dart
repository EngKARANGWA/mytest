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
  final GlobalKey<SellerProductsTabState> _productsTabKey =
      GlobalKey<SellerProductsTabState>();

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

  Future<void> _showProductModal() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const ProductPostModal(),
    );

    // If product was created successfully, refresh the products tab
    if (result == true && _currentIndex == 0) {
      _productsTabKey.currentState?.refreshProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Seller Dashboard!',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications, color: Colors.white),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: _showNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              // Refresh current tab
              if (_currentIndex == 0) {
                _productsTabKey.currentState?.refreshProducts();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // My Products Tab
          SellerProductsTab(key: _productsTabKey),
          // Add Product Tab
          const SellerAddProductTab(),
          // Payments Tab
          const SellerPaymentsTab(),
          // Profile Tab
          const SellerProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
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

          // Refresh products when switching to My Products tab
          if (index == 0) {
            Future.delayed(const Duration(milliseconds: 100), () {
              _productsTabKey.currentState?.refreshProducts();
            });
          }
        },
      ),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1
          ? FloatingActionButton(
              onPressed: _showProductModal,
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
