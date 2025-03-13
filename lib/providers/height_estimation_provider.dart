import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/height_estimation.dart';
import '../models/reference_object.dart';
import '../services/gemini_service.dart';

class HeightEstimationProvider with ChangeNotifier {
  List<HeightEstimation> _estimations = [];
  File? _selectedImage;
  ReferenceObject? _selectedReferenceObject;
  HeightEstimation? _currentEstimation;
  bool _isProcessing = false;
  String? _error;
  final GeminiService _geminiService = GeminiService();
  List<Map<String, dynamic>>? _detectedObjects;
  bool _isDetectingObjects = false;

  // Getters
  List<HeightEstimation> get estimations => _estimations;
  File? get selectedImage => _selectedImage;
  ReferenceObject? get selectedReferenceObject => _selectedReferenceObject;
  HeightEstimation? get currentEstimation => _currentEstimation;
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  List<Map<String, dynamic>>? get detectedObjects => _detectedObjects;
  bool get isDetectingObjects => _isDetectingObjects;

  // Initialize estimations from shared preferences
  Future<void> initEstimations() async {
    _isProcessing = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final estimationsJson = prefs.getString('estimations');

      if (estimationsJson != null) {
        final List<dynamic> decodedList = json.decode(estimationsJson);
        _estimations =
            decodedList.map((item) => HeightEstimation.fromJson(item)).toList();
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to load estimations: ${e.toString()}';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Save estimations to shared preferences
  Future<void> _saveEstimations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final estimationsJson = json.encode(
        _estimations.map((e) => e.toJson()).toList(),
      );
      await prefs.setString('estimations', estimationsJson);
    } catch (e) {
      _error = 'Failed to save estimations: ${e.toString()}';
      notifyListeners();
    }
  }

  // Setters
  void setSelectedImage(File image) {
    _selectedImage = image;
    // Reset detected objects when a new image is selected
    _detectedObjects = null;
    notifyListeners();
  }

  void setSelectedReferenceObject(ReferenceObject? referenceObject) {
    _selectedReferenceObject = referenceObject;
    notifyListeners();
  }

  void setCurrentEstimation(HeightEstimation estimation) {
    _currentEstimation = estimation;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Methods
  Future<void> detectReferenceObjects() async {
    if (_selectedImage == null) {
      _error = 'No image selected';
      notifyListeners();
      return;
    }

    _isDetectingObjects = true;
    notifyListeners();

    try {
      final result =
          await _geminiService.detectReferenceObjects(_selectedImage!);

      if (result.containsKey('detectedObjects')) {
        _detectedObjects =
            List<Map<String, dynamic>>.from(result['detectedObjects']);
      } else {
        _detectedObjects = [];
      }

      _error = null;
    } catch (e) {
      _error = 'Error detecting objects: ${e.toString()}';
      _detectedObjects = [];
    } finally {
      _isDetectingObjects = false;
      notifyListeners();
    }
  }

  Future<void> processImageAndEstimateHeight({required String userId}) async {
    if (_selectedImage == null) {
      _error = 'Image must be selected';
      notifyListeners();
      return;
    }

    _isProcessing = true;
    notifyListeners();

    try {
      Map<String, dynamic> result;
      ReferenceObject referenceObject;

      // If user selected a reference object, use it
      if (_selectedReferenceObject != null) {
        result = await _geminiService.estimateHeightFromImage(
          _selectedImage!,
          _selectedReferenceObject!.name,
          _selectedReferenceObject!.knownHeight,
        );
        referenceObject = _selectedReferenceObject!;
      } else {
        // Otherwise, let Gemini detect reference objects and estimate height
        result = await _geminiService
            .estimateHeightWithoutReference(_selectedImage!);

        // Create a reference object from Gemini's detection
        final refObjHeight = result['referenceObjectHeight'];
        final double knownHeight = refObjHeight == null
            ? 0.0
            : (refObjHeight is int)
                ? refObjHeight.toDouble()
                : (refObjHeight as double);

        referenceObject = ReferenceObject(
          id: result['referenceObjectUsed']
                  ?.toString()
                  .toLowerCase()
                  .replaceAll(' ', '_') ??
              'auto_detected',
          name: result['referenceObjectUsed'] ?? 'Auto-detected object',
          knownHeight: knownHeight,
          pixelHeight: 100.0, // Placeholder value
          boundingBox: {
            'x': 0.0,
            'y': 0.0,
            'width': 0.0,
            'height': 0.0,
          },
        );
      }

      // Extract the estimated height and confidence score
      final estimatedHeight = result['estimatedHeight'] is int
          ? (result['estimatedHeight'] as int).toDouble()
          : result['estimatedHeight'] as double;
      final confidenceScore = result['confidenceScore'] is int
          ? (result['confidenceScore'] as int).toDouble()
          : result['confidenceScore'] as double;
      final reasoning = result['reasoning'] as String;

      // Use gemini-2.0-flash to enhance the reasoning
      String enhancedReasoning = reasoning;
      try {
        final enhancedResult = await _geminiService.generateTextWithFlash(
            "Based on this height estimation reasoning: '$reasoning', provide a more structured and concise explanation of how the height of ${estimatedHeight.toStringAsFixed(1)} cm was calculated. Include reference object details and confidence factors. Keep it under 150 words.");

        if (enhancedResult.isNotEmpty && !enhancedResult.startsWith('Error')) {
          enhancedReasoning = enhancedResult;
        }
      } catch (e) {
        // If enhancement fails, use the original reasoning
        debugPrint('Error enhancing reasoning: $e');
      }

      // Create a new height estimation
      final estimation = HeightEstimation(
        id: const Uuid().v4(),
        imageUrl: _selectedImage!.path,
        estimatedHeight: estimatedHeight,
        confidenceScore: confidenceScore,
        referenceObject: referenceObject,
        userId: userId,
        notes: enhancedReasoning,
      );

      // Add to estimations list
      _estimations.add(estimation);
      _currentEstimation = estimation;
      await _saveEstimations();

      _error = null;
    } catch (e) {
      _error = 'Error processing image: ${e.toString()}';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  List<HeightEstimation> getEstimationsForUser(String userId) {
    return _estimations.where((e) => e.userId == userId).toList();
  }

  Future<void> deleteEstimation(String id) async {
    _isProcessing = true;
    notifyListeners();

    try {
      final estimation = _estimations.firstWhere((e) => e.id == id);

      // Delete the image file
      final imageFile = File(estimation.imageUrl);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }

      // Remove from list
      _estimations.removeWhere((e) => e.id == id);
      await _saveEstimations();

      if (_currentEstimation?.id == id) {
        _currentEstimation = null;
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to delete estimation: ${e.toString()}';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void reset() {
    _selectedImage = null;
    _selectedReferenceObject = null;
    _currentEstimation = null;
    _detectedObjects = null;
    _error = null;
    notifyListeners();
  }

  Future<void> _loadEstimations() async {
    // In a real app, this would load from SharedPreferences, a database, or the cloud
    // For this example, we'll just keep the data in memory
  }
}
