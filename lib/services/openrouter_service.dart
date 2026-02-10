import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../models/api_config_model.dart';

/// OpenRouter Service - Full integration with OpenRouter API
/// Handles account, models, usage tracking, and billing
class OpenRouterService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  static const String _signupUrl = 'https://openrouter.ai/auth/signup';
  static const String _keysUrl = 'https://openrouter.ai/keys';
  static const String _creditsUrl = 'https://openrouter.ai/credits';

  final http.Client _client = http.Client();

  /// Open OpenRouter signup page
  Future<void> openSignup() async {
    final uri = Uri.parse(_signupUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Open API keys page
  Future<void> openKeysPage() async {
    final uri = Uri.parse(_keysUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Open credits/billing page
  Future<void> openCreditsPage() async {
    final uri = Uri.parse(_creditsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Validate OpenRouter API key
  Future<bool> validateKey(String apiKey) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/auth/key'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get available models from OpenRouter
  Future<List<OpenRouterModel>> getAvailableModels(String apiKey) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/models'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://tutu.app',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = (data['data'] as List)
            .map((m) => OpenRouterModel.fromJson(m as Map<String, dynamic>))
            .toList();

        // Sort by category
        models.sort((a, b) {
          final catOrder = {'Free': 0, 'Cheap': 1, 'Balanced': 2, 'Premium': 3};
          final aOrder = catOrder[a.category] ?? 4;
          final bOrder = catOrder[b.category] ?? 4;
          return aOrder.compareTo(bOrder);
        });

        return models;
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get popular/recommended models
  List<OpenRouterModel> getPopularModels(List<OpenRouterModel> allModels) {
    final popularIds = [
      'anthropic/claude-3.5-sonnet',
      'anthropic/claude-3-haiku',
      'openai/gpt-4-turbo-preview',
      'openai/gpt-3.5-turbo',
      'google/gemini-pro',
      'deepseek/deepseek-chat',
      'meta-llama/llama-3-70b-instruct',
      'mistralai/mistral-7b-instruct',
    ];

    return allModels
        .where((m) => popularIds.contains(m.id))
        .toList();
  }

  /// Get usage statistics
  Future<OpenRouterUsage?> getUsage(String apiKey) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/auth/key'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return OpenRouterUsage.fromJson(data);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get model by ID
  OpenRouterModel? getModelById(List<OpenRouterModel> models, String id) {
    try {
      return models.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Format model name for display
  String formatModelName(String modelId) {
    // Convert "anthropic/claude-3.5-sonnet" to "Claude 3.5 Sonnet"
    final parts = modelId.split('/');
    if (parts.length < 2) return modelId;

    final name = parts[1]
        .replaceAll('-', ' ')
        .replaceAll('_', ' ');

    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  /// Get provider name from model ID
  String getProviderName(String modelId) {
    final parts = modelId.split('/');
    if (parts.isEmpty) return 'Unknown';

    final provider = parts[0];
    switch (provider) {
      case 'anthropic':
        return 'Anthropic';
      case 'openai':
        return 'OpenAI';
      case 'google':
        return 'Google';
      case 'deepseek':
        return 'DeepSeek';
      case 'meta-llama':
        return 'Meta';
      case 'mistralai':
        return 'Mistral AI';
      case 'microsoft':
        return 'Microsoft';
      case 'amazon':
        return 'Amazon';
      default:
        return provider[0].toUpperCase() + provider.substring(1);
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}

/// Model categories for UI organization
class ModelCategories {
  static const String free = 'Free';
  static const String cheap = 'Cheap';
  static const String balanced = 'Balanced';
  static const String premium = 'Premium';
}

/// Usage statistics response
class UsageStats {
  final double balance;
  final double totalSpent;
  final double todaySpent;
  final int requestCount;
  final DateTime? lastRequest;

  UsageStats({
    required this.balance,
    required this.totalSpent,
    required this.todaySpent,
    required this.requestCount,
    this.lastRequest,
  });
}
