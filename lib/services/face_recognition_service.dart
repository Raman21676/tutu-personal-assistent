import 'dart:io';
import 'dart:math' as math;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart'
    as ml_kit_face;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../models/face_model.dart';
import '../models/memory_model.dart';
import 'storage_service.dart';
import 'rag_service.dart';

/// Face Recognition Service - Local face detection and recognition
/// Uses ML Kit for detection and custom encoding for recognition
class FaceRecognitionService {
  static final FaceRecognitionService _instance =
      FaceRecognitionService._internal();
  factory FaceRecognitionService() => _instance;
  FaceRecognitionService._internal();

  final StorageService _storage = StorageService();
  final RAGService _rag = RAGService();
  final _uuid = const Uuid();

  ml_kit_face.FaceDetector? _faceDetector;

  /// Threshold for face matching (Euclidean distance)
  static const double _matchThreshold = 0.6;

  /// Maximum stored image dimension
  static const int _maxImageSize = 512;

  /// Initialize face detector
  Future<void> initialize() async {
    if (_faceDetector != null) return;

    final options = ml_kit_face.FaceDetectorOptions(
      enableTracking: true,
      enableContours: true,
      enableClassification: true,
      performanceMode: ml_kit_face.FaceDetectorMode.accurate,
    );

    _faceDetector = ml_kit_face.FaceDetector(options: options);
  }

  /// Detect and recognize face from image file
  Future<FaceDetectionResult> recognizeFace({
    required File imageFile,
    required String agentId,
    String? context,
  }) async {
    await initialize();

    // Detect faces in image
    final faces = await _detectFaces(imageFile);

    if (faces.isEmpty) {
      return FaceDetectionResult(isRecognized: false, confidence: 0.0);
    }

    // Get the primary face (largest one)
    final face = _getPrimaryFace(faces);

    // Generate face encoding
    final encoding = await _generateFaceEncoding(face, imageFile);

    if (encoding == null) {
      return FaceDetectionResult(isRecognized: false, confidence: 0.0);
    }

    // Search for matching face in database
    final match = await _findMatchingFace(encoding, agentId);

    if (match != null) {
      // Calculate confidence
      final distance = _euclideanDistance(encoding, match.faceEncoding);
      final confidence = 1.0 - distance;

      // Save recognition event to memory
      await _saveRecognitionEvent(
        agentId: agentId,
        face: match,
        context: context,
      );

      return FaceDetectionResult(
        faceId: match.id,
        personName: match.personName,
        confidence: confidence,
        faceEncoding: encoding,
        isRecognized: true,
      );
    }

    return FaceDetectionResult(
      isRecognized: false,
      confidence: 0.0,
      faceEncoding: encoding,
    );
  }

  /// Register a new face
  Future<Face> registerFace({
    required File imageFile,
    required String personName,
    required String agentId,
    String? version,
    Map<String, dynamic>? metadata,
  }) async {
    await initialize();

    // Detect faces
    final faces = await _detectFaces(imageFile);
    if (faces.isEmpty) {
      throw Exception('No face detected in image');
    }

    final face = _getPrimaryFace(faces);
    final encoding = await _generateFaceEncoding(face, imageFile);

    if (encoding == null) {
      throw Exception('Failed to generate face encoding');
    }

    // Save compressed image
    final savedImagePath = await _saveFaceImage(imageFile, personName);

    // Create face record
    final faceRecord = Face(
      id: _uuid.v4(),
      personName: personName,
      agentId: agentId,
      faceEncoding: encoding,
      imagePath: savedImagePath,
      version: version ?? 'current',
      detectedAt: DateTime.now(),
      metadata: {...?metadata, 'landmarks': _extractLandmarks(face)},
    );

    await _storage.saveFace(faceRecord);

    // Save to memory
    await _rag.addToMemory(
      agentId: agentId,
      content: 'I learned to recognize $personName',
      type: MemoryType.faceRecognition,
      importance: 0.8,
      category: 'face_recognition',
    );

    return faceRecord;
  }

