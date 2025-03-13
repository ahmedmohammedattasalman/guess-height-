import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String apiKey = 'AIzaSyDe1ogWJNUW7isJFK05pTpWxjTO4v90ctQ';
  final GenerativeModel _visionModel;
  final GenerativeModel _flashModel;
  final String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  GeminiService()
      : _visionModel = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: apiKey,
        ),
        _flashModel = GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: apiKey,
        );

  Future<String> analyzeImage(File imageFile, {String? prompt}) async {
    try {
      // Read the image file as bytes
      final bytes = await imageFile.readAsBytes();

      // Create the prompt
      final promptText = prompt ??
          'Analyze this image and identify any reference objects that could be used for height estimation. If you see a person, estimate their height based on visible reference objects.';

      // Create content parts
      final textPart = TextPart(promptText);
      final imagePart = DataPart('image/jpeg', bytes);

      // Generate content
      final response = await _visionModel.generateContent([
        Content.multi([textPart, imagePart])
      ]);

      return response.text ?? 'No analysis available';
    } catch (e) {
      debugPrint('Error analyzing image with Gemini: $e');
      return 'Error analyzing image: $e';
    }
  }

  Future<String> generateTextWithFlash(String prompt) async {
    try {
      final response =
          await _flashModel.generateContent([Content.text(prompt)]);

      return response.text ?? 'No response generated';
    } catch (e) {
      debugPrint('Error generating text with Gemini Flash: $e');
      return 'Error: $e';
    }
  }

  // Direct API call using HTTP for more control
  Future<Map<String, dynamic>> callGeminiFlashApi(String prompt) async {
    try {
      final url = '$_baseUrl/gemini-2.0-flash:generateContent?key=$apiKey';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('API error: ${response.statusCode} - ${response.body}');
        return {
          'error': 'API error: ${response.statusCode}',
          'message': response.body
        };
      }
    } catch (e) {
      debugPrint('Error calling Gemini Flash API: $e');
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> detectReferenceObjects(File imageFile) async {
    try {
      const prompt = '''
      Analyze this image and identify any common objects that could be used as reference for height estimation.
      For each object you identify:
      1. Determine its approximate height in centimeters
      2. Assign a confidence score between 0 and 1 for your identification
      3. Return your answer in JSON format with the following fields:
         - detectedObjects: array of objects with properties: name, estimatedHeight, confidenceScore
         - personDetected: boolean indicating if a person is in the image
      
      Focus on common objects with known standard sizes like:
      - Credit cards (8.5 cm)
      - Smartphones (14-16 cm)
      - Soda cans (12 cm)
      - Standard doors (200 cm)
      - A4 paper (29.7 cm)
      - Basketballs (24 cm)
      ''';

      final response = await analyzeImage(imageFile, prompt: prompt);

      // Use safe parsing helper
      final defaultValue = {
        'detectedObjects': [],
        'personDetected': false,
        'rawResponse': response
      };

      return _safeParseJson(response, defaultValue);
    } catch (e) {
      debugPrint('Error detecting objects with Gemini: $e');
      return {
        'detectedObjects': [],
        'personDetected': false,
        'error': 'Error communicating with Gemini API: $e'
      };
    }
  }

  Future<Map<String, dynamic>> estimateHeightFromImage(File imageFile,
      String referenceObjectName, double referenceObjectHeight) async {
    try {
      final prompt = '''
      In this image, there is a reference object: $referenceObjectName with a known height of $referenceObjectHeight cm.
      Please:
      1. Identify the person in the image
      2. Estimate their height in centimeters based on the reference object
      3. Provide a confidence score between 0 and 1
      4. Return your answer in JSON format with the following fields: estimatedHeight (number), confidenceScore (number), reasoning (string)
      ''';

      final response = await analyzeImage(imageFile, prompt: prompt);

      // Use safe parsing helper
      final defaultValue = {
        'estimatedHeight': 170.0, // Default fallback
        'confidenceScore': 0.5,
        'reasoning':
            'Could not extract structured data from Gemini response. Raw response: $response'
      };

      return _safeParseJson(response, defaultValue);
    } catch (e) {
      debugPrint('Error estimating height with Gemini: $e');
      return {
        'estimatedHeight': 170.0, // Default fallback
        'confidenceScore': 0.3,
        'reasoning': 'Error communicating with Gemini API: $e'
      };
    }
  }

  Future<Map<String, dynamic>> estimateHeightWithoutReference(
      File imageFile) async {
    try {
      const prompt = '''
      Analyze this image and:
      1. Identify if there's a person in the image
      2. Look for any objects near the person that could serve as reference (like furniture, doors, common items)
      3. Based on these reference objects, estimate the person's height in centimeters
      4. Provide a confidence score between 0 and 1
      5. Return your answer in JSON format with the following fields: 
         - estimatedHeight (number)
         - confidenceScore (number)
         - reasoning (string)
         - referenceObjectUsed (string)
         - referenceObjectHeight (number)
      ''';

      final response = await analyzeImage(imageFile, prompt: prompt);

      // Use safe parsing helper
      final defaultValue = {
        'estimatedHeight': 170.0, // Default fallback
        'confidenceScore': 0.3,
        'reasoning':
            'Could not extract structured data from Gemini response. Raw response: $response',
        'referenceObjectUsed': 'None detected',
        'referenceObjectHeight': 0.0
      };

      return _safeParseJson(response, defaultValue);
    } catch (e) {
      debugPrint('Error estimating height with Gemini: $e');
      return {
        'estimatedHeight': 170.0, // Default fallback
        'confidenceScore': 0.2,
        'reasoning': 'Error communicating with Gemini API: $e',
        'referenceObjectUsed': 'None detected',
        'referenceObjectHeight': 0.0
      };
    }
  }

  // Helper method to safely convert values to double
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return 0.0;
      }
    }
    return 0.0;
  }

  // Helper method to safely parse JSON from Gemini response
  Map<String, dynamic> _safeParseJson(
      String response, Map<String, dynamic> defaultValue) {
    try {
      // Look for JSON in the response
      final jsonRegExp = RegExp(r'\{.*\}', dotAll: true);
      final match = jsonRegExp.firstMatch(response);

      if (match != null) {
        final jsonStr = match.group(0);
        if (jsonStr != null) {
          final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

          // Ensure numeric values are properly converted to double
          if (parsed.containsKey('estimatedHeight')) {
            parsed['estimatedHeight'] =
                _safeToDouble(parsed['estimatedHeight']);
          }

          if (parsed.containsKey('confidenceScore')) {
            parsed['confidenceScore'] =
                _safeToDouble(parsed['confidenceScore']);
          }

          if (parsed.containsKey('referenceObjectHeight')) {
            parsed['referenceObjectHeight'] =
                _safeToDouble(parsed['referenceObjectHeight']);
          }

          // Handle detected objects array
          if (parsed.containsKey('detectedObjects') &&
              parsed['detectedObjects'] is List) {
            final objects = parsed['detectedObjects'] as List;
            for (int i = 0; i < objects.length; i++) {
              if (objects[i] is Map<String, dynamic>) {
                final obj = objects[i] as Map<String, dynamic>;
                if (obj.containsKey('estimatedHeight')) {
                  obj['estimatedHeight'] =
                      _safeToDouble(obj['estimatedHeight']);
                }
                if (obj.containsKey('confidenceScore')) {
                  obj['confidenceScore'] =
                      _safeToDouble(obj['confidenceScore']);
                }
              }
            }
          }

          return parsed;
        }
      }
      return defaultValue;
    } catch (e) {
      debugPrint('Error parsing Gemini response: $e');
      return defaultValue;
    }
  }
}
