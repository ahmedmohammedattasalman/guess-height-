class ReferenceObject {
  final String id;
  final String name;
  final double knownHeight; // in cm
  final double pixelHeight; // height in pixels in the image
  final Map<String, double> boundingBox; // x, y, width, height in pixels

  ReferenceObject({
    required this.id,
    required this.name,
    required this.knownHeight,
    required this.pixelHeight,
    required this.boundingBox,
  });

  // Create from JSON
  factory ReferenceObject.fromJson(Map<String, dynamic> json) {
    return ReferenceObject(
      id: json['id'],
      name: json['name'],
      knownHeight: json['knownHeight'].toDouble(),
      pixelHeight: json['pixelHeight'].toDouble(),
      boundingBox: Map<String, double>.from(json['boundingBox']),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'knownHeight': knownHeight,
      'pixelHeight': pixelHeight,
      'boundingBox': boundingBox,
    };
  }

  // Create a copy with updated fields
  ReferenceObject copyWith({
    String? id,
    String? name,
    double? knownHeight,
    double? pixelHeight,
    Map<String, double>? boundingBox,
  }) {
    return ReferenceObject(
      id: id ?? this.id,
      name: name ?? this.name,
      knownHeight: knownHeight ?? this.knownHeight,
      pixelHeight: pixelHeight ?? this.pixelHeight,
      boundingBox: boundingBox ?? this.boundingBox,
    );
  }
}
