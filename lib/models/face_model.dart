
/// Face Model - Represents a recognized person
/// Stores face encoding and metadata for recognition
class Face {
  final String id;
  final String personName;
  final String agentId;
  final List<double> faceEncoding;
  final String? imagePath;
  final String? version; // e.g., "with_beard", "short_hair"
  final DateTime detectedAt;
  final Map<String, dynamic>? metadata;
  final List<FaceVersion> versions;

  Face({
    required this.id,
    required this.personName,
    required this.agentId,
    required this.faceEncoding,
    this.imagePath,
    this.version,
    required this.detectedAt,
    this.metadata,
    this.versions = const [],
  });

  /// Create from JSON
  factory Face.fromJson(Map<String, dynamic> json) {
    return Face(
      id: json['id'] as String,
      personName: json['personName'] as String,
      agentId: json['agentId'] as String,
      faceEncoding: List<double>.from(
        (json['faceEncoding'] as List).map((e) => (e as num).toDouble()),
      ),
      imagePath: json['imagePath'] as String?,
      version: json['version'] as String?,
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      versions: json['versions'] != null
          ? (json['versions'] as List)
              .map((v) => FaceVersion.fromJson(v as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'personName': personName,
      'agentId': agentId,
      'faceEncoding': faceEncoding,
      'imagePath': imagePath,
      'version': version,
      'detectedAt': detectedAt.toIso8601String(),
      'metadata': metadata,
      'versions': versions.map((v) => v.toJson()).toList(),
    };
  }

  /// Get display name with version if available
  String get displayName {
    if (version != null && version!.isNotEmpty) {
      return '$personName (${_formatVersion(version!)})';
    }
    return personName;
  }

  String _formatVersion(String v) {
    return v.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  @override
  String toString() => 'Face(id: $id, name: $personName, agent: $agentId)';
}

/// Face Version - Different appearances of the same person
class FaceVersion {
  final String id;
  final String version; // e.g., "with_beard", "childhood"
  final String imagePath;
  final List<double> faceEncoding;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  FaceVersion({
    required this.id,
    required this.version,
    required this.imagePath,
    required this.faceEncoding,
    required this.createdAt,
    this.metadata,
  });

  /// Create from JSON
  factory FaceVersion.fromJson(Map<String, dynamic> json) {
    return FaceVersion(
      id: json['id'] as String,
      version: json['version'] as String,
      imagePath: json['imagePath'] as String,
      faceEncoding: List<double>.from(
        (json['faceEncoding'] as List).map((e) => (e as num).toDouble()),
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version': version,
      'imagePath': imagePath,
      'faceEncoding': faceEncoding,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Face Detection Result from ML Kit
class FaceDetectionResult {
  final String? faceId;
  final String? personName;
  final double confidence;
  final List<double>? faceEncoding;
  final Map<String, dynamic>? landmarks;
  final bool isRecognized;

  FaceDetectionResult({
    this.faceId,
    this.personName,
    required this.confidence,
    this.faceEncoding,
    this.landmarks,
    required this.isRecognized,
  });

  @override
  String toString() {
    if (isRecognized) {
      return 'FaceDetectionResult(recognized: $personName, confidence: ${confidence.toStringAsFixed(2)})';
    }
    return 'FaceDetectionResult(unrecognized, confidence: ${confidence.toStringAsFixed(2)})';
  }
}

/// Face recognition event for memory storage
class FaceRecognitionEvent {
  final String id;
  final String agentId;
  final String faceId;
  final String personName;
  final DateTime recognizedAt;
  final String? context; // Additional context about the meeting
  final String? imagePath;

  FaceRecognitionEvent({
    required this.id,
    required this.agentId,
    required this.faceId,
    required this.personName,
    required this.recognizedAt,
    this.context,
    this.imagePath,
  });

  /// Create from JSON
  factory FaceRecognitionEvent.fromJson(Map<String, dynamic> json) {
    return FaceRecognitionEvent(
      id: json['id'] as String,
      agentId: json['agentId'] as String,
      faceId: json['faceId'] as String,
      personName: json['personName'] as String,
      recognizedAt: DateTime.parse(json['recognizedAt'] as String),
      context: json['context'] as String?,
      imagePath: json['imagePath'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agentId': agentId,
      'faceId': faceId,
      'personName': personName,
      'recognizedAt': recognizedAt.toIso8601String(),
      'context': context,
      'imagePath': imagePath,
    };
  }

  /// Convert to memory content string
  String toMemoryContent() {
    final dateStr = '${recognizedAt.day}/${recognizedAt.month}/${recognizedAt.year}';
    if (context != null && context!.isNotEmpty) {
      return 'On $dateStr, I recognized $personName. Context: $context';
    }
    return 'On $dateStr, I recognized $personName';
  }
}
