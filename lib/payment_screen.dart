import 'package:flutter/material.dart';
// import 'package:twocheckout_flutter/twocheckout_flutter.dart';

class PaymentScreen extends StatefulWidget {
  final String userId;
  final String? plan;
  final int? price;

  const PaymentScreen({super.key, required this.userId, this.plan, this.price});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedMethod = 0;
  final List<String> _methods = [
    'Credit Card',
    'EasyPaisa',
    'JazzCash',
    'Bank Transfer',
  ];

  // Credit Card controllers
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // EasyPaisa/JazzCash/Bank Transfer controllers
  final TextEditingController _accountController = TextEditingController();

  String? plan;
  int? price;

  // Remove 2Checkout plugin instance and related code

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Accept arguments from ModalRoute if not provided directly
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      plan = args['plan'] as String?;
      price = args['price'] as int?;
    } else {
      plan = widget.plan;
      price = widget.price;
    }
  }

  @override
  void initState() {
    super.initState();
    // Removed 2Checkout credentials setup
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  Widget _buildMethodContent() {
    switch (_selectedMethod) {
      case 0:
        // Restore dummy Credit Card form
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Card Number'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expiryController,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(labelText: 'Expiry (M  M/YY)'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _cvvController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'CVV'),
                  ),
                ),
              ],
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name on Card'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Dummy action
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Credit Card payment submitted (dummy)!')),
                );
              },
              child: const Text('Pay with Credit Card'),
            ),
          ],
        );
      case 1:
        // EasyPaisa
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send payment to EasyPaisa account:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Account: 0345-XXXXXXX'),
            const SizedBox(height: 8),
            TextField(
              controller: _accountController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Your EasyPaisa Number'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('EasyPaisa payment info submitted (dummy)!')),
                );
              },
              child: const Text('Submit EasyPaisa Payment'),
            ),
          ],
        );
      case 2:
        // JazzCash
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send payment to JazzCash account:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Account: 0300-XXXXXXX'),
            const SizedBox(height: 8),
            TextField(
              controller: _accountController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Your JazzCash Number'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('JazzCash payment info submitted (dummy)!')),
                );
              },
              child: const Text('Submit JazzCash Payment'),
            ),
          ],
        );
      case 3:
        // Bank Transfer
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bank Transfer Details:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Account Title: XCODE360'),
            const Text('Account Number: 1234567890'),
            const Text('Bank: ABC Bank'),
            const SizedBox(height: 8),
            TextField(
              controller: _accountController,
              decoration: const InputDecoration(labelText: 'Your Bank Account/Ref No'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bank transfer info submitted (dummy)!')),
                );
              },
              child: const Text('Submit Bank Transfer'),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan != null && price != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      plan == 'monthly'
                        ? '\$4 Monthly'
                        : plan == 'yearly'
                          ? '\$35 Yearly'
                          : '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.amber),
                    ),
                  ],
                ),
              ),
            const Text('Select Payment Method:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_methods.length, (i) => ChoiceChip(
                label: Text(_methods[i]),
                selected: _selectedMethod == i,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedMethod = i);
                },
              )),
            ),
            const SizedBox(height: 24),
            _buildMethodContent(),
          ],
        ),
      ),
    );
  }
} 