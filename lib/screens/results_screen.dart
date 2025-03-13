import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../providers/height_estimation_provider.dart';
import '../providers/user_provider.dart';
import '../components/gradient_button.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  // Helper function to determine if a path is a URL or a local file
  bool _isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final estimationProvider = Provider.of<HeightEstimationProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    if (estimationProvider.currentEstimation == null) {
      // If no estimation is available, go back to home screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppConstants.homeRoute);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final estimation = estimationProvider.currentEstimation!;
    final heightInCm = estimation.estimatedHeight;
    final heightInFeetAndInches = estimation.getHeightInFeetAndInches();
    final confidenceScore = (estimation.confidenceScore * 100).toInt();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Height Estimation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share functionality would be implemented here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Sharing functionality coming soon')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Result card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius:
                      BorderRadius.circular(AppConstants.defaultBorderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      AppConstants.heightEstimationResultText,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          heightInCm.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          ' cm',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      heightInFeetAndInches,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Confidence: $confidenceScore%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Image with reference object
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(AppConstants.defaultBorderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft:
                            Radius.circular(AppConstants.defaultBorderRadius),
                        topRight:
                            Radius.circular(AppConstants.defaultBorderRadius),
                      ),
                      child: _isNetworkImage(estimation.imageUrl)
                          ? CachedNetworkImage(
                              imageUrl: estimation.imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                height: 200,
                                color: Colors.grey.withOpacity(0.1),
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          : Image.file(
                              File(estimation.imageUrl),
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  color: Colors.grey.withOpacity(0.1),
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reference Object',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getReferenceObjectIcon(
                                      estimation.referenceObject.name),
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    estimation.referenceObject.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Height: ${estimation.referenceObject.knownHeight.toStringAsFixed(1)} cm',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                            context, AppConstants.homeRoute);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('New Estimation'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (userProvider.isLoggedIn) {
                          await userProvider.saveEstimation(estimation.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Estimation saved to your profile'),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                          }
                        } else {
                          Navigator.pushNamed(
                              context, AppConstants.profileRoute);
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Save Result'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              GradientButton(
                text: 'View History',
                onPressed: () {
                  Navigator.pushNamed(context, AppConstants.historyRoute);
                },
                gradient: AppTheme.accentGradient,
                icon: Icons.history,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getReferenceObjectIcon(String name) {
    switch (name) {
      case 'Credit Card':
        return Icons.credit_card;
      case 'Standard Door':
        return Icons.door_front_door;
      case 'iPhone 13':
        return Icons.phone_iphone;
      case 'Soda Can':
        return Icons.local_drink;
      case 'Basketball':
        return Icons.sports_basketball;
      case 'A4 Paper':
        return Icons.description;
      default:
        return Icons.category;
    }
  }
}