  /// Add a new version of an existing face
  Future<void> addFaceVersion({
    required String faceId,
    required File imageFile,
    required String version,
    Map<String, dynamic>? metadata,
  }) async {
    await initialize();

    final existingFace = await _storage.getFace(faceId);
    if (existingFace == null) {
      throw Exception('Face not found');
    }

    // Detect faces
    final faces = await _detectFaces(imageFile);
    if (faces.isEmpty) {
      throw Exception('No face detected in image');
    }

    final face = _getPrimaryFace(faces);
    final encoding = await _generateFaceEncoding(face, imageFile);

    if (encoding == null) {
      throw Exception('Failed to generate face encoding');
    }

    // Save compressed image
    final savedImagePath = await _saveFaceImage(
      imageFile,
      existingFace.personName,
    );

    // Create face version
    final faceVersion = FaceVersion(
      id: _uuid.v4(),
      version: version,
      imagePath: savedImagePath,
      faceEncoding: encoding,
      createdAt: DateTime.now(),
      metadata: metadata,
    );

    // Update face with new version
    final updatedVersions = [...existingFace.versions, faceVersion];
    final updatedFace = Face(
      id: existingFace.id,
      personName: existingFace.personName,
      agentId: existingFace.agentId,
      faceEncoding: existingFace.faceEncoding,
      imagePath: existingFace.imagePath,
      version: existingFace.version,
      detectedAt: existingFace.detectedAt,
      metadata: existingFace.metadata,
      versions: updatedVersions,
    );

    await _storage.saveFace(updatedFace);
  }

  /// Get all faces for an agent
  Future<List<Face>> getFacesForAgent(String agentId) async {
    return await _storage.getFacesByAgent(agentId);
  }

  /// Delete a face
  Future<void> deleteFace(String faceId) async {
    final face = await _storage.getFace(faceId);
    if (face != null && face.imagePath != null) {
      // Delete image file
      try {
        await File(face.imagePath!).delete();
      } catch (_) {
        // Ignore deletion errors
      }
    }
    await _storage.deleteFace(faceId);
  }

  /// Detect faces in image
  Future<List<ml_kit_face.Face>> _detectFaces(File imageFile) async {
    final inputImage = ml_kit_face.InputImage.fromFile(imageFile);
    return await _faceDetector!.processImage(inputImage);
  }

  /// Get primary (largest) face
  ml_kit_face.Face _getPrimaryFace(List<ml_kit_face.Face> faces) {
    return faces.reduce((a, b) {
      final aArea = a.boundingBox.width * a.boundingBox.height;
      final bArea = b.boundingBox.width * b.boundingBox.height;
      return aArea > bArea ? a : b;
    });
  }

  /// Generate face encoding from detected face
  Future<List<double>?> _generateFaceEncoding(
    ml_kit_face.Face face,
    File imageFile,
  ) async {
    try {
      // Get face landmarks
      final landmarks = face.landmarks;

      // Calculate geometric features
      final encoding = <double>[];

      // Left eye
      final leftEye = landmarks[ml_kit_face.FaceLandmarkType.leftEye]?.position;
      if (leftEye != null) {
        encoding.add(leftEye.x.toDouble());
        encoding.add(leftEye.y.toDouble());
      } else {
        encoding.addAll([0, 0]);
      }

      // Right eye
      final rightEye =
          landmarks[ml_kit_face.FaceLandmarkType.rightEye]?.position;
      if (rightEye != null) {
        encoding.add(rightEye.x.toDouble());
        encoding.add(rightEye.y.toDouble());
      } else {
        encoding.addAll([0, 0]);
      }

      // Nose base
      final noseBase =
          landmarks[ml_kit_face.FaceLandmarkType.noseBase]?.position;
      if (noseBase != null) {
        encoding.add(noseBase.x.toDouble());
        encoding.add(noseBase.y.toDouble());
      } else {
        encoding.addAll([0, 0]);
      }

      // Left mouth
      final leftMouth =
          landmarks[ml_kit_face.FaceLandmarkType.leftMouth]?.position;
      if (leftMouth != null) {
        encoding.add(leftMouth.x.toDouble());
        encoding.add(leftMouth.y.toDouble());
      } else {
        encoding.addAll([0, 0]);
      }

      // Right mouth
      final rightMouth =
          landmarks[ml_kit_face.FaceLandmarkType.rightMouth]?.position;
      if (rightMouth != null) {
        encoding.add(rightMouth.x.toDouble());
        encoding.add(rightMouth.y.toDouble());
      } else {
        encoding.addAll([0, 0]);
      }

      // Calculate distances and ratios
      if (leftEye != null && rightEye != null) {
        // Inter-eye distance
        final eyeDistance = math.sqrt(
          math.pow(rightEye.x - leftEye.x, 2) +
              math.pow(rightEye.y - leftEye.y, 2),
        );
        encoding.add(eyeDistance);

        // Eye-nose distance
        if (noseBase != null) {
          final leftEyeNose = math.sqrt(
            math.pow(noseBase.x - leftEye.x, 2) +
                math.pow(noseBase.y - leftEye.y, 2),
          );
          final rightEyeNose = math.sqrt(
            math.pow(noseBase.x - rightEye.x, 2) +
                math.pow(noseBase.y - rightEye.y, 2),
          );
          encoding.add(leftEyeNose);
          encoding.add(rightEyeNose);
          encoding.add((leftEyeNose + rightEyeNose) / 2); // Average
        } else {
          encoding.addAll([0, 0, 0]);
        }
      } else {
        encoding.addAll([0, 0, 0, 0]);
      }

      // Face dimensions
      final faceWidth = face.boundingBox.width.toDouble();
      final faceHeight = face.boundingBox.height.toDouble();
      encoding.add(faceWidth);
      encoding.add(faceHeight);
      encoding.add(faceWidth / faceHeight); // Aspect ratio

      // Head angle (if available)
      encoding.add(face.headEulerAngleY?.toDouble() ?? 0);
      encoding.add(face.headEulerAngleZ?.toDouble() ?? 0);

      // Smile probability
      encoding.add(face.smilingProbability?.toDouble() ?? 0.5);

      // Left eye open probability
      encoding.add(face.leftEyeOpenProbability?.toDouble() ?? 0.5);

      // Right eye open probability
      encoding.add(face.rightEyeOpenProbability?.toDouble() ?? 0.5);

      // Normalize encoding
      return _normalizeEncoding(encoding);
    } catch (e) {
      return null;
    }
  }

