import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../providers/user_provider.dart';
import '../models/user_profile.dart';
import '../components/gradient_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _heightController = TextEditingController();
  bool _isLoading = false;
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _initUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _initUserData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userProfile = userProvider.userProfile;

    if (userProfile != null) {
      _nameController.text = userProfile.name;
      _emailController.text = userProfile.email;
      if (userProfile.knownHeight != null) {
        _heightController.text = userProfile.knownHeight!.toString();
      }
      if (userProfile.profileImageUrl != null) {
        _profileImagePath = userProfile.profileImageUrl;
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 90,
    );

    if (pickedFile != null && mounted) {
      setState(() {
        _profileImagePath = pickedFile.path;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.userProfile;

      // In a real app, we would upload the image to a server
      // and get a URL back. For now, we'll just use the local path.
      final profileImageUrl = _profileImagePath;

      // Parse height if provided
      double? knownHeight;
      if (_heightController.text.isNotEmpty) {
        knownHeight = double.tryParse(_heightController.text);
      }

      if (currentUser == null) {
        // Create new user
        final newUser = UserProfile(
          id: const Uuid().v4(),
          name: _nameController.text,
          email: _emailController.text,
          profileImageUrl: profileImageUrl,
          knownHeight: knownHeight,
        );

        await userProvider.saveUserProfile(newUser);
      } else {
        // Update existing user
        await userProvider.updateUserProfile(
          name: _nameController.text,
          email: _emailController.text,
          profileImageUrl: profileImageUrl,
          knownHeight: knownHeight,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isNewUser = userProvider.userProfile == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNewUser ? 'Create Profile' : 'Edit Profile'),
        actions: [
          if (!isNewUser)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await userProvider.logOut();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile image
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        backgroundImage: _profileImagePath != null
                            ? (_profileImagePath!.startsWith('http')
                                ? NetworkImage(_profileImagePath!)
                                    as ImageProvider
                                : FileImage(File(_profileImagePath!)))
                            : null,
                        child: _profileImagePath == null
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Height field
                TextFormField(
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: 'Your Height (cm)',
                    prefixIcon: Icon(Icons.height),
                    hintText: 'Optional',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final height = double.tryParse(value);
                      if (height == null) {
                        return 'Please enter a valid number';
                      }
                      if (height < 50 || height > 250) {
                        return 'Please enter a realistic height (50-250 cm)';
                      }
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Save button
                _isLoading
                    ? const CircularProgressIndicator()
                    : GradientButton(
                        text: isNewUser ? 'Create Profile' : 'Save Changes',
                        onPressed: _saveProfile,
                        gradient: AppTheme.primaryGradient,
                        icon: isNewUser ? Icons.person_add : Icons.save,
                      ),

                if (!isNewUser) ...[
                  const SizedBox(height: 24),

                  // Delete account button
                  OutlinedButton.icon(
                    onPressed: () {
                      // In a real app, we would show a confirmation dialog
                      // and then delete the account
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Account deletion coming soon'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete Account'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: const BorderSide(color: AppTheme.errorColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
