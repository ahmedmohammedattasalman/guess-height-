import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../providers/height_estimation_provider.dart';
import '../providers/user_provider.dart';
import '../models/height_estimation.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // Helper function to determine if a path is a URL or a local file
  bool _isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final estimationProvider = Provider.of<HeightEstimationProvider>(context);

    // Get estimations for the current user, or all estimations if no user is logged in
    final List<HeightEstimation> estimations = userProvider.isLoggedIn
        ? estimationProvider.getEstimationsForUser(userProvider.userProfile!.id)
        : estimationProvider.estimations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: estimations.isEmpty
          ? _buildEmptyState()
          : _buildEstimationsList(context, estimations),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            AppConstants.noHistoryText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make your first height estimation',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimationsList(
      BuildContext context, List<HeightEstimation> estimations) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: estimations.length,
      itemBuilder: (context, index) {
        final estimation = estimations[
            estimations.length - 1 - index]; // Reverse order (newest first)
        return _buildEstimationCard(context, estimation);
      },
    );
  }

  Widget _buildEstimationCard(
      BuildContext context, HeightEstimation estimation) {
    final estimationProvider =
        Provider.of<HeightEstimationProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Set as current estimation and navigate to results screen
          estimationProvider.setCurrentEstimation(estimation);
          Navigator.pushNamed(context, AppConstants.resultsRoute);
        },
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.defaultBorderRadius),
                topRight: Radius.circular(AppConstants.defaultBorderRadius),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _isNetworkImage(estimation.imageUrl)
                    ? CachedNetworkImage(
                        imageUrl: estimation.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.withOpacity(0.1),
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    : Image.file(
                        File(estimation.imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.withOpacity(0.1),
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and height
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(estimation.createdAt),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.height,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${estimation.estimatedHeight.toStringAsFixed(1)} cm',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Reference object
                  Row(
                    children: [
                      const Text(
                        'Reference: ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        estimation.referenceObject.name,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  // Notes (if any)
                  if (estimation.notes != null &&
                      estimation.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      estimation.notes!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          // View details
                          estimationProvider.setCurrentEstimation(estimation);
                          Navigator.pushNamed(
                              context, AppConstants.resultsRoute);
                        },
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('View'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        onPressed: () {
                          // Delete confirmation
                          _showDeleteConfirmation(context, estimation);
                        },
                        icon: const Icon(Icons.delete,
                            size: 18, color: AppTheme.errorColor),
                        label: const Text('Delete',
                            style: TextStyle(color: AppTheme.errorColor)),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showDeleteConfirmation(
      BuildContext context, HeightEstimation estimation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Estimation'),
        content: const Text(
            'Are you sure you want to delete this height estimation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final estimationProvider = Provider.of<HeightEstimationProvider>(
                context,
                listen: false,
              );
              await estimationProvider.deleteEstimation(estimation.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Estimation deleted'),
                  ),
                );
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}
