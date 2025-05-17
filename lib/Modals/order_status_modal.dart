// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/payment_service.dart';

class OrderStatusModal extends StatefulWidget {
  final String orderId;

  const OrderStatusModal({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderStatusModal> createState() => _OrderStatusModalState();
}

class _OrderStatusModalState extends State<OrderStatusModal> {
  Map<String, dynamic>? _payment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayment();
  }

  Future<void> _loadPayment() async {
    final payments = await PaymentService.getPayments();
    final payment = payments.firstWhere(
      (p) => p['id'] == widget.orderId,
      orElse: () => {},
    );

    if (mounted) {
      setState(() {
        _payment = payment;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Order Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_payment == null)
              const Text('Order not found')
            else
              Column(
                children: [
                  Text(
                    'Order ID: ${_payment!['id']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Amount: \$${(_payment!['amount'] as double).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Payment Method: ${_payment!['paymentMethod']}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Payment Timing: ${_payment!['paymentTiming']}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _payment!['status'] == 'Approved'
                          ? Colors.green.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _payment!['status'] == 'Approved'
                              ? Icons.check_circle
                              : Icons.pending,
                          color: _payment!['status'] == 'Approved'
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Status: ${_payment!['status']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _payment!['status'] == 'Approved'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
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
    );
  }
}
