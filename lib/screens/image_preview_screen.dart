import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../providers/height_estimation_provider.dart';
import '../providers/user_provider.dart';
import '../models/reference_object.dart';
import '../components/gradient_button.dart';
import '../services/gemini_service.dart';

class ImagePreviewScreen extends StatefulWidget {
  const ImagePreviewScreen({super.key});

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  String? _selectedReferenceObjectName;
  bool _isProcessing = false;
  bool _isAutoDetecting = false;
  String? _customObjectName;
  double? _customObjectHeight;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto-detect objects when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoDetectObjects();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _clearCustomObjectInputs() {
    setState(() {
      _customObjectName = null;
      _customObjectHeight = null;
      _nameController.clear();
      _heightController.clear();
    });
  }

  Future<void> _autoDetectObjects() async {
    setState(() {
      _isAutoDetecting = true;
    });

    final estimationProvider =
        Provider.of<HeightEstimationProvider>(context, listen: false);

    await estimationProvider.detectReferenceObjects();

    setState(() {
      _isAutoDetecting = false;
    });
  }

  Future<void> _cropImage(BuildContext context) async {
    final estimationProvider = Provider.of<HeightEstimationProvider>(
      context,
      listen: false,
    );

    if (estimationProvider.selectedImage == null) {
      return;
    }

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: estimationProvider.selectedImage!.path,
      aspectRatioPresets: [
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9,
      ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: AppTheme.primaryColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Image',
        ),
      ],
    );

    if (croppedFile != null && context.mounted) {
      estimationProvider.setSelectedImage(File(croppedFile.path));
      // Re-detect objects after cropping
      _autoDetectObjects();
    }
  }

  void _selectReferenceObject(String name, double knownHeight) {
    final estimationProvider = Provider.of<HeightEstimationProvider>(
      context,
      listen: false,
    );

    // In a real app, we would detect the object in the image
    // and calculate its pixel height. For now, we'll use a simulated value.
    const pixelHeight = 100.0; // Simulated pixel height

    final referenceObject = ReferenceObject(
      id: name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      knownHeight: knownHeight,
      pixelHeight: pixelHeight,
      boundingBox: {
        'x': 100.0,
        'y': 100.0,
        'width': 50.0,
        'height': pixelHeight,
      },
    );

    estimationProvider.setSelectedReferenceObject(referenceObject);
    setState(() {
      _selectedReferenceObjectName = name;
    });

    // If this was a custom object, clear the input fields
    if (_customObjectName != null && _customObjectName == name) {
      _clearCustomObjectInputs();

      // Show a confirmation snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "$name" as reference object'),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _processImage() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final estimationProvider = Provider.of<HeightEstimationProvider>(
      context,
      listen: false,
    );

    setState(() {
      _isProcessing = true;
    });

    // Process the image and estimate height
    await estimationProvider.processImageAndEstimateHeight(
      userId: userProvider.userProfile?.id ?? 'guest',
    );

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    if (estimationProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(estimationProvider.error!),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      estimationProvider.clearError();
    } else if (estimationProvider.currentEstimation != null) {
      // Navigate to results screen
      Navigator.pushReplacementNamed(context, AppConstants.resultsRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estimationProvider = Provider.of<HeightEstimationProvider>(context);

    if (estimationProvider.selectedImage == null) {
      // If no image is selected, go back to home screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.crop),
            onPressed: () => _cropImage(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image preview
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppConstants.defaultBorderRadius),
                child: Image.file(
                  estimationProvider.selectedImage!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 16),

              // Hint box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppConstants.defaultBorderRadius),
                  border: Border.all(color: Colors.amber.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tips_and_updates,
                            color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Tips for Accurate Height Estimation',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Make sure the person and reference object are in the same plane\n'
                      '• Choose objects with known standard heights\n'
                      '• If AI doesn\'t detect an object, add it manually below\n'
                      '• For best results, ensure the entire person is visible',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Auto-detected objects section
              if (_isAutoDetecting)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Analyzing image for reference objects...'),
                    ],
                  ),
                )
              else if (estimationProvider.detectedObjects != null &&
                  estimationProvider.detectedObjects!.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detected Reference Objects',
                      style: AppTheme.subheadingStyle,
                    ),
                    TextButton.icon(
                      onPressed: _autoDetectObjects,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.defaultBorderRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...estimationProvider.detectedObjects!.map((obj) {
                        final name = obj['name'] as String;
                        // Convert to double safely
                        final height = (obj['estimatedHeight'] is int)
                            ? (obj['estimatedHeight'] as int).toDouble()
                            : obj['estimatedHeight'] as double;
                        // Convert to double safely
                        final confidence = (obj['confidenceScore'] is int)
                            ? (obj['confidenceScore'] as int).toDouble()
                            : obj['confidenceScore'] as double;

                        return ListTile(
                          leading: Icon(_getReferenceObjectIcon(name)),
                          title: Text(name),
                          subtitle:
                              Text('Height: ${height.toStringAsFixed(1)} cm'),
                          trailing:
                              Text('${(confidence * 100).toInt()}% confidence'),
                          onTap: () => _selectReferenceObject(name, height),
                          selected: _selectedReferenceObjectName == name,
                          selectedTileColor:
                              AppTheme.primaryColor.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap on a detected object to use it as reference, or select a standard object below.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Reference object selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Standard Reference Objects',
                    style: AppTheme.subheadingStyle,
                  ),
                  if (_selectedReferenceObjectName != null)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedReferenceObjectName = null;
                        });
                        // Clear the reference object
                        estimationProvider.setSelectedReferenceObject(null);
                      },
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear Selection'),
                    ),
                ],
              ),

              if (_selectedReferenceObjectName != null)
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.defaultBorderRadius),
                    border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getReferenceObjectIcon(_selectedReferenceObjectName!),
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                color: Colors.black87, fontSize: 14),
                            children: [
                              const TextSpan(
                                text: 'Currently using: ',
                                style: TextStyle(fontWeight: FontWeight.normal),
                              ),
                              TextSpan(
                                text: _selectedReferenceObjectName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text:
                                    ' (${estimationProvider.selectedReferenceObject?.knownHeight.toStringAsFixed(1)} cm)',
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Custom reference object input
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius:
                      BorderRadius.circular(AppConstants.defaultBorderRadius),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Add Custom Reference Object',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'If you see an object in the image with a known height, you can add it manually:',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Object Name',
                              hintText: 'e.g., Door, Table',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _customObjectName = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _heightController,
                            decoration: const InputDecoration(
                              labelText: 'Height (cm)',
                              hintText: 'e.g., 200',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _customObjectHeight = double.tryParse(value);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _customObjectName != null &&
                                _customObjectName!.isNotEmpty &&
                                _customObjectHeight != null
                            ? () => _selectReferenceObject(
                                _customObjectName!, _customObjectHeight!)
                            : null,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Reference Object'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Reference object grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: AppConstants.referenceObjectHeights.length,
                itemBuilder: (context, index) {
                  final entry = AppConstants.referenceObjectHeights.entries
                      .elementAt(index);
                  final name = entry.key;
                  final height = entry.value;
                  final isSelected = _selectedReferenceObjectName == name;

                  return GestureDetector(
                    onTap: () => _selectReferenceObject(name, height),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                            AppConstants.defaultBorderRadius),
                        border: isSelected
                            ? Border.all(color: AppTheme.primaryColor, width: 2)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getReferenceObjectIcon(name),
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.grey[700],
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey[800],
                            ),
                          ),
                          Text(
                            '${height.toStringAsFixed(1)} cm',
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Process buttons
              _isProcessing
                  ? const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Processing image...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        GradientButton(
                          text: _selectedReferenceObjectName == null
                              ? 'Estimate Height (Auto-detect Reference)'
                              : 'Estimate Height with $_selectedReferenceObjectName',
                          onPressed: _processImage,
                          gradient: AppTheme.primaryGradient,
                          icon: Icons.height,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () async {
                            setState(() {
                              _isProcessing = true;
                            });

                            try {
                              final geminiService = GeminiService();

                              // First analyze the image with vision model
                              final imageAnalysis =
                                  await geminiService.analyzeImage(
                                estimationProvider.selectedImage!,
                                prompt:
                                    'Analyze this image and identify any reference objects that could be used for height estimation. If you see a person, estimate their height based on visible reference objects. Be concise.',
                              );

                              // Then use gemini-2.0-flash to enhance the analysis
                              final enhancedAnalysis =
                                  await geminiService.generateTextWithFlash(
                                      "Based on this image analysis: '$imageAnalysis', provide a more structured and concise height estimation. Include: 1) Detected reference objects with their heights, 2) Estimated person's height if visible, 3) Confidence level of the estimation.");

                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Gemini Analysis'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'Enhanced Analysis (gemini-2.0-flash):',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(enhancedAnalysis),
                                          const Divider(),
                                          const Text(
                                            'Raw Image Analysis:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            imageAnalysis,
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error analyzing image: $e'),
                                    backgroundColor: AppTheme.errorColor,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isProcessing = false;
                                });
                              }
                            }
                          },
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Analyze with Gemini AI  '),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getReferenceObjectIcon(String name) {
    switch (name.toLowerCase()) {
      case 'credit card':
        return Icons.credit_card;
      case 'standard door':
      case 'door':
        return Icons.door_front_door;
      case 'iphone':
      case 'iphone 13':
      case 'smartphone':
      case 'phone':
        return Icons.phone_iphone;
      case 'soda can':
      case 'can':
        return Icons.local_drink;
      case 'basketball':
      case 'ball':
        return Icons.sports_basketball;
      case 'a4 paper':
      case 'paper':
      case 'document':
        return Icons.description;
      case 'table':
      case 'desk':
        return Icons.table_bar;
      case 'chair':
        return Icons.chair;
      case 'bottle':
      case 'water bottle':
        return Icons.water_drop;
      case 'laptop':
      case 'computer':
        return Icons.laptop;
      case 'book':
        return Icons.book;
      default:
        return Icons.category;
    }
  }
}
