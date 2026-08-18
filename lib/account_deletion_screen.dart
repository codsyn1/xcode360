import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountDeletionScreen extends StatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  State<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen> {
  bool _isConfirmed = false;
  final bool _isLoading = false;
  final TextEditingController _confirmationController = TextEditingController();

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _launchEmail() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userEmail = currentUser?.email ?? 'your registered email';
    
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'jehangir.business@gmail.com',
      query: 'subject=Account Deletion Request - XCODE360&body=Please delete my account and all associated data. My email is: $userEmail\n\nI understand that:\n- This action cannot be undone\n- All my data will be permanently deleted\n- I will lose access to all app features\n\nPlease confirm receipt and process this request.',
    );

    if (!await launchUrl(emailUri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch email app'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email app opened successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _launchPrivacyPolicy() async {
    final Uri privacyUri = Uri(
      scheme: 'https',
      host: 'example.com',
      path: '/privacy-policy',
    );

    if (!await launchUrl(privacyUri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch privacy policy'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text(
            'Confirm Account Deletion',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action cannot be undone. All your data will be permanently deleted.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmationController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Type "DELETE" to confirm',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: _confirmationController.text == 'DELETE'
                  ? () {
                      Navigator.of(context).pop();
                      _launchEmail();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Deletion'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Deletion'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This action is permanent and cannot be undone',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Account Deletion Request',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // What happens section
            const _SectionCard(
              title: 'What happens after deletion:',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DeletionItem(
                    icon: Icons.delete_forever,
                    text: 'Your account will be permanently deleted',
                  ),
                  _DeletionItem(
                    icon: Icons.cloud_off,
                    text: 'All personal data will be removed from our servers',
                  ),
                  _DeletionItem(
                    icon: Icons.lock_outline,
                    text: 'You will lose access to all app features',
                  ),
                  _DeletionItem(
                    icon: Icons.history_toggle_off,
                    text: 'This action cannot be undone',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Data retention info (Play Store compliance)
            const _SectionCard(
              title: 'Data Retention Policy:',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• Some data may be retained for legal obligations\n• Transaction records may be kept for tax purposes\n• Anonymous analytics data may be preserved\n• You can request a copy of your data before deletion',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Alternative options
            const _SectionCard(
              title: 'Alternative Options:',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'If you\'re having issues with your account, consider:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 8),
                  _AlternativeOption(
                    icon: Icons.settings,
                    title: 'Update your settings',
                    description: 'Change preferences or privacy settings',
                  ),
                  _AlternativeOption(
                    icon: Icons.pause_circle_outline,
                    title: 'Take a break',
                    description: 'Log out instead of deleting your account',
                  ),
                  _AlternativeOption(
                    icon: Icons.support_agent,
                    title: 'Contact support',
                    description: 'We can help resolve your issues',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Confirmation checkbox
            Row(
              children: [
                Checkbox(
                  value: _isConfirmed,
                  onChanged: (value) {
                    setState(() {
                      _isConfirmed = value ?? false;
                    });
                  },
                  activeColor: Colors.red,
                ),
                const Expanded(
                  child: Text(
                    'I understand that this action cannot be undone',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Delete button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isConfirmed ? _showConfirmationDialog : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Request Account Deletion',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Privacy policy link
            Center(
              child: TextButton(
                onPressed: _launchPrivacyPolicy,
                child: const Text(
                  'View Privacy Policy',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DeletionItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DeletionItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlternativeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  const _AlternativeOption({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
