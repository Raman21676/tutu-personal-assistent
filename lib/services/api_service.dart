import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

import '../models/agent_model.dart';
import '../models/message_model.dart';
import '../models/api_config_model.dart';
import 'storage_service.dart';

/// API Service - Handles all LLM API communications
/// Supports multiple providers with retry logic and error handling
class ApiService {
  final StorageService _storage = StorageService();
  final http.Client _client = http.Client();
  
  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 1);
  
  // Timeout configuration
  static const Duration _requestTimeout = Duration(seconds: 60);

  /// Send a message to the LLM and get response
  Future<Message> sendMessage({
    required String content,
    required Agent agent,
    required List<Message> conversationHistory,
    String? systemPrompt,
  }) async {
    final config = await _storage.getApiConfig();
    
    if (config == null || config.apiKey.isEmpty) {
      throw ApiException(
        'No API key configured',
        type: ApiErrorType.noApiKey,
      );
    }

    // Build messages array
    final messages = _buildMessages(
      content: content,
      agent: agent,
      history: conversationHistory,
      systemPrompt: systemPrompt,
    );

    // Try request with retries
    Exception? lastError;
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await _sendRequest(
          config: config,
          messages: messages,
        );
        
        return Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          agentId: agent.id,
          role: 'assistant',
          content: response,
          timestamp: DateTime.now(),
        );
      } on ApiException catch (e) {
        // Don't retry on auth errors
        if (e.type == ApiErrorType.authentication) {
          rethrow;
        }
        lastError = e;
      } catch (e) {
        lastError = Exception(e.toString());
      }

      // Wait before retry with exponential backoff
      if (attempt < _maxRetries - 1) {
        final delay = _baseRetryDelay * math.pow(2, attempt);
        await Future.delayed(delay);
      }
    }

    throw lastError ?? ApiException(
      'Failed after $_maxRetries attempts',
      type: ApiErrorType.unknown,
    );
  }

  /// Build the messages array for the LLM
  List<Map<String, String>> _buildMessages({
    required String content,
    required Agent agent,
    required List<Message> history,
    String? systemPrompt,
  }) {
    final messages = <Map<String, String>>[];

    // Add system prompt
    messages.add({
      'role': 'system',
      'content': systemPrompt ?? agent.systemPrompt,
    });

    // Add conversation history (last 20 messages)
    final recentHistory = history.length > 20 
        ? history.sublist(history.length - 20) 
        : history;
    
    for (final msg in recentHistory) {
      messages.add({
        'role': msg.role,
        'content': msg.content,
      });
    }

    // Add current message
    messages.add({
      'role': 'user',
      'content': content,
    });

    return messages;
  }

  /// Send request to LLM API
  Future<String> _sendRequest({
    required ApiConfig config,
    required List<Map<String, String>> messages,
  }) async {
    switch (config.provider) {
      case LLMProvider.openai:
      case LLMProvider.openrouter:
      case LLMProvider.deepseek:
        return await _sendOpenAICompatibleRequest(config, messages);
      case LLMProvider.anthropic:
        return await _sendAnthropicRequest(config, messages);
      case LLMProvider.gemini:
        return await _sendGeminiRequest(config, messages);
      case LLMProvider.custom:
        return await _sendOpenAICompatibleRequest(config, messages);
    }
  }

  /// Send request to OpenAI-compatible API
  Future<String> _sendOpenAICompatibleRequest(
    ApiConfig config,
    List<Map<String, String>> messages,
  ) async {
    final url = '${config.baseUrl}/chat/completions';
    
    final body = jsonEncode({
      'model': config.model,
      'messages': messages,
      'temperature': 0.7,
      'max_tokens': 2000,
    });

    final response = await _client
        .post(
          Uri.parse(url),
          headers: config.headers,
          body: body,
        )
        .timeout(_requestTimeout);

    return _parseOpenAIResponse(response);
  }

  /// Send request to Anthropic API
  Future<String> _sendAnthropicRequest(
    ApiConfig config,
    List<Map<String, String>> messages,
  ) async {
    final url = '${config.baseUrl}/messages';
    
    // Extract system message
    String? systemMessage;
    final chatMessages = <Map<String, dynamic>>[];
    
    for (final msg in messages) {
      if (msg['role'] == 'system') {
        systemMessage = msg['content'];
      } else {
        chatMessages.add({
          'role': msg['role'],
          'content': msg['content'],
        });
      }
    }

    final body = jsonEncode({
      'model': config.model,
      'max_tokens': 2000,
      'system': systemMessage,
      'messages': chatMessages,
    });

    final headers = Map<String, String>.from(config.headers);
    headers['anthropic-version'] = '2023-06-01';

    final response = await _client
        .post(
          Uri.parse(url),
          headers: headers,
          body: body,
        )
        .timeout(_requestTimeout);

    return _parseAnthropicResponse(response);
  }

  /// Send request to Gemini API
  Future<String> _sendGeminiRequest(
    ApiConfig config,
    List<Map<String, String>> messages,
  ) async {
    final model = config.model;
    final url = '${config.baseUrl}/models/$model:generateContent?key=${config.apiKey}';
    
    // Convert messages to Gemini format
    final contents = <Map<String, dynamic>>[];
    for (final msg in messages) {
      if (msg['role'] != 'system') {
        contents.add({
          'role': msg['role'] == 'user' ? 'user' : 'model',
          'parts': [{'text': msg['content']}],
        });
      }
    }

    final body = jsonEncode({
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 2000,
      },
    });

    final response = await _client
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(_requestTimeout);

    return _parseGeminiResponse(response);
  }

  /// Parse OpenAI-compatible response
  String _parseOpenAIResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    }
    
    _handleErrorResponse(response);
    throw ApiException('Unknown error', type: ApiErrorType.unknown);
  }

  /// Parse Anthropic response
  String _parseAnthropicResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['content'][0]['text'] as String;
    }
    
    _handleErrorResponse(response);
    throw ApiException('Unknown error', type: ApiErrorType.unknown);
  }

  /// Parse Gemini response
  String _parseGeminiResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'] as String;
    }
    
    _handleErrorResponse(response);
    throw ApiException('Unknown error', type: ApiErrorType.unknown);
  }

  /// Handle error responses
  void _handleErrorResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;
    
    String message;
    ApiErrorType type;

    try {
      final data = jsonDecode(body);
      message = data['error']?['message'] ?? 
                data['error']?['code'] ?? 
                'HTTP $statusCode';
    } catch (_) {
      message = 'HTTP $statusCode';
    }

    switch (statusCode) {
      case 401:
      case 403:
        type = ApiErrorType.authentication;
        message = 'Invalid API key. Please check your settings.';
        break;
      case 429:
        type = ApiErrorType.rateLimit;
        message = 'Rate limit exceeded. Please try again later.';
        break;
      case 500:
      case 502:
      case 503:
        type = ApiErrorType.serverError;
        message = 'Server error. Please try again later.';
        break;
      case 400:
        type = ApiErrorType.badRequest;
        break;
      default:
        type = ApiErrorType.unknown;
    }

    throw ApiException(message, type: type, statusCode: statusCode);
  }

  /// Test API connection
  Future<bool> testConnection(ApiConfig config) async {
    try {
      final messages = [
        {'role': 'user', 'content': 'Hi'},
      ];
      
      await _sendRequest(config: config, messages: messages);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Estimate token count (rough approximation)
  int estimateTokens(String text) {
    // Rough estimate: 1 token ≈ 4 characters for English
    return (text.length / 4).ceil();
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}

/// API Exception with type information
class ApiException implements Exception {
  final String message;
  final ApiErrorType type;
  final int? statusCode;

  ApiException(this.message, {required this.type, this.statusCode});

  @override
  String toString() => 'ApiException: $message (type: $type)';
}

/// API Error Types
enum ApiErrorType {
  noApiKey,
  authentication,
  rateLimit,
  serverError,
  badRequest,
  network,
  unknown,
}

/// Extension to get user-friendly error messages
extension ApiErrorTypeExtension on ApiErrorType {
  String get displayMessage {
    switch (this) {
      case ApiErrorType.noApiKey:
        return 'Please set up your API key in settings.';
      case ApiErrorType.authentication:
        return 'Invalid API key. Please check your settings.';
      case ApiErrorType.rateLimit:
        return 'Too many requests. Please wait a moment.';
      case ApiErrorType.serverError:
        return 'Server error. Please try again later.';
      case ApiErrorType.badRequest:
        return 'Invalid request. Please try again.';
      case ApiErrorType.network:
        return 'Network error. Please check your connection.';
      case ApiErrorType.unknown:
        return 'Something went wrong. Please try again.';
    }
  }
}
