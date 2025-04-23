import 'package:flutter/material.dart';
import '../../models/cleaning_package.dart';
import '../../models/booking.dart';
import '../../services/payment_service.dart';
import '../../services/supabase_service.dart';

class PaymentScreen extends StatefulWidget {
  final CleaningPackage package;
  final DateTime scheduledDate;
  final String address;
  final String location;
  final String description;

  const PaymentScreen({
    super.key,
    required this.package,
    required this.scheduledDate,
    required this.address,
    required this.location,
    required this.description,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedPaymentMethod;
  final _phoneController = TextEditingController();
  bool _isProcessing = false;

  final _paymentMethods = [
    {'name': 'EVC-Plus', 'icon': Icons.phone_android},
    {'name': 'Zaad', 'icon': Icons.account_balance_wallet},
    {'name': 'e-Dahab', 'icon': Icons.currency_exchange},
  ];

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Get current user
      final user = await SupabaseService().getCurrentUser();
      if (user == null) throw Exception('User not authenticated');

      print(
          "Processing payment with phone number: ${_phoneController.text.trim()}");

      // Process payment first
      final paymentResponse = await PaymentService().makePayment(
        _phoneController.text.trim(),
        widget.package.price,
        'Payment for ${widget.package.name} cleaning service',
      );

      print("Payment response message: $paymentResponse");

      // Handle different payment responses
      if (paymentResponse == "RCS_USER_REJECTED") {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment was rejected by user. Please try again.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (paymentResponse == "RCS_SUCCESS") {
        print("Payment successful, storing booking details...");

        // Create booking with completed payment status
        final booking = Booking(
          customerId: user.id.toString(),
          packageId: widget.package.id,
          scheduledDate: widget.scheduledDate,
          address: widget.address,
          location: widget.location,
          description: widget.description,
          status: BookingStatus.pending.toString().split('.').last,
          paymentStatus: PaymentStatus.completed.toString().split('.').last,
          paymentAmount: widget.package.price,
          paymentMethod: _selectedPaymentMethod,
          paymentReference: paymentResponse,
          paymentPhoneNumber: _phoneController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Save booking to database
        await SupabaseService().createBooking(booking);
        print("Booking stored successfully");

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Payment successful! Your booking has been confirmed.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        throw Exception('Payment failed: Unexpected response');
      }
    } catch (e) {
      print("Error in payment process: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Package Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Package Summary',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      widget.package.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.package.description),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Duration: ${widget.package.durationMinutes ~/ 60} hours',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Price: \$${widget.package.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select Payment Method',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // Payment Methods
            Card(
              child: Column(
                children: _paymentMethods.map((method) {
                  return RadioListTile(
                    value: method['name'],
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value as String;
                      });
                    },
                    title: Row(
                      children: [
                        Icon(method['icon'] as IconData),
                        const SizedBox(width: 16),
                        Text(method['name'] as String),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedPaymentMethod != null) ...[
              Text(
                'Enter Phone Number',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Proceed to Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
