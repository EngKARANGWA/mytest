// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../services/payment_service.dart';

class SellerPaymentsTab extends StatefulWidget {
  const SellerPaymentsTab({super.key});

  @override
  State<SellerPaymentsTab> createState() => _SellerPaymentsTabState();
}

class _SellerPaymentsTabState extends State<SellerPaymentsTab> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: PaymentService.getPayments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No pending payments'));
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
                            color:
                                payment['status'] == 'Approved'
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            payment['status'],
                            style: TextStyle(
                              color:
                                  payment['status'] == 'Approved'
                                      ? Colors.green
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
                    if (payment['status'] == 'Pending')
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await PaymentService.updatePaymentStatus(
                                  payment['id'],
                                  'Approved',
                                );
                                setState(() {});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                minimumSize: const Size(double.infinity, 48),
                              ),
                              child: const Text('Approve Payment'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                await PaymentService.updatePaymentStatus(
                                  payment['id'],
                                  'Rejected',
                                );
                                setState(() {});
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                        ],
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
}
