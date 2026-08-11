import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class AgencyPaymentPage extends StatefulWidget {
  final String userId;
  const AgencyPaymentPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<AgencyPaymentPage> createState() => _AgencyPaymentPageState();
}

class _AgencyPaymentPageState extends State<AgencyPaymentPage> {
  String selectedPlan = 'Monthly';

  final Map<String, String> bankDetails = {
    'Bank Name': 'NBP : National Bank of Pakistan',
    'Account Name': 'Hostings Ware SMC Private Limited',
    'Account Number': '03154249365340',
    'IBAN': 'PK77NBPA0315004249365340',
    'Country': 'Pakistan',
  };

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openWhatsApp() async {
    final phoneNumber = '+923215971854'; // Business WhatsApp number
    final message = 'Hello, I have sent the payment for Agency Pro Plan. Please activate my account. User ID: ${widget.userId}';
    final url = 'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';
    
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch WhatsApp'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: const Text(
          'Upgrade to Pro',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: isWide ? 32 : 16,
          right: isWide ? 32 : 16,
          top: isWide ? 24 : 16,
          bottom: isWide ? 60 : 50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bank Payment Details Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isWide ? 24 : 20),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(isWide ? 20 : 16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bank Payment Details',
                    style: TextStyle(
                      color: Color(0xFFFFD700), // Yellow color
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...bankDetails.entries.map((entry) => _buildBankDetailRow(
                    entry.key,
                    entry.value,
                    isWide,
                  )).toList(),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Select Plan Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isWide ? 24 : 20),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(isWide ? 20 : 16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Plan',
                    style: TextStyle(
                      color: Color(0xFFFFD700), // Yellow color
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPlanOption('Monthly', '\$1', isWide),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Payment Instructions
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isWide ? 24 : 20),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(isWide ? 20 : 16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Instructions',
                    style: TextStyle(
                      color: Color(0xFFFFD700), // Yellow color
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'After sending payment, please share the payment screenshot on WhatsApp so our team can activate your Pro account. Thank you.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // WhatsApp Button outside container
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openWhatsApp,
                icon: Icon(Icons.message, color: Colors.white, size: isWide ? 20 : 18),
                label: Text(
                  'Message us on WhatsApp',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isWide ? 16 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C2C2C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isWide ? 16 : 12),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 20 : 16,
                    vertical: isWide ? 14 : 12,
                  ),
                  minimumSize: Size(0, isWide ? 56 : 48),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBankDetailRow(String label, String value, bool isWide) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: isWide ? 16 : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(':', style: TextStyle(color: Colors.white70)),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: isWide ? 16 : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _copyToClipboard(value),
            child: Container(
              padding: EdgeInsets.all(isWide ? 8 : 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isWide ? 8 : 6),
              ),
              child: Icon(
                Icons.copy,
                color: const Color(0xFFFFD700),
                size: isWide ? 20 : 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption(String planName, String price, bool isWide) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlan = planName;
        });
      },
      child: Container(
        padding: EdgeInsets.all(isWide ? 16 : 14),
        decoration: BoxDecoration(
          color: selectedPlan == planName 
              ? Colors.white.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(isWide ? 12 : 10),
          border: Border.all(
            color: selectedPlan == planName 
                ? const Color(0xFFFFD700)
                : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: planName,
              groupValue: selectedPlan,
              onChanged: (value) {
                setState(() {
                  selectedPlan = value!;
                });
              },
              activeColor: const Color(0xFFFFD700),
              fillColor: MaterialStateProperty.resolveWith<Color>(
                (states) => const Color(0xFFFFD700),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              planName,
              style: TextStyle(
                color: Colors.white,
                fontSize: isWide ? 18 : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              price,
              style: TextStyle(
                color: const Color(0xFFFFD700),
                fontSize: isWide ? 18 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
