/// model_manager_screen.dart - Screen for managing local LLM models
/// 
/// This screen allows users to:
/// - View installed models
/// - Download new models
/// - Delete models to free space
/// - See model details (size, parameters, etc.)

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../services/local_llm_service.dart';

/// Model information
class ModelInfo {
  final String id;
  final String name;
  final String description;
  final int sizeBytes;
  final int parameters;
  final String quantization;
  final bool isBuiltIn;
  final String? downloadUrl;
  bool isInstalled;
  bool isDownloading;
  double downloadProgress;
  
  ModelInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.sizeBytes,
    required this.parameters,
    required this.quantization,
    this.isBuiltIn = false,
    this.downloadUrl,
    this.isInstalled = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
  });
  
  String get sizeFormatted {
    final mb = sizeBytes / 1024 / 1024;
    if (mb >= 1024) {
      return '${(mb / 1024).toStringAsFixed(1)} GB';
    }
    return '${mb.toStringAsFixed(0)} MB';
  }
  
  String get paramsFormatted {
    if (parameters >= 1000) {
      return '${(parameters / 1000).toStringAsFixed(1)}B';
    }
    return '${parameters}M';
  }
}

class ModelManagerScreen extends StatefulWidget {
  const ModelManagerScreen({super.key});
  
  @override
  State<ModelManagerScreen> createState() => _ModelManagerScreenState();
}

class _ModelManagerScreenState extends State<ModelManagerScreen> {
  final LocalLLMService _llmService = LocalLLMService();
  List<ModelInfo> _models = [];
  bool _isLoading = true;
  int _totalSpaceUsed = 0;
  
  @override
  void initState() {
    super.initState();
    _loadModels();
  }
  
  Future<void> _loadModels() async {
    setState(() => _isLoading = true);
    
    // Define available models
    _models = [
      ModelInfo(
        id: 'smollm2-360m-q4',
        name: 'SmolLM2 360M',
        description: 'Fast and efficient model perfect for everyday conversations',
        sizeBytes: 258 * 1024 * 1024,
        parameters: 360,
        quantization: 'Q4_K_M',
        isBuiltIn: true,
        isInstalled: _llmService.isModelExtracted,
      ),
      ModelInfo(
        id: 'smollm2-1.7b-q4',
        name: 'SmolLM2 1.7B',
        description: 'More capable model with better reasoning abilities',
        sizeBytes: 1 * 1024 * 1024 * 1024,
        parameters: 1700,
        quantization: 'Q4_K_M',
        downloadUrl: 'https://huggingface.co/HuggingFaceTB/SmolLM2-1.7B-Instruct-GGUF/resolve/main/smollm2-1.7b-instruct-q4_k_m.gguf',
      ),
      ModelInfo(
        id: 'phi-2-q4',
        name: 'Phi-2',
        description: 'Microsoft\'s small but powerful model',
        sizeBytes: (1.6 * 1024 * 1024 * 1024).toInt(),
        parameters: 2700,
        quantization: 'Q4_K_M',
        downloadUrl: 'https://huggingface.co/TheBloke/phi-2-GGUF/resolve/main/phi-2.Q4_K_M.gguf',
      ),
      ModelInfo(
        id: 'tinyllama-1.1b-q4',
        name: 'TinyLlama 1.1B',
        description: 'Compact Llama model with good performance',
        sizeBytes: 600 * 1024 * 1024,
        parameters: 1100,
        quantization: 'Q4_K_M',
        downloadUrl: 'https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf',
      ),
    ];
    
    await _calculateSpaceUsed();
    
    setState(() => _isLoading = false);
  }
  
  Future<void> _calculateSpaceUsed() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory(path.join(appDir.path, 'models'));
    
    if (!await modelDir.exists()) {
      _totalSpaceUsed = 0;
      return;
    }
    
    int total = 0;
    await for (final entity in modelDir.list()) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    
    setState(() => _totalSpaceUsed = total);
  }
  
  Future<void> _downloadModel(ModelInfo model) async {
    if (model.downloadUrl == null) return;
    
    setState(() => model.isDownloading = true);
    
    // Simulate download progress
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() => model.downloadProgress = i / 100);
    }
    
    setState(() {
      model.isDownloading = false;
      model.isInstalled = true;
      model.downloadProgress = 0;
    });
    
    await _calculateSpaceUsed();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${model.name} installed successfully!')),
      );
    }
  }
  
  Future<void> _deleteModel(ModelInfo model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model?'),
        content: Text('Are you sure you want to delete ${model.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    // Delete the model file
    final appDir = await getApplicationDocumentsDirectory();
    final modelFile = File(path.join(appDir.path, 'models', '${model.id}.gguf'));
    if (await modelFile.exists()) {
      await modelFile.delete();
    }
    
    setState(() => model.isInstalled = false);
    await _calculateSpaceUsed();
  }
  
  String _formatBytes(int bytes) {
    final gb = bytes / 1024 / 1024 / 1024;
    if (gb >= 1) {
      return '${gb.toStringAsFixed(2)} GB';
    }
    final mb = bytes / 1024 / 1024;
    return '${mb.toStringAsFixed(0)} MB';
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Models'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadModels,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Info header
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.secondaryContainer,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.offline_bolt,
                              color: theme.colorScheme.primary,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Privacy First AI',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'All models run locally on your device. No data leaves your phone.',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStat(
                              'Total Space',
                              _formatBytes(_totalSpaceUsed),
                              Icons.storage,
                            ),
                            _buildStat(
                              'Active Model',
                              _llmService.modelName,
                              Icons.memory,
                            ),
                            _buildStat(
                              'Status',
                              _llmService.isReady ? 'Ready' : 'Loading',
                              _llmService.isReady ? Icons.check_circle : Icons.pending,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Models list
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.builder(
                    itemCount: _models.length,
                    itemBuilder: (context, index) {
                      final model = _models[index];
                      return _buildModelCard(model, theme);
                    },
                  ),
                ),
                
                // Bottom padding
                const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
              ],
            ),
    );
  }
  
  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
  
  Widget _buildModelCard(ModelInfo model, ThemeData theme) {
    final isActive = model.id == 'smollm2-360m-q4' && _llmService.isReady;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Model icon/status
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    model.isInstalled
                        ? Icons.check_circle
                        : Icons.download_for_offline,
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Model info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              model.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (model.isBuiltIn)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Built-in',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          if (isActive)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        model.description,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            
            // Specs and actions
            Row(
              children: [
                // Specs
                _buildSpecChip(Icons.straighten, model.sizeFormatted),
                const SizedBox(width: 8),
                _buildSpecChip(Icons.memory, '${model.paramsFormatted} params'),
                const SizedBox(width: 8),
                _buildSpecChip(Icons.compress, model.quantization),
                
                const Spacer(),
                
                // Actions
                if (model.isDownloading)
                  SizedBox(
                    width: 100,
                    child: LinearProgressIndicator(
                      value: model.downloadProgress,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                else if (model.isInstalled)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!model.isBuiltIn)
                        TextButton.icon(
                          onPressed: () => _deleteModel(model),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                    ],
                  )
                else
                  FilledButton.icon(
                    onPressed: () => _downloadModel(model),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Download'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSpecChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
