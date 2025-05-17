import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../services/payment_service.dart';

class PaymentModal extends StatefulWidget {
  final double totalAmount;
  final Function(String) onPaymentComplete;

  const PaymentModal({
    super.key,
    required this.totalAmount,
    required this.onPaymentComplete,
  });

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  String _selectedPaymentMethod = 'Cash';
  String _paymentTiming = 'Pay Now';
  File? _paymentReferenceImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  final List<String> _paymentMethods = [
    'Cash',
    'Bank Transfer',
    'Mobile Payment',
    'Credit Card',
  ];

  Future<File> _resizeImage(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    const maxWidth = 800.0;
    const maxHeight = 800.0;

    double width = image.width.toDouble();
    double height = image.height.toDouble();

    if (width > maxWidth || height > maxHeight) {
      if (width / height > maxWidth / maxHeight) {
        width = maxWidth;
        height = (maxWidth * image.height) / image.width;
      } else {
        height = maxHeight;
        width = (maxHeight * image.width) / image.height;
      }
    }

    final resizedImage = await image.toByteData(format: ui.ImageByteFormat.png);
    final resizedBytes = resizedImage!.buffer.asUint8List();

    // Create a temporary file for the resized image
    final tempDir = Directory.systemTemp;
    final tempFile = File(
        '${tempDir.path}/resized_${DateTime.now().millisecondsSinceEpoch}.png');
    await tempFile.writeAsBytes(resizedBytes);

    return tempFile;
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final resizedFile = await _resizeImage(file);
      setState(() {
        _paymentReferenceImage = resizedFile;
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final resizedFile = await _resizeImage(file);
      setState(() {
        _paymentReferenceImage = resizedFile;
      });
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Payment Reference'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPayment() async {
    if (_paymentReferenceImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a payment reference'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final orderId = await PaymentService.processPayment(
        amount: widget.totalAmount,
        paymentMethod: _selectedPaymentMethod,
        paymentTiming: _paymentTiming,
        paymentReference: _paymentReferenceImage!,
      );

      if (!mounted) return;

      Navigator.pop(context); // Close payment modal
      widget.onPaymentComplete(orderId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing payment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Payment Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Total Amount: \$${widget.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payment),
                ),
                items: _paymentMethods.map((String method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Text(method),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedPaymentMethod = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _paymentTiming,
                decoration: const InputDecoration(
                  labelText: 'Payment Timing',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Pay Now',
                    child: Text('Pay Now'),
                  ),
                  DropdownMenuItem(
                    value: 'Pay Later',
                    child: Text('Pay Later'),
                  ),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _paymentTiming = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              if (_paymentReferenceImage != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.file(
                    _paymentReferenceImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showImageSourceDialog,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text(_paymentReferenceImage == null
                    ? 'Add Payment Reference'
                    : 'Change Payment Reference'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Payment'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
