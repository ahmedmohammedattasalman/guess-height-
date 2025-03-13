class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final double? knownHeight; // in cm
  final List<String> savedEstimationIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.knownHeight,
    List<String>? savedEstimationIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : savedEstimationIds = savedEstimationIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Create from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profileImageUrl: json['profileImageUrl'],
      knownHeight: json['knownHeight']?.toDouble(),
      savedEstimationIds: json['savedEstimationIds'] != null
          ? List<String>.from(json['savedEstimationIds'])
          : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'knownHeight': knownHeight,
      'savedEstimationIds': savedEstimationIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create a copy with updated fields
  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImageUrl,
    double? knownHeight,
    List<String>? savedEstimationIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      knownHeight: knownHeight ?? this.knownHeight,
      savedEstimationIds: savedEstimationIds ?? this.savedEstimationIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
