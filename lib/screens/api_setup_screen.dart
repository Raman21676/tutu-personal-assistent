import 'package:flutter/material.dart';
import '../models/api_config_model.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../services/openrouter_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// API Setup Screen - Configure LLM providers
class ApiSetupScreen extends StatefulWidget {
  const ApiSetupScreen({super.key});

  @override
  State<ApiSetupScreen> createState() => _ApiSetupScreenState();
}

class _ApiSetupScreenState extends State<ApiSetupScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  final ApiService _apiService = ApiService();
  final OpenRouterService _openRouterService = OpenRouterService();
  
  late TabController _tabController;
  
  LLMProvider _selectedProvider = LLMProvider.openrouter;
  final _apiKeyController = TextEditingController();
  final _customEndpointController = TextEditingController();
  String? _selectedModel;
  
  bool _isLoading = false;
  bool _isTesting = false;
  String? _testResult;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExistingConfig();
  }

  Future<void> _loadExistingConfig() async {
    final config = await _storage.getApiConfig();
    if (config != null) {
      setState(() {
        _selectedProvider = config.provider;
        _apiKeyController.text = config.apiKey;
        _customEndpointController.text = config.customEndpoint ?? '';
        _selectedModel = config.defaultModel;
      });
    }
  }

  Future<void> _saveConfig() async {
    if (_apiKeyController.text.trim().isEmpty) {
      Helpers.showSnackbar(
        context,
        message: 'Please enter an API key',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final config = ApiConfig(
        provider: _selectedProvider,
        apiKey: _apiKeyController.text.trim(),
        customEndpoint: _customEndpointController.text.trim().isEmpty
            ? null
            : _customEndpointController.text.trim(),
        defaultModel: _selectedModel,
      );

      await _storage.saveApiConfig(config);
      await _storage.setOnboardingCompleted(true);

      if (mounted) {
        Helpers.showSnackbar(
          context,
          message: 'API configuration saved successfully!',
        );
        Navigator.pushReplacementNamed(context, Routes.home);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackbar(
          context,
          message: 'Failed to save configuration: $e',
          isError: true,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testConnection() async {
    if (_apiKeyController.text.trim().isEmpty) {
      Helpers.showSnackbar(
        context,
        message: 'Please enter an API key first',
        isError: true,
      );
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final config = ApiConfig(
        provider: _selectedProvider,
        apiKey: _apiKeyController.text.trim(),
        customEndpoint: _customEndpointController.text.trim().isEmpty
            ? null
            : _customEndpointController.text.trim(),
      );

      final isValid = await _apiService.testConnection(config);

      setState(() {
        _isTesting = false;
        _testResult = isValid ? 'Connection successful!' : 'Connection failed. Please check your API key.';
      });
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testResult = 'Error: $e';
      });
    }
  }

  void _openProviderUrl() {
    final url = _selectedProvider.apiKeyUrl;
    if (url.isNotEmpty) {
      _openRouterService.openSignup();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _apiKeyController.dispose();
    _customEndpointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Setup'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Manual Setup'),
            Tab(text: 'OpenRouter'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildManualSetupTab(),
          _buildOpenRouterTab(),
        ],
      ),
    );
  }

  Widget _buildManualSetupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider selection
          DropdownButtonFormField<LLMProvider>(
            initialValue: _selectedProvider,
            decoration: const InputDecoration(
              labelText: 'Provider',
              prefixIcon: Icon(Icons.cloud),
            ),
            items: LLMProvider.values.map((provider) {
              return DropdownMenuItem(
                value: provider,
                child: Text(provider.displayName),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedProvider = value;
                  _selectedModel = null;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          
          // API Key input
          TextFormField(
            controller: _apiKeyController,
            decoration: InputDecoration(
              labelText: 'API Key',
              prefixIcon: const Icon(Icons.key),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _obscureKey ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscureKey = !_obscureKey);
                    },
                  ),
                ],
              ),
            ),
            obscureText: _obscureKey,
          ),
          const SizedBox(height: 8),
          
          // Help text
          TextButton.icon(
            onPressed: _openProviderUrl,
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text('Get ${_selectedProvider.displayName} API Key'),
          ),
          const SizedBox(height: 16),
          
          // Model selection (if available)
          if (_selectedProvider.availableModels.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              initialValue: _selectedModel,
              decoration: const InputDecoration(
                labelText: 'Model (Optional)',
                prefixIcon: Icon(Icons.model_training),
              ),
              hint: const Text('Default model'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Default (Recommended)'),
                ),
                ..._selectedProvider.availableModels.map((model) {
                  return DropdownMenuItem(
                    value: model,
                    child: Text(model),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _selectedModel = value);
              },
            ),
            const SizedBox(height: 16),
          ],
          
          // Custom endpoint (for custom provider)
          if (_selectedProvider == LLMProvider.custom) ...[
            TextFormField(
              controller: _customEndpointController,
              decoration: const InputDecoration(
                labelText: 'Custom Endpoint URL',
                prefixIcon: Icon(Icons.link),
                hintText: 'https://api.example.com/v1',
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Test connection button
          OutlinedButton.icon(
            onPressed: _isTesting ? null : _testConnection,
            icon: _isTesting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.network_check),
            label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
          ),
          
          // Test result
          if (_testResult != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _testResult!.contains('successful')
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _testResult!.contains('successful')
                      ? Colors.green.shade200
                      : Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _testResult!.contains('successful')
                        ? Icons.check_circle
                        : Icons.error,
                    color: _testResult!.contains('successful')
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _testResult!,
                      style: TextStyle(
                        color: _testResult!.contains('successful')
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveConfig,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Configuration'),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Skip button
          Center(
            child: TextButton(
              onPressed: () {
                _storage.setOnboardingCompleted(true);
                Navigator.pushReplacementNamed(context, Routes.home);
              },
              child: const Text('Skip for now'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenRouterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.lightbulb,
                    size: 48,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Why OpenRouter?',
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'OpenRouter provides access to multiple AI models (GPT-4, Claude, Gemini, etc.) through a single API. It\'s perfect if you want flexibility.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Steps
          Text(
            'Get Started in 3 Steps:',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildStep(
            number: '1',
            title: 'Create an Account',
            description: 'Sign up for a free OpenRouter account',
            buttonText: 'Sign Up',
            onPressed: () => _openRouterService.openSignup(),
          ),
          const SizedBox(height: 16),
          
          _buildStep(
            number: '2',
            title: 'Get API Key',
            description: 'Create a new API key in your OpenRouter dashboard',
            buttonText: 'Get API Key',
            onPressed: () => _openRouterService.openKeysPage(),
          ),
          const SizedBox(height: 16),
          
          _buildStep(
            number: '3',
            title: 'Add Credits (Optional)',
            description: 'Add credits to use premium models, or use free models',
            buttonText: 'Add Credits',
            onPressed: () => _openRouterService.openCreditsPage(),
          ),
          
          const SizedBox(height: 32),
          
          // Continue button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _tabController.animateTo(0);
                setState(() => _selectedProvider = LLMProvider.openrouter);
              },
              child: const Text('I Have My API Key'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: context.colors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onPressed,
                child: Text(buttonText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
