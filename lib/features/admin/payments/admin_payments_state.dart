import 'package:equatable/equatable.dart';

class AdminPaymentItem {
  final String id;
  final String userId;
  final String tier; // monthly, quarterly, semiannual, yearly
  final double amountUSD;
  final String bankReference;
  final DateTime createdAt;
  final String status; // pending, approved, rejected

  AdminPaymentItem({
    required this.id,
    required this.userId,
    required this.tier,
    required this.amountUSD,
    required this.bankReference,
    required this.createdAt,
    required this.status,
  });
}

class AdminUserItem {
  final String id; // userId
  final String name;
  final String email;
  final String username;
  final String plan; // 'Free' or 'Pro'
  final DateTime? proActiveUntil;
  final String userPin; // unique user PIN
  final String? jobTitle;
  final String? signupCategory;
  final String? country;
  final String? city;
  final String? profileImageUrl;
  final DateTime? proSince;
  final DateTime? createdAt;

  const AdminUserItem({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.plan,
    this.proActiveUntil,
    this.userPin = '',
    this.jobTitle,
    this.signupCategory,
    this.country,
    this.city,
    this.profileImageUrl,
    this.proSince,
    this.createdAt,
  });
}

class AdminPaymentsState extends Equatable {
  final bool loading;
  final bool processing;
  final String? error;
  final String? message;
  final List<AdminPaymentItem> pending;
  final bool usersLoading;
  final List<AdminUserItem> users;
  final String searchQuery;
  final List<AdminUserItem> filteredUsers;
  final AdminUserItem? selectedUser;
  
  // Analytics data
  final int totalUsers;
  final int freeUsers;
  final int proUsers;
  final Map<String, int> countryStats;
  final Map<String, int> cityStats;

  const AdminPaymentsState({
    this.loading = true,
    this.processing = false,
    this.error,
    this.message,
    this.pending = const [],
    this.usersLoading = true,
    this.users = const [],
    this.searchQuery = '',
    this.filteredUsers = const [],
    this.selectedUser,
    this.totalUsers = 0,
    this.freeUsers = 0,
    this.proUsers = 0,
    this.countryStats = const {},
    this.cityStats = const {},
  });

  AdminPaymentsState copyWith({
    bool? loading,
    bool? processing,
    String? error,
    String? message,
    List<AdminPaymentItem>? pending,
    bool? usersLoading,
    List<AdminUserItem>? users,
    String? searchQuery,
    List<AdminUserItem>? filteredUsers,
    AdminUserItem? selectedUser,
    int? totalUsers,
    int? freeUsers,
    int? proUsers,
    Map<String, int>? countryStats,
    Map<String, int>? cityStats,
  }) {
    return AdminPaymentsState(
      loading: loading ?? this.loading,
      processing: processing ?? this.processing,
      error: error,
      message: message,
      pending: pending ?? this.pending,
      usersLoading: usersLoading ?? this.usersLoading,
      users: users ?? this.users,
      searchQuery: searchQuery ?? this.searchQuery,
      filteredUsers: filteredUsers ?? this.filteredUsers,
      selectedUser: selectedUser ?? this.selectedUser,
      totalUsers: totalUsers ?? this.totalUsers,
      freeUsers: freeUsers ?? this.freeUsers,
      proUsers: proUsers ?? this.proUsers,
      countryStats: countryStats ?? this.countryStats,
      cityStats: cityStats ?? this.cityStats,
    );
  }

  @override
  List<Object?> get props => [loading, processing, error, message, pending, usersLoading, users, searchQuery, filteredUsers, selectedUser, totalUsers, freeUsers, proUsers, countryStats, cityStats];
}
