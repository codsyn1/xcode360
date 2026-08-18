import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AgencyProAdminScreen extends StatefulWidget {
  const AgencyProAdminScreen({super.key});

  @override
  State<AgencyProAdminScreen> createState() => _AgencyProAdminScreenState();
}

class _AgencyProAdminScreenState extends State<AgencyProAdminScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _recentUsers = [];
  String? _selectedUserId;
  String? _selectedUserName;
  String? _selectedUserEmail;
  String? _selectedUserPlan;

  @override
  void initState() {
    super.initState();
    _fetchRecentUsers();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecentUsers() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      
      setState(() {
        _recentUsers = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'name': data['fullName'] ?? data['name'] ?? 'Unknown',
            'email': data['email'] ?? 'No email',
            'plan': data['plan'] ?? 'Free',
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching users: $e')),
      );
    }
  }

  Future<void> _giveProAccess() async {
    final userId = _selectedUserId ?? _userIdController.text.trim();
    final email = _emailController.text.trim();

    if (userId.isEmpty && email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter User ID or Email')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String targetUserId = userId;

      // If email is provided, find user by email
      if (email.isNotEmpty && userId.isEmpty) {
        QuerySnapshot emailQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        
        if (emailQuery.docs.isEmpty) {
          throw Exception('No user found with this email');
        }
        
        targetUserId = emailQuery.docs.first.id;
      }

      // Update user plan to Pro
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .update({
        'plan': 'Pro',
        'planUpdatedAt': FieldValue.serverTimestamp(),
        'planGrantedBy': FirebaseAuth.instance.currentUser?.uid,
        'planGrantedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pro access granted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      _emailController.clear();
      _userIdController.clear();
      setState(() {
        _selectedUserId = null;
        _selectedUserName = null;
        _selectedUserEmail = null;
        _selectedUserPlan = null;
      });

      // Refresh recent users
      await _fetchRecentUsers();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _revokeProAccess(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'plan': 'Free',
        'planUpdatedAt': FieldValue.serverTimestamp(),
        'planRevokedBy': FirebaseAuth.instance.currentUser?.uid,
        'planRevokedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pro access revoked successfully!'),
          backgroundColor: Colors.orange,
        ),
      );

      await _fetchRecentUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _selectUser(Map<String, dynamic> user) {
    setState(() {
      _selectedUserId = user['id'];
      _selectedUserName = user['name'];
      _selectedUserEmail = user['email'];
      _selectedUserPlan = user['plan'];
      _userIdController.text = user['id'];
      _emailController.text = user['email'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: const Text(
          'Agency Pro Access',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grant Pro Access Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Grant Agency Pro Access',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Selected User Info (if any)
                  if (_selectedUserId != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedUserName ?? 'Unknown',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _selectedUserEmail ?? 'No email',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Current Plan: ${_selectedUserPlan ?? 'Free'}',
                                  style: TextStyle(
                                    color: _selectedUserPlan == 'Pro' ? Colors.green : Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              setState(() {
                                _selectedUserId = null;
                                _selectedUserName = null;
                                _selectedUserEmail = null;
                                _selectedUserPlan = null;
                                _emailController.clear();
                                _userIdController.clear();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'User Email',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFFD700)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: _userIdController,
                    decoration: const InputDecoration(
                      labelText: 'User ID (optional)',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFFD700)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _giveProAccess,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              'Grant Pro Access',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Recent Users Section
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Users',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Color(0xFFFFD700)),
                          onPressed: _fetchRecentUsers,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Expanded(
                      child: _recentUsers.isEmpty
                          ? const Center(
                              child: Text(
                                'No users found',
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _recentUsers.length,
                              itemBuilder: (context, index) {
                                final user = _recentUsers[index];
                                final isPro = user['plan'] == 'Pro';
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isPro 
                                          ? Colors.green.withOpacity(0.3)
                                          : Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: isPro ? Colors.green : Colors.grey,
                                        child: const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user['name'] ?? 'Unknown',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              user['email'] ?? 'No email',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.7),
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              'Plan: ${user['plan'] ?? 'Free'}',
                                              style: TextStyle(
                                                color: isPro ? Colors.green : Colors.orange,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          if (!isPro)
                                            IconButton(
                                              icon: const Icon(Icons.add, color: Colors.green),
                                              onPressed: () => _selectUser(user),
                                              tooltip: 'Grant Pro Access',
                                            ),
                                          if (isPro)
                                            IconButton(
                                              icon: const Icon(Icons.remove, color: Colors.red),
                                              onPressed: () => _revokeProAccess(user['id']),
                                              tooltip: 'Revoke Pro Access',
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
