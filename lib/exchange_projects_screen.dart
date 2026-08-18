import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/services.dart';

class ExchangeProjectsScreen extends StatefulWidget {
  final String currentUserId;
  const ExchangeProjectsScreen({super.key, required this.currentUserId});

  @override
  State<ExchangeProjectsScreen> createState() => _ExchangeProjectsScreenState();
}

class _ExchangeProjectsScreenState extends State<ExchangeProjectsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<List<Map<String, dynamic>>> _getRequestsStream() {
    print('=== GET REQUESTS STREAM STARTED ===');
    print('Current user ID: ${widget.currentUserId}');
    
    // Get ALL requests where current user is either sender or receiver with real-time updates
    final fromStream = FirebaseFirestore.instance
        .collection('exchanges')
        .where('fromUserId', isEqualTo: widget.currentUserId)
        .snapshots();
        
    final toStream = FirebaseFirestore.instance
        .collection('exchanges')
        .where('toUserId', isEqualTo: widget.currentUserId)
        .snapshots();
    
    // Combine both streams for real-time updates
    return Rx.combineLatest2(fromStream, toStream, (fromSnapshot, toSnapshot) {
      print('=== REAL-TIME UPDATE RECEIVED ===');
      
      // Combine both sent and received requests
      final fromRequests = fromSnapshot.docs.map((doc) {
        final data = doc.data();
        print('From request data: $data');
        return {
          'id': doc.id,
          'data': {...data, 'isOutgoing': true},
        };
      }).toList();
      
      final toRequests = toSnapshot.docs.map((doc) {
        final data = doc.data();
        print('To request data: $data');
        return {
          'id': doc.id,
          'data': {...data, 'isOutgoing': false},
        };
      }).toList();
      
      final allRequests = [...fromRequests, ...toRequests];
      
      // Sort by timestamp
      if (allRequests.isNotEmpty) {
        allRequests.sort((a, b) {
          final aData = a['data'] as Map<String, dynamic>?;
          final bData = b['data'] as Map<String, dynamic>?;
          final aTime = aData?['timestamp'] as Timestamp?;
          final bTime = bData?['timestamp'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime) ?? 0;
        });
      }
      
      print('Total requests count: ${allRequests.length}');
      return allRequests;
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
           '${dateTime.month.toString().padLeft(2, '0')}/'
           '${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }

  String _getCountryFlag(String country) {
    switch (country) {
      case 'US': return '🇺🇸';
      case 'PK': return '🇵🇰';
      case 'IN': return '🇮🇳';
      case 'GB': return '🇬🇧';
      case 'CA': return '🇨🇦';
      case 'AU': return '🇦🇺';
      case 'DE': return '🇩🇪';
      case 'FR': return '🇫🇷';
      case 'JP': return '🇯🇵';
      case 'KR': return '🇰🇷';
      case 'CN': return '🇨🇳';
      case 'BR': return '🇧🇷';
      case 'RU': return '🇷🇺';
      case 'SA': return '🇸🇦';
      case 'AE': return '🇦🇪';
      default: return '';
    }
  }

  Future<void> _acceptRequest(String requestId) async {
    try {
      // Update the main exchange document
      await FirebaseFirestore.instance
          .collection('exchanges')
          .doc(requestId)
          .update({'status': 'accepted'});

      // Get the exchange document to find both user IDs
      final exchangeDoc = await FirebaseFirestore.instance
          .collection('exchanges')
          .doc(requestId)
          .get();
      final exchangeData = exchangeDoc.data();
      final fromUserId = exchangeData?['fromUserId'];
      final toUserId = exchangeData?['toUserId'];

      // Update both users' request documents
      if (fromUserId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(fromUserId)
            .collection('requests')
            .doc(requestId)
            .update({'status': 'accepted'});
      }
      if (toUserId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(toUserId)
            .collection('requests')
            .doc(requestId)
            .update({'status': 'accepted'});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request accepted!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept request: ${e.toString()}')),
      );
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      // Update the main exchange document
      await FirebaseFirestore.instance
          .collection('exchanges')
          .doc(requestId)
          .update({'status': 'rejected'});

      // Get the exchange document to find both user IDs
      final exchangeDoc = await FirebaseFirestore.instance
          .collection('exchanges')
          .doc(requestId)
          .get();
      final exchangeData = exchangeDoc.data();
      final fromUserId = exchangeData?['fromUserId'];
      final toUserId = exchangeData?['toUserId'];

      // Update both users' request documents
      if (fromUserId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(fromUserId)
            .collection('requests')
            .doc(requestId)
            .update({'status': 'rejected'});
      }
      if (toUserId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(toUserId)
            .collection('requests')
            .doc(requestId)
            .update({'status': 'rejected'});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject request: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeCubit>().state == ThemeMode.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF232323) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        title: const Text('Exchange Projects'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: isDarkMode ? Colors.white : Colors.black),
            tooltip: 'Filter by date',
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDateRange: _selectedDateRange,
                builder: (context, child) => Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Colors.blueAccent,
                      onPrimary: Colors.white,
                      surface: Color(0xFF232323),
                      onSurface: Colors.white,
                    ), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF232323)),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                setState(() {
                  _selectedDateRange = picked;
                });
              }
            },
          ),
          if (_selectedDateRange != null)
            IconButton(
              icon: Icon(Icons.clear, color: isDarkMode ? Colors.white : Colors.black),
              tooltip: 'Clear date filter',
              onPressed: () {
                setState(() {
                  _selectedDateRange = null;
                });
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: isDarkMode ? Colors.white : Colors.black,
          labelColor: isDarkMode ? Colors.white : Colors.black,
          unselectedLabelColor: isDarkMode ? Colors.white70 : Colors.black54,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Accepted'),
            Tab(text: 'Rejected'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getRequestsStream(),
        builder: (context, snapshot) {
          print('=== STREAM BUILDER CALLED ===');
          print('Has data: ${snapshot.hasData}');
          print('Has error: ${snapshot.hasError}');
          
          if (!snapshot.hasData) {
            print('No data - showing loading');
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          
          final requests = snapshot.data!;
          print('Total requests count: ${requests.length}');
          
          // Filter requests by status for each tab
          List<Map<String, dynamic>> filteredRequests = requests;
          if (_selectedDateRange != null) {
            print('=== DATE FILTERING ACTIVE ===');
            print('Selected date range: ${_selectedDateRange!.start} to ${_selectedDateRange!.end}');
            
            filteredRequests = requests.where((r) {
              final data = r['data'] as Map<String, dynamic>;
              print('Processing request: ${data.keys.toList()}');
              print('Request data: $data');
              
              DateTime? start;
              DateTime? end;
              
              // Try multiple possible date field names
              try {
                // Check for various date field names
                final dateFields = ['startProjectDate', 'endProjectDate', 'startDate', 'endDate', 'timestamp', 'createdAt', 'created_at'];
                
                for (String field in dateFields) {
                  if (data[field] != null) {
                    print('Found date field: $field = ${data[field]}');
                    if (field.contains('start') || field == 'timestamp' || field.contains('created')) {
                      if (data[field] is Timestamp) {
                        start = (data[field] as Timestamp).toDate();
                      } else {
                        start = DateTime.tryParse(data[field].toString());
                      }
                    } else if (field.contains('end')) {
                      if (data[field] is Timestamp) {
                        end = (data[field] as Timestamp).toDate();
                      } else {
                        end = DateTime.tryParse(data[field].toString());
                      }
                    }
                  }
                }
                
                print('Parsed start date: $start');
                print('Parsed end date: $end');
              } catch (e) {
                print('Error parsing dates: $e');
              }
              
              // If no specific dates found, try to use timestamp as fallback
              if (start == null && end == null && data['timestamp'] != null) {
                if (data['timestamp'] is Timestamp) {
                  start = (data['timestamp'] as Timestamp).toDate();
                  end = (data['timestamp'] as Timestamp).toDate();
                  print('Using timestamp as fallback: $start');
                }
              }
              
              if (start == null && end == null) {
                print('No valid dates found, excluding request');
                return false;
              }
              
              final rangeStart = _selectedDateRange!.start;
              final rangeEnd = _selectedDateRange!.end;
              
              // Normalize dates to ignore time component
              final rangeStartOnly = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
              final rangeEndOnly = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);
              
              bool inRange = false;
              
              if (start != null) {
                final startOnly = DateTime(start.year, start.month, start.day);
                if ((startOnly.isAtSameMomentAs(rangeStartOnly) || startOnly.isAfter(rangeStartOnly)) && 
                    (startOnly.isAtSameMomentAs(rangeEndOnly) || startOnly.isBefore(rangeEndOnly))) {
                  inRange = true;
                  print('Start date $startOnly is in range');
                }
              }
              
              if (end != null) {
                final endOnly = DateTime(end.year, end.month, end.day);
                if ((endOnly.isAtSameMomentAs(rangeStartOnly) || endOnly.isAfter(rangeStartOnly)) && 
                    (endOnly.isAtSameMomentAs(rangeEndOnly) || endOnly.isBefore(rangeEndOnly))) {
                  inRange = true;
                  print('End date $endOnly is in range');
                }
              }
              
              print('Request in range: $inRange');
              return inRange;
            }).toList();
            
            print('Filtered requests count: ${filteredRequests.length}');
          } else {
            print('=== NO DATE FILTER ===');
          }
          
          final pendingRequests = filteredRequests.where((r) => (r['data']['status'] ?? 'pending') == 'pending').toList();
          final acceptedRequests = filteredRequests.where((r) => (r['data']['status'] ?? '') == 'accepted').toList();
          final rejectedRequests = filteredRequests.where((r) => (r['data']['status'] ?? '') == 'rejected').toList();
          final completedRequests = filteredRequests.where((r) => (r['data']['status'] ?? '') == 'completed').toList();
          
          print('Pending requests: ${pendingRequests.length}');
          print('Accepted requests: ${acceptedRequests.length}');
          print('Rejected requests: ${rejectedRequests.length}');
          print('Completed requests: ${completedRequests.length}');

          List<Map<String, dynamic>> getTabRequests(int index) {
            switch (index) {
              case 0:
                return pendingRequests;
              case 1:
                return acceptedRequests;
              case 2:
                return rejectedRequests;
              case 3:
                return completedRequests;
              default:
                return [];
            }
          }

          return TabBarView(
            controller: _tabController,
            children: List.generate(4, (tabIndex) {
              final tabRequests = getTabRequests(tabIndex);
              if (tabRequests.isEmpty) {
                return Center(
                  child: Text(
                    'No exchange requests.',
                    style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 16),
                  ),
                );
              }
              return ListView.builder(
                itemCount: tabRequests.length,
                itemBuilder: (context, index) {
                  final request = tabRequests[index];
                  final data = request['data'] as Map<String, dynamic>;
                  final requestId = request['id'];
                  
                  final status = data['status'] ?? 'pending';
                  final title = data['projectTitle'] ?? data['title'] ?? '';
                  final type = data['projectType'] ?? data['type'] ?? '';
                  final description = data['projectDescription'] ?? data['description'] ?? '';
                  final note = data['exchangeNote'] ?? data['note'] ?? '';
                  final fromUserId = data['fromUserId'] ?? '';
                  final toUserId = data['toUserId'] ?? '';
                  final isOutgoing = data['isOutgoing'] ?? false;
                  final projectLinkType = data['projectLinkType'] ?? '';
                  final projectLink = data['projectLink'] ?? '';
                  
                  final startDate = data['startProjectDate'] is Timestamp ? 
                              (data['startProjectDate'] as Timestamp).toDate() :
                              data['startProjectDate'] as DateTime? ?? 
                              (data['startDate'] is Timestamp ? 
                                (data['startDate'] as Timestamp).toDate() :
                                (data['startDate'] != null ? DateTime.tryParse(data['startDate'].toString()) : null));
                  final endDate = data['endProjectDate'] is Timestamp ?
                            (data['endProjectDate'] as Timestamp).toDate() :
                            data['endProjectDate'] as DateTime? ??
                            (data['endDate'] is Timestamp ?
                              (data['endDate'] as Timestamp).toDate() :
                              (data['endDate'] != null ? DateTime.tryParse(data['endDate'].toString()) : null));
                  final timestamp = data['timestamp'] as Timestamp? ?? data['createdAt'] as Timestamp?;

                  final senderProjectLink = data['senderProjectLink'] ?? '';
                  final senderProjectLinkType = data['senderProjectLinkType'] ?? '';
                  final receiverProjectLink = data['receiverProjectLink'] ?? '';
                  final receiverProjectLinkType = data['receiverProjectLinkType'] ?? '';

                  final senderReview = data['senderReview'];
                  final receiverReview = data['receiverReview'];

                  // Determine if current user is sender or receiver
                  final isCurrentUserSender = widget.currentUserId == fromUserId;

                  // Debug print for each request
                  print('Request $index: id=$requestId, status=$status, isOutgoing=$isOutgoing, isCurrentUserSender=$isCurrentUserSender');

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF3A3A3A),
                          Color(0xFF2C2C2C),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: isOutgoing 
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: isOutgoing 
                          ? Colors.blue.withOpacity(0.3)
                          : Colors.orange.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with request type and status
                          Row(
                            children: [
                              // Request type indicator with gradient
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isOutgoing 
                                      ? [Colors.blue.shade400, Colors.blue.shade600]
                                      : [Colors.orange.shade400, Colors.orange.shade600],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isOutgoing 
                                        ? Colors.blue.withOpacity(0.3)
                                        : Colors.orange.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isOutgoing ? Icons.arrow_upward : Icons.arrow_downward,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isOutgoing ? 'Outgoing' : 'Incoming',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              // Status badge with animation
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: _getStatusColor(status).withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      status[0].toUpperCase() + status.substring(1),
                                      style: TextStyle(
                                        color: _getStatusColor(status),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // User info
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(isOutgoing ? toUserId : fromUserId)
                                .get(),
                            builder: (context, userSnapshot) {
                              String userName = 'Loading...';
                              String userImage = '';
                              String userCountry = '';

                              if (userSnapshot.hasData && userSnapshot.data != null) {
                                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                                
                                // Enhanced user data fetching with more field checks
                                userName = userData?['name'] ?? 
                                           userData?['fullName'] ?? 
                                           userData?['userName'] ?? 
                                           userData?['displayName'] ?? 
                                           userData?['email']?.toString().split('@')[0] ?? 
                                           userData?['uid']?.toString().substring(0, 8) ?? 
                                           'Unknown User';
                                           
                                userImage = userData?['avatarUrl'] ?? 
                                           userData?['profileImage'] ?? 
                                           userData?['profileImageUrl'] ?? 
                                           userData?['photo'] ?? 
                                           userData?['photoURL'] ?? 
                                           userData?['imageUrl'] ?? '';
                                           
                                userCountry = userData?['country'] ?? 
                                                     userData?['Country'] ?? 
                                                     userData?['location'] ?? 
                                                     userData?['Location'] ?? '';
                              } else if (userSnapshot.hasError) {
                                userName = 'Error loading user';
                                print('Error loading user: ${userSnapshot.error}');
                              } else {
                                userName = 'User not found';
                                print('User not found: ${isOutgoing ? widget.currentUserId : fromUserId}');
                              }
                              
                              // Beautiful modern user info card
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.08),
                                      Colors.white.withOpacity(0.02),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Enhanced avatar with glow effect
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: isOutgoing 
                                              ? Colors.blue.withOpacity(0.3)
                                              : Colors.orange.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 24,
                                        backgroundColor: Colors.white24,
                                        backgroundImage: userImage.isNotEmpty ? NetworkImage(userImage) : null,
                                        child: userImage.isEmpty 
                                          ? const Icon(
                                              Icons.person,
                                              color: Colors.white70,
                                              size: 28,
                                            )
                                          : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // User info with better typography
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                isOutgoing ? Icons.arrow_forward : Icons.arrow_back,
                                                size: 16,
                                                color: isOutgoing ? Colors.blue.shade300 : Colors.orange.shade300,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  userName,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                    letterSpacing: 0.2,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          // User ID with better styling
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.05),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'ID: ${isOutgoing ? widget.currentUserId.substring(0, 8) : fromUserId.substring(0, 8)}...',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.6),
                                                fontSize: 11,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              if (userCountry.isNotEmpty) ...[
                                                Text(
                                                  _getCountryFlag(userCountry),
                                                  style: const TextStyle(fontSize: 18),
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              if (timestamp != null)
                                                Expanded(
                                                  child: Text(
                                                    _formatDateTime(timestamp.toDate()),
                                                    style: TextStyle(
                                                      color: Colors.white.withOpacity(0.5),
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          
                          // Project details
                          const SizedBox(height: 20),
                          Text(
                            'Project: $title',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Type: $type',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Description: $description',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          if (note.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Note: $note',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Date range display
                          if (startDate != null || endDate != null) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Start: ${_formatDate(startDate)}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (endDate != null) ...[
                                        Text(
                                          'End: ${_formatDate(endDate)}',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.7),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Action buttons for pending requests - only receiver can accept/reject
                          if (status == 'pending' && !isCurrentUserSender) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2C2C2C), // Light black
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => _acceptRequest(requestId),
                                    child: const Text('Accept Request', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2C2C2C), // Light black
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => _rejectRequest(requestId),
                                    child: const Text('Reject Request', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Show waiting message for sender
                          if (status == 'pending' && isCurrentUserSender) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.hourglass_empty,
                                    color: Colors.orange.shade300,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Waiting for the other user to respond to your request...',
                                      style: TextStyle(
                                        color: Colors.orange.shade300,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Project link submission for accepted requests
                          if (status == 'accepted') ...[
                            // Show project link submission form for current user if they haven't submitted
                            if ((isCurrentUserSender && senderProjectLink.isEmpty) || (!isCurrentUserSender && receiverProjectLink.isEmpty))
                              _ProjectLinkSubmitWidget(
                                requestId: requestId,
                                currentUserId: widget.currentUserId,
                                isSender: isCurrentUserSender,
                              ),
                            
                            // Only show project links when BOTH users have submitted their links
                            if (senderProjectLink.isNotEmpty && receiverProjectLink.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              
                              // Sender's project link
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.withOpacity(0.1),
                                      Colors.blue.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.link,
                                          color: Colors.blue.shade300,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isCurrentUserSender ? 'Your submitted project link:' : "Other user's submitted project link:",
                                          style: TextStyle(
                                            color: Colors.blue.shade300,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Type: $senderProjectLinkType',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.7),
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          GestureDetector(
                                            onTap: () async {
                                              String urlString = senderProjectLink.trim().replaceAll(' ', '');
                                              if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
                                                urlString = 'https://$urlString';
                                              }
                                              final Uri url = Uri.parse(urlString);

                                              print('Trying to launch: $urlString');
                                              try {
                                                final launched = await launchUrl(
                                                  url,
                                                  mode: LaunchMode.externalApplication,
                                                );
                                                if (!launched) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Could not launch link: $urlString')),
                                                  );
                                                }
                                              } catch (e) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Error launching link: $urlString')),
                                                );
                                              }
                                            },
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    senderProjectLink,
                                                    style: const TextStyle(
                                                      color: Colors.blueAccent,
                                                      decoration: TextDecoration.underline,
                                                      fontSize: 14,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                GestureDetector(
                                                  onTap: () async {
                                                    String urlString = senderProjectLink.trim().replaceAll(' ', '');
                                                    if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
                                                      urlString = 'https://$urlString';
                                                    }
                                                    try {
                                                      await Clipboard.setData(ClipboardData(text: urlString));
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Link copied to clipboard!')),
                                                      );
                                                    } catch (e) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text('Failed to copy link: ${e.toString()}')),
                                                      );
                                                    }
                                                  },
                                                  child: Icon(
                                                    Icons.copy,
                                                    color: Colors.blue.shade300,
                                                    size: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Receiver's project link
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.withOpacity(0.1),
                                      Colors.green.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.link,
                                          color: Colors.green.shade300,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          !isCurrentUserSender ? 'Your submitted project link:' : "Other user's submitted project link:",
                                          style: TextStyle(
                                            color: Colors.green.shade300,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Type: $receiverProjectLinkType',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.7),
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          GestureDetector(
                                            onTap: () async {
                                              String urlString = receiverProjectLink.trim().replaceAll(' ', '');
                                              if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
                                                urlString = 'https://$urlString';
                                              }
                                              final Uri url = Uri.parse(urlString);

                                              print('Trying to launch: $urlString');
                                              try {
                                                final launched = await launchUrl(
                                                  url,
                                                  mode: LaunchMode.externalApplication,
                                                );
                                                if (!launched) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Could not launch link: $urlString')),
                                                  );
                                                }
                                              } catch (e) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Error launching link: $urlString')),
                                                );
                                              }
                                            },
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    receiverProjectLink,
                                                    style: const TextStyle(
                                                      color: Colors.greenAccent,
                                                      decoration: TextDecoration.underline,
                                                      fontSize: 14,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                GestureDetector(
                                                  onTap: () async {
                                                    String urlString = receiverProjectLink.trim().replaceAll(' ', '');
                                                    if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
                                                      urlString = 'https://$urlString';
                                                    }
                                                    try {
                                                      await Clipboard.setData(ClipboardData(text: urlString));
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Link copied to clipboard!')),
                                                      );
                                                    } catch (e) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text('Failed to copy link: ${e.toString()}')),
                                                      );
                                                    }
                                                  },
                                                  child: Icon(
                                                    Icons.copy,
                                                    color: Colors.green.shade300,
                                                    size: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Review submission after both links are submitted
                              const SizedBox(height: 16),
                              if ((isCurrentUserSender && (senderReview == null)) || (!isCurrentUserSender && (receiverReview == null)))
                                _ReviewSubmitWidget(
                                  requestId: requestId,
                                  currentUserId: widget.currentUserId,
                                  isSender: isCurrentUserSender,
                                ),
                            ],

                            // Show waiting message if links are not yet submitted by both users
                            if (senderProjectLink.isEmpty || receiverProjectLink.isEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.hourglass_empty,
                                      color: Colors.orange.shade300,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Waiting for both users to submit their project links...',
                                        style: TextStyle(
                                          color: Colors.orange.shade300,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],

                          // Status display for other statuses
                          if (status != 'pending') ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status: ${status[0].toUpperCase() + status.substring(1)}',
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (status == 'accepted') ...[
                                    Text(
                                      'Request accepted! Submit your project link.',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                  if (status == 'rejected') ...[
                                    Text(
                                      'This request has been rejected.',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                  if (status == 'completed') ...[
                                    Text(
                                      'Exchange completed! Both users have submitted their reviews.',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                    
                                    // Show project links in completed status
                                    if (senderProjectLink.isNotEmpty && receiverProjectLink.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      
                                      // Sender's project link
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.blue.withOpacity(0.1),
                                              Colors.blue.withOpacity(0.05),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.blue.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.link,
                                                  color: Colors.blue.shade300,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  isCurrentUserSender ? 'Your submitted project link:' : "Other user's submitted project link:",
                                                  style: TextStyle(
                                                    color: Colors.blue.shade300,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.05),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.white.withOpacity(0.1),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Type: $senderProjectLinkType',
                                                    style: TextStyle(
                                                      color: Colors.white.withOpacity(0.7),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  GestureDetector(
                                                    onTap: () async {
                                                      String urlString = senderProjectLink.trim().replaceAll(' ', '');
                                                      if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
                                                        urlString = 'https://$urlString';
                                                      }
                                                      final Uri url = Uri.parse(urlString);

                                                      print('Trying to launch: $urlString');
                                                      try {
                                                        final launched = await launchUrl(
                                                          url,
                                                          mode: LaunchMode.externalApplication,
                                                        );
                                                        if (!launched) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text('Could not launch link: $urlString')),
                                                          );
                                                        }
                                                      } catch (e) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text('Error launching link: $urlString')),
                                                        );
                                                      }
                                                    },
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            senderProjectLink,
                                                            style: const TextStyle(
                                                              color: Colors.blueAccent,
                                                              decoration: TextDecoration.underline,
                                                              fontSize: 14,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        GestureDetector(
                                                          onTap: () async {
                                                            String urlString = senderProjectLink.trim().replaceAll(' ', '');
                                                            if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
                                                              urlString = 'https://$urlString';
                                                            }
                                                            try {
                                                              await Clipboard.setData(ClipboardData(text: urlString));
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                const SnackBar(content: Text('Link copied to clipboard!')),
                                                              );
                                                            } catch (e) {
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(content: Text('Failed to copy link: ${e.toString()}')),
                                                              );
                                                            }
                                                          },
                                                          child: Icon(
                                                            Icons.copy,
                                                            color: Colors.blue.shade300,
                                                            size: 16,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 16),

                                      // Receiver's project link
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.green.withOpacity(0.1),
                                              Colors.green.withOpacity(0.05),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.green.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.link,
                                                  color: Colors.green.shade300,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  !isCurrentUserSender ? 'Your submitted project link:' : "Other user's submitted project link:",
                                                  style: TextStyle(
                                                    color: Colors.green.shade300,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.05),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.white.withOpacity(0.1),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Type: $receiverProjectLinkType',
                                                    style: TextStyle(
                                                      color: Colors.white.withOpacity(0.7),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  GestureDetector(
                                                    onTap: () async {
                                                      String urlString = receiverProjectLink.trim().replaceAll(' ', '');
                                                      if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
                                                        urlString = 'https://$urlString';
                                                      }
                                                      final Uri url = Uri.parse(urlString);

                                                      print('Trying to launch: $urlString');
                                                      try {
                                                        final launched = await launchUrl(
                                                          url,
                                                          mode: LaunchMode.externalApplication,
                                                        );
                                                        if (!launched) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text('Could not launch link: $urlString')),
                                                          );
                                                        }
                                                      } catch (e) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text('Error launching link: $urlString')),
                                                        );
                                                      }
                                                    },
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            receiverProjectLink,
                                                            style: const TextStyle(
                                                              color: Colors.greenAccent,
                                                              decoration: TextDecoration.underline,
                                                              fontSize: 14,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        GestureDetector(
                                                          onTap: () async {
                                                            String urlString = receiverProjectLink.trim().replaceAll(' ', '');
                                                            if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
                                                              urlString = 'https://$urlString';
                                                            }
                                                            try {
                                                              await Clipboard.setData(ClipboardData(text: urlString));
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                const SnackBar(content: Text('Link copied to clipboard!')),
                                                              );
                                                            } catch (e) {
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(content: Text('Failed to copy link: ${e.toString()}')),
                                                              );
                                                            }
                                                          },
                                                          child: Icon(
                                                            Icons.copy,
                                                            color: Colors.green.shade300,
                                                            size: 16,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                  
                                  // Show ratings in completed status
                                  if (senderReview != null || receiverReview != null) ...[
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.amber.withOpacity(0.1),
                                            Colors.amber.withOpacity(0.05),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.amber.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.star,
                                                color: Colors.amber.shade300,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Exchange Reviews',
                                                style: TextStyle(
                                                  color: Colors.amber.shade300,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          
                                          // Sender's review
                                          if (senderReview != null) ...[
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.05),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.white.withOpacity(0.1),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        isCurrentUserSender ? 'Your Review:' : "Other User's Review:",
                                                        style: TextStyle(
                                                          color: Colors.white.withOpacity(0.9),
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      ...List.generate(5, (index) => Icon(
                                                        index < (senderReview['rating'] ?? 0) 
                                                          ? Icons.star 
                                                          : Icons.star_border,
                                                        color: Colors.amber,
                                                        size: 16,
                                                      )),
                                                    ],
                                                  ),
                                                  if ((senderReview['comment'] ?? '').isNotEmpty) ...[
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      senderReview['comment'],
                                                      style: TextStyle(
                                                        color: Colors.white.withOpacity(0.7),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                          ],
                                          
                                          // Receiver's review
                                          if (receiverReview != null) ...[
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.05),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.white.withOpacity(0.1),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        !isCurrentUserSender ? 'Your Review:' : "Other User's Review:",
                                                        style: TextStyle(
                                                          color: Colors.white.withOpacity(0.9),
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      ...List.generate(5, (index) => Icon(
                                                        index < (receiverReview['rating'] ?? 0) 
                                                          ? Icons.star 
                                                          : Icons.star_border,
                                                        color: Colors.amber,
                                                        size: 16,
                                                      )),
                                                    ],
                                                  ),
                                                  if ((receiverReview['comment'] ?? '').isNotEmpty) ...[
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      receiverReview['comment'],
                                                      style: TextStyle(
                                                        color: Colors.white.withOpacity(0.7),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.greenAccent;
      case 'rejected':
        return Colors.redAccent;
      case 'pending':
        return Colors.orangeAccent;
      default:
        return Colors.white70;
    }
  }
}

class _ProjectLinkSubmitWidget extends StatefulWidget {
  final String requestId;
  final String currentUserId;
  final bool isSender;
  const _ProjectLinkSubmitWidget({super.key, required this.requestId, required this.currentUserId, required this.isSender});

  @override
  State<_ProjectLinkSubmitWidget> createState() => _ProjectLinkSubmitWidgetState();
}

class _ProjectLinkSubmitWidgetState extends State<_ProjectLinkSubmitWidget> {
  String _selectedLinkType = 'Google Drive';
  final TextEditingController _linkController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.upload_file,
                color: Colors.blue.shade300,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Submit Your Project Link',
                style: TextStyle(
                  color: Colors.blue.shade300,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedLinkType,
            dropdownColor: const Color(0xFF232323),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Project Link Type',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
            ),
            items: ['Google Drive', 'Github']
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedLinkType = val;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _linkController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: _selectedLinkType == 'Google Drive' ? 'Google Drive Project Link' : 'Github Project Link',
              hintText: _selectedLinkType == 'Google Drive' ? 'Please drop your Google Drive project link' : 'Please drop your Github project link',
              hintStyle: const TextStyle(color: Colors.white38),
              labelStyle: const TextStyle(color: Colors.white70),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
            ),
          ),
          const SizedBox(height: 16),
          if (_isSubmitting)
            const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C2C), // Light black
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                String link = _linkController.text.trim();
                link = link.replaceAll(' ', ''); // Remove all spaces
                if (!link.startsWith('http://') && !link.startsWith('https://')) {
                  link = 'https://$link';
                }
                if (link.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your project link!')));
                  return;
                }
                setState(() => _isSubmitting = true);
                try {
                  // Update main exchange document
                  await FirebaseFirestore.instance
                      .collection('exchanges')
                      .doc(widget.requestId)
                      .update(widget.isSender
                        ? {
                            'senderProjectLinkType': _selectedLinkType,
                            'senderProjectLink': link,
                          }
                        : {
                            'receiverProjectLinkType': _selectedLinkType,
                            'receiverProjectLink': link,
                          });

                  setState(() => _isSubmitting = false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project link submitted successfully!')));
                } catch (e) {
                  setState(() => _isSubmitting = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to submit project link: ${e.toString()}')),
                  );
                }
              },
              child: const Text('Submit Project Link', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}

class _ReviewSubmitWidget extends StatefulWidget {
  final String requestId;
  final String currentUserId;
  final bool isSender;
  const _ReviewSubmitWidget({super.key, required this.requestId, required this.currentUserId, required this.isSender});

  @override
  State<_ReviewSubmitWidget> createState() => _ReviewSubmitWidgetState();
}

class _ReviewSubmitWidgetState extends State<_ReviewSubmitWidget> {
  double _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber.shade300,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Rate Your Exchange Partner',
                style: TextStyle(
                  color: Colors.amber.shade300,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RatingBar.builder(
            initialRating: 5,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: false,
            itemCount: 5,
            itemPadding: const EdgeInsets.symmetric(horizontal: 2.0),
            itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: (rating) {
              setState(() {
                _rating = rating;
              });
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _commentController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Comment (optional)',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          if (_isSubmitting)
            const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C2C), // Light black
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                setState(() => _isSubmitting = true);
                final reviewData = {
                  'rating': _rating,
                  'comment': _commentController.text.trim(),
                  'timestamp': DateTime.now().toIso8601String(),
                };
                try {
                  // Update main exchange document
                  await FirebaseFirestore.instance
                      .collection('exchanges')
                      .doc(widget.requestId)
                      .update(widget.isSender
                        ? {'senderReview': reviewData}
                        : {'receiverReview': reviewData});

                  // Check if both reviews submitted, then mark as completed
                  final exchangeDoc = await FirebaseFirestore.instance
                      .collection('exchanges')
                      .doc(widget.requestId)
                      .get();
                  final exchangeData = exchangeDoc.data();
                  final senderReview = exchangeData?['senderReview'];
                  final receiverReview = exchangeData?['receiverReview'];
                  
                  if (senderReview != null && receiverReview != null) {
                    // Both reviews submitted, mark as completed
                    await FirebaseFirestore.instance
                        .collection('exchanges')
                        .doc(widget.requestId)
                        .update({'status': 'completed'});
                  }

                  setState(() => _isSubmitting = false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted!')));
                } catch (e) {
                  setState(() => _isSubmitting = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to submit review: ${e.toString()}')),
                  );
                }
              },
              child: const Text('Submit Review', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