  /// Normalize encoding vector
  List<double> _normalizeEncoding(List<double> encoding) {
    final mean = encoding.reduce((a, b) => a + b) / encoding.length;
    final variance =
        encoding.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) /
        encoding.length;
    final stdDev = math.sqrt(variance);

    if (stdDev == 0) return encoding;

    return encoding.map((x) => (x - mean) / stdDev).toList();
  }

  /// Find matching face in database
  Future<Face?> _findMatchingFace(List<double> encoding, String agentId) async {
    final faces = await _storage.getFacesByAgent(agentId);

    Face? bestMatch;
    double bestDistance = double.infinity;

    for (final face in faces) {
      // Check main encoding
      double distance = _euclideanDistance(encoding, face.faceEncoding);

      // Check all versions
      for (final version in face.versions) {
        final versionDistance = _euclideanDistance(
          encoding,
          version.faceEncoding,
        );
        if (versionDistance < distance) {
          distance = versionDistance;
        }
      }

      if (distance < bestDistance && distance < _matchThreshold) {
        bestDistance = distance;
        bestMatch = face;
      }
    }

    return bestMatch;
  }

  /// Calculate Euclidean distance between two encodings
  double _euclideanDistance(List<double> a, List<double> b) {
    if (a.length != b.length) return double.infinity;

    double sum = 0;
    for (int i = 0; i < a.length; i++) {
      sum += math.pow(a[i] - b[i], 2);
    }
    return math.sqrt(sum);
  }

  /// Save face image with compression
  Future<String> _saveFaceImage(File imageFile, String personName) async {
    final appDir = await getApplicationDocumentsDirectory();
    final facesDir = Directory(
      path.join(appDir.path, 'faces', personName.replaceAll(' ', '_')),
    );
    await facesDir.create(recursive: true);

    // Read and compress image
    final bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize if too large
    if (image.width > _maxImageSize || image.height > _maxImageSize) {
      image = img.copyResize(
        image,
        width: image.width > image.height ? _maxImageSize : null,
        height: image.height >= image.width ? _maxImageSize : null,
      );
    }

    // Save as JPEG
    final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final filePath = path.join(facesDir.path, filename);
    final jpeg = img.encodeJpg(image, quality: 85);
    await File(filePath).writeAsBytes(jpeg);

    return filePath;
  }

  /// Extract landmarks for storage
  Map<String, dynamic> _extractLandmarks(ml_kit_face.Face face) {
    final landmarks = <String, Map<String, double>>{};

    face.landmarks.forEach((type, landmark) {
      if (landmark != null) {
        landmarks[type.name] = {
          'x': landmark.position.x.toDouble(),
          'y': landmark.position.y.toDouble(),
        };
      }
    });

    return {
      'landmarks': landmarks,
      'boundingBox': {
        'left': face.boundingBox.left,
        'top': face.boundingBox.top,
        'width': face.boundingBox.width,
        'height': face.boundingBox.height,
      },
    };
  }

  /// Save recognition event to memory
  Future<void> _saveRecognitionEvent({
    required String agentId,
    required Face face,
    String? context,
  }) async {
    final event = FaceRecognitionEvent(
      id: _uuid.v4(),
      agentId: agentId,
      faceId: face.id,
      personName: face.personName,
      recognizedAt: DateTime.now(),
      context: context,
    );

    await _rag.addToMemory(
      agentId: agentId,
      content: event.toMemoryContent(),
      type: MemoryType.faceRecognition,
      importance: 0.6,
      category: 'face_recognition',
      relatedFaceId: face.id,
    );
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _faceDetector?.close();
    _faceDetector = null;
  }
}
