import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

class AgencyExchangeProjectsScreen extends StatefulWidget {
  final String currentUserId;
  final String receiverId;
  final String receiverName;
  final String? receiverAvatar;

  const AgencyExchangeProjectsScreen({
    Key? key,
    required this.currentUserId,
    required this.receiverId,
    required this.receiverName,
    this.receiverAvatar,
  }) : super(key: key);

  @override
  State<AgencyExchangeProjectsScreen> createState() => _AgencyExchangeProjectsScreenState();
}

class _AgencyExchangeProjectsScreenState extends State<AgencyExchangeProjectsScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _projectTitleController = TextEditingController();
  final TextEditingController _projectTypeController = TextEditingController();
  final TextEditingController _projectDescriptionController = TextEditingController();
  final TextEditingController _exchangeNoteController = TextEditingController();
  DateTime? _startProjectDate;
  DateTime? _endProjectDate;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _projectTitleController.dispose();
    _projectTypeController.dispose();
    _projectDescriptionController.dispose();
    _exchangeNoteController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6200EE),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF2C2C2C),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != (isStartDate ? _startProjectDate : _endProjectDate)) {
      setState(() {
        if (isStartDate) {
          _startProjectDate = picked;
        } else {
          _endProjectDate = picked;
        }
      });
    }
  }

  Future<void> _sendExchangeRequest() async {
    print('=== EXCHANGE REQUEST SEND STARTED ===');
    print('Form key exists: ${_formKey.currentState != null}');
    print('Form valid: ${_formKey.currentState?.validate()}');
    print('Loading state: $_isLoading');
    print('Project title: "${_projectTitleController.text}"');
    print('Project type: "${_projectTypeController.text}"');
    print('Project description: "${_projectDescriptionController.text}"');
    print('Exchange note: "${_exchangeNoteController.text}"');
    print('Start date: $_startProjectDate');
    print('End date: $_endProjectDate');
    
    if (_isLoading) {
      print('Already loading - returning');
      return;
    }
    
    // Temporarily skip form validation for testing
    // if (!_formKey.currentState!.validate()) {
    //   print('Form validation failed - returning');
    //   return;
    // }

    // Basic validation instead
    if (_projectTitleController.text.trim().isEmpty) {
      print('Project title is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter project title'), backgroundColor: Colors.red),
      );
      return;
    }
    
    if (_projectTypeController.text.trim().isEmpty) {
      print('Project type is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter project type'), backgroundColor: Colors.red),
      );
      return;
    }
    
    if (_projectDescriptionController.text.trim().isEmpty) {
      print('Project description is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter project description'), backgroundColor: Colors.red),
      );
      return;
    }
    
    if (_exchangeNoteController.text.trim().isEmpty) {
      print('Exchange note is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter exchange note'), backgroundColor: Colors.red),
      );
      return;
    }

    // Additional validation for dates
    if (_startProjectDate == null || _endProjectDate == null) {
      print('Date validation failed - dates are null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both start and end dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_endProjectDate!.isBefore(_startProjectDate!)) {
      print('Date order validation failed - end date before start date');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('All validations passed - proceeding with send');
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    print('Current user: ${user?.uid}');
    
    if (user == null) {
      print('User not logged in');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      print('Fetching user data...');
      // Get user info
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      print('User doc exists: ${userDoc.exists}');
      if (userDoc.exists) {
        print('User data: ${userDoc.data()}');
      }

      // Safely get user data with proper field names
      final userData = userDoc.data() as Map<String, dynamic>?;
      final userName = userData?['name'] ?? userData?['userName'] ?? userData?['fullName'] ?? 'Unknown User';
      final userAvatar = userData?['avatarUrl'] ?? userData?['profileImage'] ?? userData?['photo'] ?? '';

      print('User name: $userName');
      print('User avatar: $userAvatar');
      print('Receiver ID: ${widget.receiverId}');
      print('Receiver name: ${widget.receiverName}');

      // Create request data
      final exchangeRequest = {
        'projectTitle': _projectTitleController.text.trim(),
        'projectType': _projectTypeController.text.trim(),
        'projectDescription': _projectDescriptionController.text.trim(),
        'exchangeNote': _exchangeNoteController.text.trim(),
        'startProjectDate': _startProjectDate,
        'endProjectDate': _endProjectDate,
        'fromUserId': user.uid,
        'fromUserName': userName,
        'fromUserAvatar': userAvatar,
        'toUserId': widget.receiverId,
        'toUserName': widget.receiverName,
        'toUserAvatar': widget.receiverAvatar,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'exchange_request',
        'isOutgoing': true,
      };

      print('Exchange request data: $exchangeRequest');

      // Save to main exchanges collection for the exchange projects screen
      final requestId = FirebaseFirestore.instance.collection('exchanges').doc().id;
      print('Generated request ID: $requestId');
      
      print('Saving to exchanges collection...');
      await FirebaseFirestore.instance
          .collection('exchanges')
          .doc(requestId)
          .set(exchangeRequest);
      print('Saved to exchanges collection');

      print('Saving to current user requests...');
      // Ensure current user document exists before saving to subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'lastUpdated': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      
      // Save to current user's requests
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('requests')
          .doc(requestId)
          .set(exchangeRequest);
      print('Saved to current user requests');

      print('Saving to receiver requests...');
      // Ensure receiver document exists before saving to subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.receiverId)
          .set({'lastUpdated': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      
      // Save to receiver's requests
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.receiverId)
          .collection('requests')
          .doc(requestId)
          .set(exchangeRequest);
      print('Saved to receiver requests');

      // Send offline notification to receiver
      print('Sending offline notification...');
      await NotificationService().sendExchangeRequestNotification(
        fromUserId: user.uid,
        fromUserName: userName,
        toUserId: widget.receiverId,
        toUserName: widget.receiverName,
        projectTitle: _projectTitleController.text.trim(),
        requestId: requestId,
      );
      print('Offline notification sent');

      setState(() {
        _isLoading = false;
      });

      // Clear all fields
      _projectTitleController.clear();
      _projectTypeController.clear();
      _projectDescriptionController.clear();
      _exchangeNoteController.clear();
      setState(() {
        _startProjectDate = null;
        _endProjectDate = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exchange request sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      print('Error sending exchange request: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;
    final isSmallScreen = screenHeight < 700;
    final isCompactScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text(
          'Exchange Projects with ${widget.receiverName}',
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 16 : 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: isSmallScreen ? 20 : 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: screenHeight - (isSmallScreen ? 120 : 140),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isWide ? 32 : (isSmallScreen ? 12 : 16)),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isWide ? 24 : (isSmallScreen ? 16 : 20)),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(isWide ? 20 : (isSmallScreen ? 12 : 16)),
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
                        Row(
                          children: [
                            Container(
                              width: isWide ? 60 : (isSmallScreen ? 40 : 50),
                              height: isWide ? 60 : (isSmallScreen ? 40 : 50),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.swap_horiz,
                                color: Colors.black,
                                size: isSmallScreen ? 20 : 30,
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 12 : 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Project Exchange Request',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isWide ? 24 : (isSmallScreen ? 16 : 20),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 2 : 4),
                                  Text(
                                    'Send a project exchange request to ${widget.receiverName}',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: isWide ? 16 : (isSmallScreen ? 12 : 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 16 : 24),

                  // Form Fields
                  _buildInputField(
                    'Project Title',
                    'Enter project title',
                    _projectTitleController,
                    Icons.title,
                    isSmallScreen: isSmallScreen,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter project title';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: isSmallScreen ? 12 : 16),

                  _buildInputField(
                    'Project Type',
                    'Enter project type',
                    _projectTypeController,
                    Icons.category,
                    isSmallScreen: isSmallScreen,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter project type';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: isSmallScreen ? 12 : 16),

                  // Date Fields Row
                  isCompactScreen
                      ? Column(
                          children: [
                            _buildDateField(
                              'Start Project Date',
                              _startProjectDate,
                              true,
                              isSmallScreen: isSmallScreen,
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 16),
                            _buildDateField(
                              'End Project Date',
                              _endProjectDate,
                              false,
                              isSmallScreen: isSmallScreen,
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _buildDateField(
                                'Start Project Date',
                                _startProjectDate,
                                true,
                                isSmallScreen: isSmallScreen,
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 8 : 16),
                            Expanded(
                              child: _buildDateField(
                                'End Project Date',
                                _endProjectDate,
                                false,
                                isSmallScreen: isSmallScreen,
                              ),
                            ),
                          ],
                        ),

                  SizedBox(height: isSmallScreen ? 12 : 16),

                  // Description Field
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isWide ? 20 : (isSmallScreen ? 12 : 16)),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(isWide ? 16 : (isSmallScreen ? 10 : 12)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.description, color: Colors.white, size: isSmallScreen ? 18 : 20),
                            SizedBox(width: isSmallScreen ? 6 : 8),
                            Text(
                              'Project Description',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isWide ? 16 : (isSmallScreen ? 14 : 14),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        TextFormField(
                          controller: _projectDescriptionController,
                          style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 14 : 16),
                          maxLines: isSmallScreen ? 3 : 5,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter project description';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'Describe your project in detail...',
                            hintStyle: TextStyle(color: Colors.white54, fontSize: isSmallScreen ? 14 : 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                            contentPadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 12 : 16),

                  _buildInputField(
                    'Exchange Note',
                    'Enter exchange note',
                    _exchangeNoteController,
                    Icons.note,
                    isSmallScreen: isSmallScreen,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter exchange note';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: isSmallScreen ? 24 : 32),

                  // Send Request Button
                  SizedBox(
                    width: double.infinity,
                    height: isWide ? 56 : (isSmallScreen ? 44 : 48),
                    child: ElevatedButton(
                      onPressed: () {
                        print('=== SEND BUTTON PRESSED ===');
                        print('Is loading: $_isLoading');
                        print('Send function callable: ${_sendExchangeRequest != null}');
                        
                        if (_isLoading) {
                          print('Button disabled - currently loading');
                          return;
                        }
                        
                        print('Calling _sendExchangeRequest...');
                        _sendExchangeRequest();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C2C2C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(isWide ? 16 : (isSmallScreen ? 10 : 12)),
                        ),
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: isSmallScreen ? 16 : 20,
                                  height: isSmallScreen ? 16 : 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: isSmallScreen ? 8 : 12),
                                Text(
                                  'Sending...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Send Exchange Request',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 24 : 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller,
    IconData icon, {
    String? Function(String?)? validator,
    required bool isSmallScreen,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 20 : (isSmallScreen ? 12 : 16)),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(isWide ? 16 : (isSmallScreen ? 10 : 12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: isSmallScreen ? 18 : 20),
              SizedBox(width: isSmallScreen ? 6 : 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isWide ? 16 : (isSmallScreen ? 14 : 14),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          TextFormField(
            controller: controller,
            style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 14 : 16),
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white54, fontSize: isSmallScreen ? 14 : 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white),
              ),
              contentPadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, bool isStartDate, {required bool isSmallScreen}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 20 : (isSmallScreen ? 12 : 16)),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(isWide ? 16 : (isSmallScreen ? 10 : 12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white, size: isSmallScreen ? 18 : 20),
              SizedBox(width: isSmallScreen ? 6 : 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isWide ? 16 : (isSmallScreen ? 14 : 14),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          GestureDetector(
            onTap: () => _selectDate(context, isStartDate),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16, 
                vertical: isSmallScreen ? 8 : 12
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.date_range,
                    color: date != null ? Colors.white : Colors.white54,
                    size: isSmallScreen ? 18 : 20,
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  Expanded(
                    child: Text(
                      date != null
                          ? DateFormat('MMM dd, yyyy').format(date!)
                          : 'Select date',
                      style: TextStyle(
                        color: date != null ? Colors.white : Colors.white54,
                        fontSize: isSmallScreen ? 14 : 14,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.white54, size: isSmallScreen ? 18 : 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
