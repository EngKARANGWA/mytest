// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'Signup_page/seller_signup.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userType = 'Buyer';

  void _showUserTypeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 250,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Continue as:",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 30,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        userType = 'Buyer';
                      });
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Buyer",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 30,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: const BorderSide(color: Colors.deepPurple),
                    ),
                    onPressed: () {
                      setState(() {
                        userType = 'Seller';
                      });
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Seller",
                      style: TextStyle(fontSize: 18, color: Colors.deepPurple),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBuyerCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Buyer Login",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "As a Buyer, you can browse and purchase products from sellers near you.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // Handle buyer login
              },
              child: const Text(
                "Login",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: const BorderSide(color: Colors.deepPurple),
              ),
              onPressed: () {
                // Navigate to Seller Signup Page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SellerSignup()),
                );
              },
              child: const Text(
                "Sign Up",
                style: TextStyle(fontSize: 18, color: Colors.deepPurple),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Seller Login",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "As a Seller, you can list your products and reach potential buyers nearby.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // Handle seller login
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SellerSignup()),
                );
              },
              child: const Text(
                "Login",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: const BorderSide(color: Colors.deepPurple),
              ),
              onPressed: () {
                // Navigate to Seller Signup Page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SellerSignup()),
                );
              },
              child: const Text(
                "Sign Up",
                style: TextStyle(fontSize: 18, color: Colors.deepPurple),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login and Signup Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => _showUserTypeModal(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: userType == 'Buyer' ? _buildBuyerCard() : _buildSellerCard(),
        ),
      ),
    );
  }
}
