import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  // Default categories used across the app
  static const Map<String, List<String>> kDefaultCategories = {
    'Mobile Apps Development': ['iOS Development', 'Android Development', 'Cross-Platform', 'Mobile UI/UX'],
    'AI Services': ['Machine Learning', 'Deep Learning', 'Data Science', 'Computer Vision'],
    'Web Development': ['Frontend Development', 'Backend Development', 'Full Stack Development', 'Database Design'],
    'Web Designing': ['UI/UX Design', 'Responsive Design', 'Wireframing', 'Prototyping'],
    'Graphics Designing': ['Logo Design', 'Illustration', 'Print Design', 'Photo Editing'],
    'Digital Marketing': ['Social Media Marketing', 'SEO Optimization', 'Content Marketing', 'Email Marketing'],
    'Management': ['Project Management', 'Team Leadership', 'Product Management', 'Business Analysis'],
    'Business': ['Business Strategy', 'Entrepreneurship', 'Finance & Accounting', 'Marketing Strategy'],
  };
  // Loading / saving
  final bool loading;
  final bool saving;
  final String? message;
  final String? error;

  // Identity
  final String? userId;

  // User immutable fields to display (read-only)
  final String fullName;
  final String jobTitle;
  final String country;
  final String city;

  // User other display fields (read-only in this screen)
  final String email;
  final String username;
  // Security PIN (editable in settings)
  final String userPin;

  // Editable fields
  final String website;
  final String bio;
  final String newPassword; // single new password field

  // Images
  final String profileImageUrl;
  final String coverImageUrl;
  final String? localProfileImagePath; // picked but not yet uploaded
  final String? localCoverImagePath;   // picked but not yet uploaded

  // Categories
  final Map<String, List<String>> categories;
  final String? category;
  final String? subcategory;

  // Skills
  final List<String> skillsOptions;
  final List<String> skills;

  SettingsState({
    this.loading = true,
    this.saving = false,
    this.message,
    this.error,
    this.userId,
    this.fullName = '',
    this.jobTitle = '',
    this.country = '',
    this.city = '',
    this.email = '',
    this.username = '',
    this.userPin = '',
    this.website = '',
    this.bio = '',
    this.newPassword = '',
    this.profileImageUrl = '',
    this.coverImageUrl = '',
    this.localProfileImagePath,
    this.localCoverImagePath,
    Map<String, List<String>>? categories,
    this.category,
    this.subcategory,
    List<String>? skillsOptions,
    List<String>? skills,
  })  : categories = categories ?? kDefaultCategories,
        skillsOptions = skillsOptions ?? const ['Flutter', 'React Native', 'SEO', 'Web Design', 'Graphics', 'UI/UX', 'Other'],
        skills = skills ?? const [];
  
  factory SettingsState.initial() {
    return SettingsState();
  }

  SettingsState copyWith({
    bool? loading,
    bool? saving,
    String? message,
    String? error,
    String? userId,
    String? fullName,
    String? jobTitle,
    String? country,
    String? city,
    String? email,
    String? username,
    String? userPin,
    String? website,
    String? bio,
    String? newPassword,
    String? profileImageUrl,
    String? coverImageUrl,
    String? localProfileImagePath,
    String? localCoverImagePath,
    Map<String, List<String>>? categories,
    String? category,
    String? subcategory,
    List<String>? skillsOptions,
    List<String>? skills,
  }) {
    return SettingsState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      message: message,
      error: error,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      jobTitle: jobTitle ?? this.jobTitle,
      country: country ?? this.country,
      city: city ?? this.city,
      email: email ?? this.email,
      username: username ?? this.username,
      userPin: userPin ?? this.userPin,
      website: website ?? this.website,
      bio: bio ?? this.bio,
      newPassword: newPassword ?? this.newPassword,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      localProfileImagePath: localProfileImagePath ?? this.localProfileImagePath,
      localCoverImagePath: localCoverImagePath ?? this.localCoverImagePath,
      categories: categories ?? this.categories,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      skillsOptions: skillsOptions ?? this.skillsOptions,
      skills: skills ?? this.skills,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        saving,
        message,
        error,
        userId,
        fullName,
        jobTitle,
        country,
        city,
        email,
        username,
        userPin,
        website,
        bio,
        newPassword,
        profileImageUrl,
        coverImageUrl,
        localProfileImagePath,
        localCoverImagePath,
        categories,
        category,
        subcategory,
        skillsOptions,
        skills,
      ];
}
