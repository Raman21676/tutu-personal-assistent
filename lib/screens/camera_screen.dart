import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/face_model.dart';
import '../services/face_recognition_service.dart';
import '../utils/helpers.dart';

/// Camera Screen - Face detection and recognition interface
class CameraScreen extends StatefulWidget {
  final String agentId;

  const CameraScreen({
    super.key,
    required this.agentId,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  final FaceRecognitionService _faceService = FaceRecognitionService();
  
  bool _isInitializing = true;
  bool _isProcessing = false;
  FaceDetectionResult? _detectionResult;
  List<CameraDescription> _cameras = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _isInitializing = false);
        return;
      }

      // Use front camera if available
      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      await _faceService.initialize();

      if (mounted) {
        setState(() => _isInitializing = false);
      }
    } catch (e) {
      setState(() => _isInitializing = false);
    }
  }

  Future<void> _captureAndRecognize() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final image = await _controller!.takePicture();
      final imageFile = File(image.path);

      final result = await _faceService.recognizeFace(
        imageFile: imageFile,
        agentId: widget.agentId,
      );

      setState(() {
        _detectionResult = result;
        _isProcessing = false;
      });

      if (result.isRecognized && result.personName != null) {
        _showRecognizedDialog(result);
      } else {
        _showRegistrationDialog(imageFile);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        Helpers.showSnackbar(
          context,
          message: 'Error: $e',
          isError: true,
        );
      }
    }
  }

  void _showRecognizedDialog(FaceDetectionResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Face Recognized!'),
        content: Text(
          'I recognize ${result.personName}! (Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%)',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, result);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRegistrationDialog(File imageFile) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Face Detected'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('I don\'t recognize this person. Would you like me to remember them?'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Person Name',
                hintText: 'e.g., John, Mom, Friend',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              Navigator.pop(context);
              
              try {
                await _faceService.registerFace(
                  imageFile: imageFile,
                  personName: name,
                  agentId: widget.agentId,
                );

                if (mounted) {
                  Helpers.showSnackbar(
                    context,
                    message: 'I\'ll remember $name!',
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  Helpers.showSnackbar(
                    context,
                    message: 'Failed to register: $e',
                    isError: true,
                  );
                }
              }
            },
            child: const Text('Remember'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : _controller == null || !_controller!.value.isInitialized
              ? const Center(
                  child: Text(
                    'Camera not available',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    // Camera preview
                    CameraPreview(_controller!),
                    
                    // Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withAlpha(128),
                            Colors.transparent,
                            Colors.black.withAlpha(128),
                          ],
                        ),
                      ),
                    ),
                    
                    // Header
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const Expanded(
                                child: Text(
                                  'Face Recognition',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Face frame guide
                    Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withAlpha(128),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    
                    // Instructions
                    Positioned(
                      bottom: 150,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(153),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Position face in the frame',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Capture button
                    Positioned(
                      bottom: 50,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: _isProcessing ? null : _captureAndRecognize,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                              color: _isProcessing
                                  ? Colors.grey
                                  : Colors.white.withAlpha(51),
                            ),
                            child: _isProcessing
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Icon(
                                    Icons.camera,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
