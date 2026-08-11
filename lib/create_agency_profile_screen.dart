import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'agency_options_screen.dart';
import 'agency_screen.dart';

class CreateAgencyProfileScreen extends StatefulWidget {
  final String userId;
  final String? agencyId;
  final bool isEditing;
  final bool isAdmin;
  
  const CreateAgencyProfileScreen({
    Key? key,
    required this.userId,
    this.agencyId,
    this.isEditing = false,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  State<CreateAgencyProfileScreen> createState() => _CreateAgencyProfileScreenState();
}

class _CreateAgencyProfileScreenState extends State<CreateAgencyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _servicesController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  
  // State variables
  File? _logoImage;
  File? _coverImage;
  List<String> _selectedServices = [];
  List<String> _customServices = []; // For manually added services
  bool isLoading = false;
  bool _isLoadingData = false;
  
  // Available services
  final List<String> _availableServices = [
    'Web Development',
    'Mobile Apps',
    'UI/UX Design',
    'Digital Marketing',
    'SEO Services',
    'Content Writing',
    'Video Production',
    'Social Media Management',
    'E-commerce Solutions',
    'Cloud Services',
    'AI & Machine Learning',
    'Blockchain Development',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.agencyId != null) {
      _loadAgencyData();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _servicesController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _loadAgencyData() async {
    setState(() => _isLoadingData = true);
    
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('agencies')
          .doc(widget.agencyId)
          .get();
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        _nameController.text = data['name'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _websiteController.text = data['website'] ?? '';
        _countryController.text = data['country'] ?? '';
        _cityController.text = data['city'] ?? '';
        _experienceController.text = data['experience'] ?? '';
        
        // Load services and separate custom services
        final services = List<String>.from(data['services'] ?? []);
        _selectedServices = services;
        
        // Identify custom services (services not in predefined list)
        _customServices = services.where((service) => !_availableServices.contains(service)).toList();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading agency data: $e')),
      );
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _pickImage(bool isLogo) async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      setState(() {
        if (isLogo) {
          _logoImage = File(pickedFile.path);
        } else {
          _coverImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<String?> _uploadImage(File? image, String folder) async {
    if (image == null) return null;
    
    try {
      // Create a unique filename
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${widget.userId}.jpg';
      Reference ref = FirebaseStorage.instance
          .ref()
          .child(folder)
          .child(fileName);
      
      // Upload with metadata
      UploadTask uploadTask = ref.putFile(
        image,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploaded_by': widget.userId,
            'uploaded_at': DateTime.now().toIso8601String(),
          },
        ),
      );
      
      // Wait for completion
      TaskSnapshot snapshot = await uploadTask;
      
      // Check if upload was successful
      if (snapshot.state == TaskState.success) {
        String downloadUrl = await snapshot.ref.getDownloadURL();
        print('Image uploaded successfully: $downloadUrl');
        return downloadUrl;
      } else {
        print('Upload failed with state: ${snapshot.state}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveAgency() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => isLoading = true);
    
    try {
      print('Starting agency creation process...');
      
      // Upload images with better error handling
      String? logoUrl;
      String? coverUrl;
      
      if (_logoImage != null) {
        print('Uploading logo image...');
        logoUrl = await _uploadImage(_logoImage, 'agency_logos');
        if (logoUrl != null) {
          print('Logo uploaded successfully: $logoUrl');
        } else {
          print('Logo upload failed');
        }
      }
      
      if (_coverImage != null) {
        print('Uploading cover image...');
        coverUrl = await _uploadImage(_coverImage, 'agency_covers');
        if (coverUrl != null) {
          print('Cover uploaded successfully: $coverUrl');
        } else {
          print('Cover upload failed');
        }
      }
      
      // Prepare agency data
      Map<String, dynamic> agencyData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'website': _websiteController.text.trim(),
        'country': _countryController.text.trim(),
        'city': _cityController.text.trim(),
        'experience': _experienceController.text.trim(),
        'services': _selectedServices,
        'ownerId': widget.userId,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'rating': 0.0,
        'totalProjects': 0,
      };
      
      // Add image URLs if uploaded
      if (logoUrl != null) {
        agencyData['logoUrl'] = logoUrl;
      }
      if (coverUrl != null) {
        agencyData['coverUrl'] = coverUrl;
      }
      
      print('Saving agency data to Firestore...');
      
      if (widget.isEditing && widget.agencyId != null) {
        // Update existing agency
        await FirebaseFirestore.instance
            .collection('agencies')
            .doc(widget.agencyId)
            .update(agencyData);
        
        print('Agency updated successfully!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agency profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Create new agency
        DocumentReference docRef = await FirebaseFirestore.instance
            .collection('agencies')
            .add(agencyData);
        
        print('Agency created successfully with ID: ${docRef.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agency profile created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Navigate back to agency options
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => AgencyOptionsScreen(userId: widget.userId)),
        (route) => false,
      );
      
      // Force refresh the agencies stream by triggering a rebuild
      // The StreamBuilder will automatically pick up changes from Firestore
      print('Agency data updated in Firestore, StreamBuilder should refresh automatically');
      
    } catch (e) {
      print('Error saving agency: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving agency: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _toggleService(String service) {
    setState(() {
      if (_selectedServices.contains(service)) {
        _selectedServices.remove(service);
      } else {
        _selectedServices.add(service);
      }
    });
  }

  void _addCustomService() {
    final service = _servicesController.text.trim();
    if (service.isNotEmpty && !_selectedServices.contains(service)) {
      setState(() {
        _selectedServices.add(service);
        _customServices.add(service);
        _servicesController.clear();
      });
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
        title: Text(
          widget.isAdmin ? 'Edit Agency' : (widget.isEditing ? 'Edit Agency Profile' : 'Create Agency Profile'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AgencyScreen(userId: widget.userId),
              ),
            ),
            child: const Text(
              'View as Member',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 32 : 16,
                vertical: isWide ? 24 : 16,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo and Cover Images
                    Row(
                      children: [
                        // Logo
                        Expanded(
                          child: _buildImagePicker(
                            'Agency Logo',
                            _logoImage,
                            true,
                            isWide,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Cover Image
                        Expanded(
                          child: _buildImagePicker(
                            'Cover Image',
                            _coverImage,
                            false,
                            isWide,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Basic Information
                    _buildSectionTitle('Basic Information', isWide),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      'Agency Name',
                      _nameController,
                      'Enter agency name',
                      Icons.business,
                      validator: (value) => value?.isEmpty == true ? 'Required' : null,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      'Description',
                      _descriptionController,
                      'Describe your agency',
                      Icons.description,
                      maxLines: 4,
                      validator: (value) => value?.isEmpty == true ? 'Required' : null,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Contact Information
                    _buildSectionTitle('Contact Information', isWide),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      'Website',
                      _websiteController,
                      'https://example.com',
                      Icons.language,
                      keyboardType: TextInputType.url,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      'Country',
                      _countryController,
                      'Enter country',
                      Icons.location_on,
                      validator: (value) => value?.isEmpty == true ? 'Required' : null,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Services
                    _buildSectionTitle('Services Offered', isWide),
                    const SizedBox(height: 16),
                    
                    // Predefined services
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableServices.map((service) {
                        final isSelected = _selectedServices.contains(service);
                        return FilterChip(
                          label: Text(
                            service,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (_) => _toggleService(service),
                          backgroundColor: const Color(0xFF2C2C2C),
                          selectedColor: const Color(0xFF2C2C2C),
                          checkmarkColor: Colors.white,
                        );
                      }).toList(),
                    ),
                    
                    // Custom services
                    if (_customServices.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildSectionTitle('Custom Services', isWide),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _customServices.map((service) {
                          return FilterChip(
                            label: Text(
                              service,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            selected: true,
                            onSelected: (_) => _toggleService(service),
                            backgroundColor: const Color(0xFF2C2C2C),
                            selectedColor: const Color(0xFF2C2C2C),
                            checkmarkColor: Colors.white,
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _selectedServices.remove(service);
                                _customServices.remove(service);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    
                    // Add custom service input
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _servicesController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Add custom service...',
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: const Color(0xFF2C2C2C),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _addCustomService(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addCustomService,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C2C2C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Experience
                    _buildSectionTitle('Experience', isWide),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      'Years of Experience',
                      _experienceController,
                      'e.g., 5+ years in web development',
                      Icons.work,
                      validator: (value) => value?.isEmpty == true ? 'Required' : null,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: isWide ? 56 : 48,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _saveAgency,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C2C2C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(isWide ? 16 : 12),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                widget.isEditing ? 'Update Profile' : 'Create Profile',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, bool isWide) {
    return Text(
      title,
      style: TextStyle(
        color: const Color(0xFFFFD700),
        fontSize: isWide ? 20 : 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: const Color(0xFFFFD700)),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFD700)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildImagePicker(String label, File? image, bool isLogo, bool isWide) {
    return GestureDetector(
      onTap: () => _pickImage(isLogo),
      child: Container(
        height: isWide ? 150 : 120,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.3),
          ),
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(image, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isLogo ? Icons.business : Icons.image,
                    color: const Color(0xFFFFD700),
                    size: isWide ? 40 : 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: const Color(0xFFFFD700),
                      fontSize: isWide ? 14 : 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to upload',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: isWide ? 12 : 10,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
