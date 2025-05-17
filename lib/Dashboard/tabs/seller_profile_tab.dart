import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../Modals/edit_profile_modal.dart';

class SellerProfileTab extends StatefulWidget {
  const SellerProfileTab({super.key});

  @override
  State<SellerProfileTab> createState() => _SellerProfileTabState();
}

class _SellerProfileTabState extends State<SellerProfileTab> {
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
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
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

  @override
  Widget build(BuildContext context) {
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
                  child: Icon(Icons.person, size: 50, color: Colors.white),
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
                        'Business Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.person,
                        'Name',
                        user['name'] ?? 'Not set',
                      ),
                      const Divider(),
                      _buildInfoRow(
                        Icons.business,
                        'Business Name',
                        user['businessName'] ?? 'Not set',
                      ),
                      const Divider(),
                      _buildInfoRow(
                        Icons.email,
                        'Email',
                        user['email'] ?? 'Not set',
                      ),
                      const Divider(),
                      _buildInfoRow(
                        Icons.phone,
                        'Phone',
                        user['phone'] ?? 'Not set',
                      ),
                      const Divider(),
                      _buildInfoRow(
                        Icons.location_on,
                        'Business Address',
                        user['businessAddress'] ?? 'Not set',
                      ),
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
                      _buildInfoRow(
                        Icons.account_circle,
                        'User Type',
                        'Seller',
                      ),
                      const Divider(),
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Member Since',
                        DateTime.parse(
                          user['createdAt'] ?? DateTime.now().toIso8601String(),
                        ).toString().split(' ')[0],
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
}
