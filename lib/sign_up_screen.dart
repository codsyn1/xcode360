import 'package:flutter/material.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'subscription_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/auth/signup/presentation/bloc/signup_cubit.dart';
import 'features/auth/signup/presentation/bloc/signup_state.dart';
import 'features/auth/signup/data/signup_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SignUpScreen extends StatefulWidget {
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController(); // Job Title controller
  final TextEditingController _customSkillController = TextEditingController();
  String? _selectedCountry;
  String? _experienceLevel;
  String _userType = 'Seller';
  bool _agreedToTerms = false;
  bool _isLoading = false;
  String? _profileImagePath;
  String? _coverImagePath;
  List<String> _selectedSkills = [];
  List<String> _customSkills = [];
  bool _showSummaryError = false;
  bool _submitted = false;

  // Add category and subcategory state
  String? _selectedCategory;
  String? _selectedSubcategory;

  // Dashboard categories and subcategories
  final Map<String, List<String>> _categories = {
    'Mobile Apps Development': [
      'iOS Development',
      'Android Development',
      'Cross-Platform',
      'Mobile UI/UX',
    ],
    'AI Services': [
      'Machine Learning',
      'Deep Learning',
      'Data Science',
      'Computer Vision',
    ],
    'Web Development': [
      'Frontend Development',
      'Backend Development',
      'Full Stack Development',
      'Database Design',
    ],
    'Web Designing': [
      'UI/UX Design',
      'Responsive Design',
      'Wireframing',
      'Prototyping',
    ],
    'Graphics Designing': [
      'Logo Design',
      'Illustration',
      'Print Design',
      'Photo Editing',
    ],
    'Digital Marketing': [
      'Social Media Marketing',
      'SEO Optimization',
      'Content Marketing',
      'Email Marketing',
    ],
    'Management': [
      'Project Management',
      'Team Leadership',
      'Product Management',
      'Business Analysis',
    ],
    'Business': [
      'Business Strategy',
      'Entrepreneurship',
      'Finance & Accounting',
      'Marketing Strategy',
    ],
  };

  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  final List<String> _skills = [
    'Flutter', 'React Native', 'SEO', 'Web Design', 'Graphics', 'UI/UX', 'Other',
  ];
  final List<String> _countries = [
    'Afghanistan', 'Albania', 'Algeria', 'Andorra', 'Angola', 'Antigua and Barbuda', 'Argentina', 'Armenia', 'Australia', 'Austria', 'Azerbaijan',
    'Bahamas', 'Bahrain', 'Bangladesh', 'Barbados', 'Belarus', 'Belgium', 'Belize', 'Benin', 'Bhutan', 'Bolivia', 'Bosnia and Herzegovina', 'Botswana', 'Brazil', 'Brunei', 'Bulgaria', 'Burkina Faso', 'Burundi',
    'Cabo Verde', 'Cambodia', 'Cameroon', 'Canada', 'Central African Republic', 'Chad', 'Chile', 'China', 'Colombia', 'Comoros', 'Congo (Congo-Brazzaville)', 'Costa Rica', 'Croatia', 'Cuba', 'Cyprus', 'Czechia (Czech Republic)',
    'Democratic Republic of the Congo', 'Denmark', 'Djibouti', 'Dominica', 'Dominican Republic',
    'Ecuador', 'Egypt', 'El Salvador', 'Equatorial Guinea', 'Eritrea', 'Estonia', 'Eswatini (fmr. "Swaziland")', 'Ethiopia',
    'Fiji', 'Finland', 'France',
    'Gabon', 'Gambia', 'Georgia', 'Germany', 'Ghana', 'Greece', 'Grenada', 'Guatemala', 'Guinea', 'Guinea-Bissau', 'Guyana',
    'Haiti', 'Honduras', 'Hungary',
    'Iceland', 'India', 'Indonesia', 'Iran', 'Iraq', 'Ireland', /*'Israel',*/ 'Italy',
    'Jamaica', 'Japan', 'Jordan',
    'Kazakhstan', 'Kenya', 'Kiribati', 'Kuwait', 'Kyrgyzstan',
    'Laos', 'Latvia', 'Lebanon', 'Lesotho', 'Liberia', 'Libya', 'Liechtenstein', 'Lithuania', 'Luxembourg',
    'Madagascar', 'Malawi', 'Malaysia', 'Maldives', 'Mali', 'Malta', 'Marshall Islands', 'Mauritania', 'Mauritius', 'Mexico', 'Micronesia', 'Moldova', 'Monaco', 'Mongolia', 'Montenegro', 'Morocco', 'Mozambique', 'Myanmar (formerly Burma)',
    'Namibia', 'Nauru', 'Nepal', 'Netherlands', 'New Zealand', 'Nicaragua', 'Niger', 'Nigeria', 'North Korea', 'North Macedonia', 'Norway',
    'Oman',
    'Pakistan', 'Palau', 'Palestine State', 'Panama', 'Papua New Guinea', 'Paraguay', 'Peru', 'Philippines', 'Poland', 'Portugal',
    'Qatar',
    'Romania', 'Russia', 'Rwanda',
    'Saint Kitts and Nevis', 'Saint Lucia', 'Saint Vincent and the Grenadines', 'Samoa', 'San Marino', 'Sao Tome and Principe', 'Saudi Arabia', 'Senegal', 'Serbia', 'Seychelles', 'Sierra Leone', 'Singapore', 'Slovakia', 'Slovenia', 'Solomon Islands', 'Somalia', 'South Africa', 'South Korea', 'South Sudan', 'Spain', 'Sri Lanka', 'Sudan', 'Suriname', 'Sweden', 'Switzerland', 'Syria',
    'Tajikistan', 'Tanzania', 'Thailand', 'Timor-Leste', 'Togo', 'Tonga', 'Trinidad and Tobago', 'Tunisia', 'Turkey', 'Turkmenistan', 'Tuvalu',
    'Uganda', 'Ukraine', 'United Arab Emirates', 'United Kingdom', 'United States of America', 'Uruguay', 'Uzbekistan',
    'Vanuatu', 'Vatican City', 'Venezuela', 'Vietnam',
    'Yemen',
    'Zambia', 'Zimbabwe',
  ];
  final List<String> _experienceLevels = [
    'Beginner', 'Intermediate', 'Expert',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    Timer(const Duration(milliseconds: 200), () {
      _animationController.forward();
    });
  }

  Future<void> _openCountryPicker() async {
    String query = '';
    String? selected = _selectedCountry;
    await showDialog(
      context: context,
      builder: (ctx) {
        List<String> filtered = _countries;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            filtered = _countries
                .where((c) => c.toLowerCase().contains(query.toLowerCase()))
                .toList();
            return AlertDialog(
              backgroundColor: const Color(0xFF2C2C2C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Select Country', style: TextStyle(color: Colors.white)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Search country...',
                        hintStyle: TextStyle(color: Colors.white70),
                      ),
                      onChanged: (val) => setStateDialog(() => query = val),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: Scrollbar(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final country = filtered[index];
                            final isSelected = country == selected;
                            return ListTile(
                              dense: true,
                              title: Text(country, style: const TextStyle(color: Colors.white)),
                              trailing: isSelected ? const Icon(Icons.check, color: Colors.amber) : null,
                              onTap: () {
                                setState(() {
                                  _selectedCountry = country;
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Colors.white70)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fullNameController.dispose();
    _jobTitleController.dispose(); // Dispose job title controller
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _customSkillController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profileImagePath = picked.path;
      });
      if (mounted) { context.read<SignupCubit>().setProfilePath(picked.path); }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image selected!')),
      );
    }
  }

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _coverImagePath = picked.path;
      });
      if (mounted) { context.read<SignupCubit>().setCoverPath(picked.path); }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image selected!')),
      );
    }
  }

  

  void _submitForm() async {
    setState(() {
      _showSummaryError = false;
      _submitted = true;
    });
    if (!_formKey.currentState!.validate() || _selectedSkills.isEmpty) {
      setState(() => _showSummaryError = true);
      return;
    }
    // Defer loading state and all network work to BLoC/Repository
    context.read<SignupCubit>().submit(
      fullName: _fullNameController.text.trim(),
      jobTitle: _jobTitleController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      username: _usernameController.text.trim(),
      mobile: _phoneController.text.trim(),
      website: _websiteController.text.trim(),
      skills: _selectedSkills,
      country: _selectedCountry,
      city: _cityController.text.trim(),
      bio: _bioController.text.trim(),
      experienceLevel: _experienceLevel,
      category: _selectedCategory,
      subcategory: _selectedSubcategory,
      profileImagePath: _profileImagePath,
      coverImagePath: _coverImagePath,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1976D2),
        brightness: Brightness.dark,
        background: const Color(0xFF212121),
        surface: const Color(0xFF2C2C2C),
        primary: const Color(0xFF1976D2),
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF232323),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF232323),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: Color(0xFF1976D2), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.w500),
        hintStyle: TextStyle(color: Color(0xFFE0E0E0)),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
        bodyLarge: TextStyle(color: Colors.white),
        labelLarge: TextStyle(color: Colors.white),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF212121),
        foregroundColor: Colors.white,
        elevation: 0.5,
      ),
      useMaterial3: true,
    );
    return Theme(
      data: theme,
      child: BlocProvider(
        create: (_) => SignupCubit(SignupRepository()),
        child: BlocListener<SignupCubit, SignupState>(
          listener: (context, state) async {
            if (state.loading != _isLoading && mounted) { setState(() => _isLoading = state.loading); }
            if (!state.loading && state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign up failed: ' + state.error!)));
            }
            if (!state.loading && state.userId != null && state.error == null) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', true);
              await prefs.setString('userId', state.userId!);
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => SubscriptionScreen(userId: state.userId!)),
                  (route) => false,
                );
              }
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Create Account'),
            ),
            body: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                final cardWidth = isWide ? 500.0 : double.infinity;
                return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? (constraints.maxWidth - cardWidth) / 2 : 0.0,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: cardWidth,
                  ),
                  child: Card(
                    elevation: 8,
                    margin: EdgeInsets.zero,
                    shadowColor: Colors.black.withOpacity(0.18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isWide ? 16 : 0),
                    ),
                    color: const Color(0xFF353535),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (_showSummaryError)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                'Please fill all required fields correctly.',
                                style: TextStyle(color: Colors.red[200], fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          Form(
                            key: _formKey,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Profile Image
                                Center(
                                  child: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 44,
                                        backgroundColor: const Color(0xFF232323),
                                        backgroundImage: _profileImagePath != null
                                            ? Image.file(
                                                File(_profileImagePath!),
                                              ).image
                                            : null,
                                        child: _profileImagePath == null
                                            ? const Icon(Icons.person, size: 44, color: Color(0xFFE0E0E0))
                                            : null,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: InkWell(
                                          onTap: _pickProfileImage,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1976D2),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2),
                                            ),
                                            padding: const EdgeInsets.all(6),
                                            child: const Icon(Icons.edit, size: 18, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Cover Photo
                                GestureDetector(
                                  onTap: _pickCoverImage,
                                  child: Container(
                                    height: 100,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF232323),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white24, width: 1.5),
                                      image: _coverImagePath != null
                                          ? DecorationImage(
                                              image: FileImage(File(_coverImagePath!)),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: _coverImagePath == null
                                        ? Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: const [
                                              Icon(Icons.photo, color: Colors.white54, size: 36),
                                              SizedBox(height: 8),
                                              Text('Tap to select cover photo', style: TextStyle(color: Colors.white54)),
                                            ],
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Full Name
                                TextFormField(
                                  controller: _fullNameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Full Name',
                                    hintText: 'Enter your full name',
                                  ),
                                  validator: (value) => !_submitted ? null : (value == null || value.trim().isEmpty ? 'Full Name is required' : null),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _jobTitleController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Job Title',
                                    hintText: 'e.g. Flutter Developer',
                                  ),
                                  validator: (value) => !_submitted ? null : (value == null || value.trim().isEmpty ? 'Job Title is required' : null),
                                ),
                                const SizedBox(height: 12),
                                // Username
                                TextFormField(
                                  controller: _usernameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Username',
                                    hintText: 'Choose a username',
                                  ),
                                  validator: (value) => !_submitted ? null : (value == null || value.trim().isEmpty ? 'Username is required' : null),
                                ),
                                const SizedBox(height: 12),
                                // Email
                                TextFormField(
                                  controller: _emailController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'yourname@example.com',
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (!_submitted) return null;
                                    if (value == null || value.trim().isEmpty) return 'Email is required';
                                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+');
                                    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                // Password
                                TextFormField(
                                  controller: _passwordController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Password',
                                  ),
                                  obscureText: true,
                                  validator: (value) {
                                    if (!_submitted) return null;
                                    if (value == null || value.isEmpty) return 'Password is required';
                                    if (value.length < 6) return 'Password must be at least 6 characters';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                // Confirm Password
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Confirm Password',
                                  ),
                                  obscureText: true,
                                  validator: (value) {
                                    if (!_submitted) return null;
                                    if (value == null || value.isEmpty) return 'Confirm your password';
                                    if (value != _passwordController.text) return 'Passwords do not match';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                // Mobile Number
                                TextFormField(
                                  controller: _phoneController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Mobile Number',
                                    hintText: '+92 300 1234567',
                                  ),
                                  keyboardType: TextInputType.phone,
                                  validator: (value) => !_submitted ? null : (value == null || value.trim().isEmpty ? 'Mobile Number is required' : null),
                                ),
                                const SizedBox(height: 12),
                                // Portfolio/Website URL (optional)
                                TextFormField(
                                  controller: _websiteController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Portfolio URL',
                                  ),
                                  keyboardType: TextInputType.url,
                                  validator: (value) {
                                    if (!_submitted) return null;
                                    if (value == null || value.trim().isEmpty) return null; // optional field
                                    final url = value.trim();
                                    final urlRegex = RegExp(r'^(https?:\/\/)?([\w-]+\.)+[\w-]+(\/\S*)?$');
                                    if (!urlRegex.hasMatch(url)) return 'Enter a valid URL';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                // Skill Categories (multi-select chips)
                                SkillChipSelector(
                                  skills: _skills,
                                  selectedSkills: _selectedSkills,
                                  onChanged: (skills) => setState(() => _selectedSkills = skills),
                                ),
                                // If 'Other' chosen, show custom skills input
                                if (_selectedSkills.contains('Other')) ...[
                                  const SizedBox(height: 10),
                                  Text('Add custom skills', style: const TextStyle(color: Colors.white70)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _customSkillController,
                                          style: const TextStyle(color: Colors.white),
                                          decoration: const InputDecoration(
                                            hintText: 'Type a skill and press +',
                                          ),
                                          onSubmitted: (_) {
                                            final text = _customSkillController.text.trim();
                                            if (text.isEmpty) return;
                                            if (!_customSkills.contains(text)) {
                                              setState(() => _customSkills.add(text));
                                            }
                                            _customSkillController.clear();
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () {
                                          final text = _customSkillController.text.trim();
                                          if (text.isEmpty) return;
                                          if (!_customSkills.contains(text)) {
                                            setState(() => _customSkills.add(text));
                                          }
                                          _customSkillController.clear();
                                        },
                                        child: const Text('+'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (_customSkills.isNotEmpty)
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: _customSkills.map((s) => Chip(
                                        label: Text(s, style: const TextStyle(color: Colors.white)),
                                        backgroundColor: const Color(0xFF1976D2).withOpacity(0.3),
                                        deleteIcon: const Icon(Icons.close, color: Colors.white70, size: 18),
                                        onDeleted: () => setState(() => _customSkills.remove(s)),
                                      )).toList(),
                                    ),
                                ],
                                if (_submitted) ...[
                                  Builder(builder: (context) {
                                    final effectiveSkills = [
                                      ..._selectedSkills.where((e) => e != 'Other'),
                                      ..._customSkills,
                                    ];
                                    return (effectiveSkills.isEmpty)
                                        ? Padding(
                                            padding: const EdgeInsets.only(left: 8, top: 4),
                                            child: Text('Select at least one skill', style: TextStyle(color: Colors.red[200], fontSize: 12)),
                                          )
                                        : const SizedBox.shrink();
                                  }),
                                ],
                                // Old validation kept for non-submitted
                                if (_submitted == false && _selectedSkills.isEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8, top: 4),
                                    child: Text('Select at least one skill', style: TextStyle(color: Colors.red[200], fontSize: 12)),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                // Select Category
                                DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  dropdownColor: const Color(0xFF232323),
                                  items: _categories.keys
                                      .map((cat) => DropdownMenuItem(
                                            value: cat,
                                            child: Text(cat, style: const TextStyle(color: Colors.white)),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedCategory = val;
                                      _selectedSubcategory = null;
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Select Category',
                                  ),
                                  validator: (value) => !_submitted ? null : (value == null || value.isEmpty ? 'Category is required' : null),
                                ),
                                const SizedBox(height: 12),
                                // Select Subcategory
                                if (_selectedCategory != null)
                                  DropdownButtonFormField<String>(
                                    value: _selectedSubcategory,
                                    dropdownColor: const Color(0xFF232323),
                                    items: (_categories[_selectedCategory] ?? [])
                                        .map((sub) => DropdownMenuItem(
                                              value: sub,
                                              child: Text(sub, style: const TextStyle(color: Colors.white)),
                                            ))
                                        .toList(),
                                    onChanged: (val) => setState(() => _selectedSubcategory = val),
                                    decoration: const InputDecoration(
                                      labelText: 'Select Subcategory',
                                    ),
                                    validator: (value) => !_submitted ? null : (value == null || value.isEmpty ? 'Subcategory is required' : null),
                                  ),
                                if (_selectedCategory != null) const SizedBox(height: 12),
                                // Country (searchable picker)
                                GestureDetector(
                                  onTap: _openCountryPicker,
                                  child: AbsorbPointer(
                                    child: TextFormField(
                                      readOnly: true,
                                      controller: TextEditingController(text: _selectedCountry ?? ''),
                                      style: const TextStyle(color: Colors.white),
                                      decoration: const InputDecoration(
                                        labelText: 'Country',
                                        hintText: 'Select your country',
                                        suffixIcon: Icon(Icons.search, color: Colors.white70),
                                      ),
                                      validator: (value) => !_submitted ? null : ((_selectedCountry == null || _selectedCountry!.isEmpty) ? 'Country is required' : null),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // City/Region
                                TextFormField(
                                  controller: _cityController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'City / Region',
                                  ),
                                  validator: (value) => !_submitted ? null : (value == null || value.trim().isEmpty ? 'City/Region is required' : null),
                                ),
                                const SizedBox(height: 12),
                                // Short Bio
                                TextFormField(
                                  controller: _bioController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Short Bio',
                                  ),
                                  maxLines: 3,
                                  maxLength: 200,
                                  validator: (value) => !_submitted ? null : (value == null || value.trim().isEmpty ? 'Short Bio is required' : null),
                                ),
                                const SizedBox(height: 12),
                                // Experience Level (dropdown)
                                DropdownButtonFormField<String>(
                                  value: _experienceLevel,
                                  dropdownColor: const Color(0xFF232323),
                                  items: _experienceLevels
                                      .map((level) => DropdownMenuItem(
                                            value: level,
                                            child: Text(level, style: const TextStyle(color: Colors.white)),
                                          ))
                                      .toList(),
                                  onChanged: (val) => setState(() => _experienceLevel = val),
                                  decoration: const InputDecoration(
                                    labelText: 'Experience Level',
                                  ),
                                  validator: (value) => !_submitted ? null : (value == null || value.isEmpty ? 'Experience Level is required' : null),
                                ),
                                const SizedBox(height: 20),
                                // Sign Up Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1976D2),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: _isLoading
                                        ? null
                                        : () async {
                                            setState(() {
                                              _showSummaryError = false;
                                              _submitted = true;
                                            });
                                            final effectiveSkills = [
                                              ..._selectedSkills.where((e) => e != 'Other'),
                                              ..._customSkills,
                                            ];
                                            if (!_formKey.currentState!.validate() || effectiveSkills.isEmpty) {
                                              setState(() => _showSummaryError = true);
                                              return;
                                            }
                                            // Submit via BLoC
                                            context.read<SignupCubit>().submit(
                                              fullName: _fullNameController.text.trim(),
                                              jobTitle: _jobTitleController.text.trim(),
                                              email: _emailController.text.trim(),
                                              password: _passwordController.text,
                                              username: _usernameController.text.trim(),
                                              mobile: _phoneController.text.trim(),
                                              website: _websiteController.text.trim(), // optional
                                              skills: effectiveSkills,
                                              country: _selectedCountry,
                                              city: _cityController.text.trim(),
                                              bio: _bioController.text.trim(),
                                              experienceLevel: _experienceLevel,
                                              category: _selectedCategory,
                                              subcategory: _selectedSubcategory,
                                              profileImagePath: _profileImagePath,
                                              coverImagePath: _coverImagePath,
                                            );
                                          },
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Text('SIGN UP'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      ),
      ),
    );
  }
}

class SkillChipSelector extends StatelessWidget {
  final List<String> skills;
  final List<String> selectedSkills;
  final ValueChanged<List<String>> onChanged;
  const SkillChipSelector({required this.skills, required this.selectedSkills, required this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Skill Categories',
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      child: Wrap(
        spacing: 8,
        children: skills.map((skill) {
          final selected = selectedSkills.contains(skill);
          return FilterChip(
            label: Text(skill, style: const TextStyle(color: Colors.white)),
            selected: selected,
            selectedColor: const Color(0xFF1976D2),
            checkmarkColor: Colors.white,
            backgroundColor: const Color(0xFF232323),
            onSelected: (val) {
              final newSkills = List<String>.from(selectedSkills);
              if (val) {
                newSkills.add(skill);
              } else {
                newSkills.remove(skill);
              }
              onChanged(newSkills);
            },
          );
        }).toList(),
      ),
    );
  }
}
