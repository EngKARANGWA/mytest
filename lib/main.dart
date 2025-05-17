import 'package:flutter/material.dart';
import 'Signup_page/buyer_signup.dart';
import 'Signup_page/seller_signup.dart';
import 'Login_page/buyer_login.dart';
import 'Login_page/seller_login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Text('Welcome to Flutter'),
      ),
    );
  }
}

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  void _showUserTypeModal(BuildContext context, {bool isLogin = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isLogin ? "Login as:" : "Continue as:",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildUserTypeButton(
                    context,
                    "Buyer",
                    Colors.deepPurple,
                    isLogin ? const BuyerLoginScreen() : const BuyerSignup(),
                  ),
                  _buildUserTypeButton(
                    context,
                    "Seller",
                    Colors.deepPurple,
                    isLogin ? const SellerLoginScreen() : const SellerSignup(),
                    isOutlined: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserTypeButton(
    BuildContext context,
    String text,
    Color color,
    Widget destination, {
    bool isOutlined = false,
  }) {
    return isOutlined
        ? OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: BorderSide(color: color),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => destination),
              );
            },
            child: Text(
              text,
              style: TextStyle(fontSize: 18, color: color),
            ),
          )
        : ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => destination),
              );
            },
            child: Text(
              text,
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isLandscape = screenSize.width > screenSize.height;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200;
    final isDesktop = screenSize.width >= 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('E-Link', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("images/elink1.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withAlpha(102)),
          Center(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                margin: EdgeInsets.all(isSmallScreen ? 16 : 24),
                constraints: BoxConstraints(
                  maxWidth:
                      isDesktop ? 600 : (isTablet ? 500 : double.infinity),
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(38),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(77)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Welcome to E-Link!!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isDesktop ? 32 : (isTablet ? 28 : 24),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(
                        height: isLandscape ? 16 : (isSmallScreen ? 20 : 30)),
                    if (isLandscape)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _buildAuthButton(
                              context,
                              "Login",
                              onPressed: () =>
                                  _showUserTypeModal(context, isLogin: true),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildAuthButton(
                              context,
                              "Sign Up",
                              isOutlined: true,
                              onPressed: () => _showUserTypeModal(context),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildAuthButton(
                            context,
                            "Login",
                            onPressed: () =>
                                _showUserTypeModal(context, isLogin: true),
                          ),
                          SizedBox(height: isSmallScreen ? 10 : 15),
                          _buildAuthButton(
                            context,
                            "Sign Up",
                            isOutlined: true,
                            onPressed: () => _showUserTypeModal(context),
                          ),
                        ],
                      ),
                    SizedBox(
                        height: isLandscape ? 16 : (isSmallScreen ? 10 : 15)),
                    TextButton(
                      onPressed: () {
                        final emailController = TextEditingController();
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Reset Password',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: emailController,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.email),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (emailController.text.isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Please enter your email')),
                                        );
                                        return;
                                      }
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Password reset link sent to your email'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      minimumSize:
                                          const Size(double.infinity, 48),
                                    ),
                                    child: const Text('Send Reset Link'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    SizedBox(
                        height: isLandscape ? 16 : (isSmallScreen ? 15 : 20)),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12.0 : 16.0),
                      child: Text(
                        "This mobile app connects buyers and sellers based on distance.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isDesktop ? 18 : (isTablet ? 16 : 15),
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 15),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthButton(
    BuildContext context,
    String text, {
    bool isOutlined = false,
    required VoidCallback onPressed,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isLandscape = screenSize.width > screenSize.height;

    return isOutlined
        ? OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: isLandscape ? 12 : (isSmallScreen ? 12 : 14),
                horizontal: isLandscape ? 16 : (isSmallScreen ? 38 : 40),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: const BorderSide(color: Colors.white70),
            ),
            onPressed: onPressed,
            child: Text(
              text,
              style: TextStyle(
                fontSize: isLandscape ? 16 : (isSmallScreen ? 18 : 20),
                color: Colors.white,
              ),
            ),
          )
        : ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: EdgeInsets.symmetric(
                vertical: isLandscape ? 12 : (isSmallScreen ? 12 : 14),
                horizontal: isLandscape ? 16 : (isSmallScreen ? 40 : 42),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: onPressed,
            child: Text(
              text,
              style: TextStyle(
                fontSize: isLandscape ? 16 : (isSmallScreen ? 18 : 20),
                color: Colors.white,
              ),
            ),
          );
  }
}
