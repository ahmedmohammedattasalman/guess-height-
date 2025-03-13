import 'reference_object.dart';

class HeightEstimation {
  final String id;
  final String imageUrl;
  final String? thumbnailUrl;
  final double estimatedHeight; // in cm
  final double confidenceScore; // 0.0 to 1.0
  final ReferenceObject referenceObject;
  final String? userId;
  final String? notes;
  final DateTime createdAt;

  HeightEstimation({
    required this.id,
    required this.imageUrl,
    this.thumbnailUrl,
    required this.estimatedHeight,
    required this.confidenceScore,
    required this.referenceObject,
    this.userId,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Create from JSON
  factory HeightEstimation.fromJson(Map<String, dynamic> json) {
    return HeightEstimation(
      id: json['id'],
      imageUrl: json['imageUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      estimatedHeight: json['estimatedHeight'].toDouble(),
      confidenceScore: json['confidenceScore'].toDouble(),
      referenceObject: ReferenceObject.fromJson(json['referenceObject']),
      userId: json['userId'],
      notes: json['notes'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'estimatedHeight': estimatedHeight,
      'confidenceScore': confidenceScore,
      'referenceObject': referenceObject.toJson(),
      'userId': userId,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Get height in feet and inches
  String getHeightInFeetAndInches() {
    final totalInches = estimatedHeight / 2.54;
    final feet = (totalInches / 12).floor();
    final inches = (totalInches % 12).round();
    return '$feet\' $inches"';
  }

  // Create a copy with updated fields
  HeightEstimation copyWith({
    String? id,
    String? imageUrl,
    String? thumbnailUrl,
    double? estimatedHeight,
    double? confidenceScore,
    ReferenceObject? referenceObject,
    String? userId,
    String? notes,
    DateTime? createdAt,
  }) {
    return HeightEstimation(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      estimatedHeight: estimatedHeight ?? this.estimatedHeight,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      referenceObject: referenceObject ?? this.referenceObject,
      userId: userId ?? this.userId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
