import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../providers/height_estimation_provider.dart';
import '../providers/user_provider.dart';
import '../components/gradient_button.dart';
import '../components/feature_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<bool> _handleGalleryPermission(BuildContext context) async {
    if (Platform.isAndroid) {
      // For Android 13 and above (SDK 33+)
      if (await Permission.photos.request().isGranted) {
        return true;
      }

      // For older Android versions
      if (await Permission.storage.request().isGranted) {
        return true;
      }

      // If both permissions are denied
      if (context.mounted) {
        _showPermissionDeniedDialog(context, isCamera: false);
      }
      return false;
    } else {
      // For iOS
      final status = await Permission.photos.request();
      if (status.isGranted) {
        return true;
      }
      if (context.mounted) {
        _showPermissionDeniedDialog(context, isCamera: false);
      }
      return false;
    }
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          if (context.mounted) {
            _showPermissionDeniedDialog(context);
          }
          return;
        }
      } else if (source == ImageSource.gallery) {
        final hasPermission = await _handleGalleryPermission(context);
        if (!hasPermission) {
          return;
        }
      }

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: AppConstants.maxImageWidth,
        maxHeight: AppConstants.maxImageHeight,
        imageQuality: AppConstants.imageQuality.toInt(),
      );

      if (pickedFile != null && context.mounted) {
        final estimationProvider = Provider.of<HeightEstimationProvider>(
          context,
          listen: false,
        );
        estimationProvider.setSelectedImage(File(pickedFile.path));

        // Navigate to image preview screen
        Navigator.pushNamed(context, AppConstants.imagePreviewRoute);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error accessing ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPermissionDeniedDialog(BuildContext context,
      {bool isCamera = true}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final permissionType = isCamera ? 'Camera' : 'Gallery';
        return AlertDialog(
          title: Text('$permissionType Permission Required'),
          content: Text(
            'To ${isCamera ? 'take photos' : 'select images'}, please grant $permissionType access in your device settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppConstants.largeBorderRadius),
              topRight: Radius.circular(AppConstants.largeBorderRadius),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    context,
                    Icons.camera_alt,
                    'Camera',
                    () => _pickImage(context, ImageSource.camera),
                  ),
                  _buildImageSourceOption(
                    context,
                    Icons.photo_library,
                    'Gallery',
                    () => _pickImage(context, ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.defaultPadding),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSourceOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryLightColor,
                  AppTheme.backgroundColor,
                ],
                stops: [0.0, 0.3],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppConstants.appName,
                          style: AppTheme.headingStyle.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                                context, AppConstants.profileRoute);
                          },
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 24,
                            child: userProvider.userProfile?.profileImageUrl !=
                                    null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: CachedNetworkImage(
                                      imageUrl: userProvider
                                          .userProfile!.profileImageUrl!,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    color: AppTheme.primaryColor,
                                    size: 28,
                                  ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Welcome message
                    Text(
                      AppConstants.welcomeMessage,
                      style: AppTheme.headingStyle.copyWith(
                        fontSize: 28,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      AppConstants.uploadImageText,
                      style: AppTheme.bodyStyle.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Main action card
                    Container(
                      padding:
                          const EdgeInsets.all(AppConstants.defaultPadding),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                            AppConstants.defaultBorderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/person.webp',
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: AppConstants.defaultPadding),
                          GradientButton(
                            text: 'Upload Image',
                            onPressed: () => _showImageSourceDialog(context),
                            gradient: AppTheme.primaryGradient,
                            icon: Icons.camera_alt,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Features section
                    Text(
                      'Features',
                      style: AppTheme.subheadingStyle,
                    ),

                    const SizedBox(height: 16),

                    // Feature cards
                    Row(
                      children: [
                        Expanded(
                          child: FeatureCard(
                            icon: Icons.history,
                            title: 'History',
                            description: 'View your past height estimations',
                            onTap: () {
                              Navigator.pushNamed(
                                  context, AppConstants.historyRoute);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FeatureCard(
                            icon: Icons.person,
                            title: 'Profile',
                            description: 'Manage your profile and settings',
                            onTap: () {
                              Navigator.pushNamed(
                                  context, AppConstants.profileRoute);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
