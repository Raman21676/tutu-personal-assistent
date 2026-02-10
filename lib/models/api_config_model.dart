/// API Configuration Model - Stores API settings for different providers
class ApiConfig {
  final LLMProvider provider;
  final String apiKey;
  final String? customEndpoint;
  final String? defaultModel;
  final Map<String, dynamic>? additionalHeaders;
  final DateTime? lastValidated;
  final bool isValid;

  ApiConfig({
    required this.provider,
    required this.apiKey,
    this.customEndpoint,
    this.defaultModel,
    this.additionalHeaders,
    this.lastValidated,
    this.isValid = false,
  });

  /// Create from JSON
  factory ApiConfig.fromJson(Map<String, dynamic> json) {
    return ApiConfig(
      provider: LLMProvider.values.byName(json['provider'] as String),
      apiKey: json['apiKey'] as String,
      customEndpoint: json['customEndpoint'] as String?,
      defaultModel: json['defaultModel'] as String?,
      additionalHeaders: json['additionalHeaders'] != null
          ? Map<String, dynamic>.from(json['additionalHeaders'] as Map)
          : null,
      lastValidated: json['lastValidated'] != null
          ? DateTime.parse(json['lastValidated'] as String)
          : null,
      isValid: json['isValid'] as bool? ?? false,
    );
  }

  /// Convert to JSON (note: apiKey should be encrypted in production)
  Map<String, dynamic> toJson() {
    return {
      'provider': provider.name,
      'apiKey': apiKey,
      'customEndpoint': customEndpoint,
      'defaultModel': defaultModel,
      'additionalHeaders': additionalHeaders,
      'lastValidated': lastValidated?.toIso8601String(),
      'isValid': isValid,
    };
  }

  /// Get the base URL for the provider
  String get baseUrl {
    if (customEndpoint != null && customEndpoint!.isNotEmpty) {
      return customEndpoint!;
    }
    return provider.defaultBaseUrl;
  }

  /// Get headers for API requests
  Map<String, String> get headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
    
    // Add provider-specific headers
    switch (provider) {
      case LLMProvider.openrouter:
        headers['HTTP-Referer'] = 'https://tutu.app';
        headers['X-Title'] = 'TuTu AI App';
        break;
      case LLMProvider.anthropic:
        headers['x-api-key'] = apiKey;
        headers.remove('Authorization');
        break;
      default:
        break;
    }
    
    // Add custom headers
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders!.map(
        (key, value) => MapEntry(key, value.toString()),
      ));
    }
    
    return headers;
  }

  /// Get the default model for this provider
  String get model => defaultModel ?? provider.defaultModel;

  /// Create a copy with updated fields
  ApiConfig copyWith({
    LLMProvider? provider,
    String? apiKey,
    String? customEndpoint,
    String? defaultModel,
    Map<String, dynamic>? additionalHeaders,
    DateTime? lastValidated,
    bool? isValid,
  }) {
    return ApiConfig(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      customEndpoint: customEndpoint ?? this.customEndpoint,
      defaultModel: defaultModel ?? this.defaultModel,
      additionalHeaders: additionalHeaders ?? this.additionalHeaders,
      lastValidated: lastValidated ?? this.lastValidated,
      isValid: isValid ?? this.isValid,
    );
  }

  @override
  String toString() =>
      'ApiConfig(provider: ${provider.displayName}, model: $model, valid: $isValid)';
}

/// LLM Provider Enum
enum LLMProvider {
  openai,
  anthropic,
  gemini,
  deepseek,
  openrouter,
  custom;

  String get displayName {
    switch (this) {
      case LLMProvider.openai:
        return 'OpenAI';
      case LLMProvider.anthropic:
        return 'Anthropic (Claude)';
      case LLMProvider.gemini:
        return 'Google Gemini';
      case LLMProvider.deepseek:
        return 'DeepSeek';
      case LLMProvider.openrouter:
        return 'OpenRouter';
      case LLMProvider.custom:
        return 'Custom Provider';
    }
  }

  String get defaultBaseUrl {
    switch (this) {
      case LLMProvider.openai:
        return 'https://api.openai.com/v1';
      case LLMProvider.anthropic:
        return 'https://api.anthropic.com/v1';
      case LLMProvider.gemini:
        return 'https://generativelanguage.googleapis.com/v1';
      case LLMProvider.deepseek:
        return 'https://api.deepseek.com/v1';
      case LLMProvider.openrouter:
        return 'https://openrouter.ai/api/v1';
      case LLMProvider.custom:
        return '';
    }
  }

  String get defaultModel {
    switch (this) {
      case LLMProvider.openai:
        return 'gpt-4-turbo-preview';
      case LLMProvider.anthropic:
        return 'claude-3-sonnet-20240229';
      case LLMProvider.gemini:
        return 'gemini-pro';
      case LLMProvider.deepseek:
        return 'deepseek-chat';
      case LLMProvider.openrouter:
        return 'anthropic/claude-3.5-sonnet';
      case LLMProvider.custom:
        return '';
    }
  }

  String get apiKeyUrl {
    switch (this) {
      case LLMProvider.openai:
        return 'https://platform.openai.com/api-keys';
      case LLMProvider.anthropic:
        return 'https://console.anthropic.com/settings/keys';
      case LLMProvider.gemini:
        return 'https://makersuite.google.com/app/apikey';
      case LLMProvider.deepseek:
        return 'https://platform.deepseek.com/api_keys';
      case LLMProvider.openrouter:
        return 'https://openrouter.ai/keys';
      case LLMProvider.custom:
        return '';
    }
  }

  List<String> get availableModels {
    switch (this) {
      case LLMProvider.openai:
        return [
          'gpt-4-turbo-preview',
          'gpt-4',
          'gpt-3.5-turbo',
        ];
      case LLMProvider.anthropic:
        return [
          'claude-3-opus-20240229',
          'claude-3-sonnet-20240229',
          'claude-3-haiku-20240307',
        ];
      case LLMProvider.gemini:
        return [
          'gemini-pro',
          'gemini-pro-vision',
        ];
      case LLMProvider.deepseek:
        return [
          'deepseek-chat',
          'deepseek-coder',
        ];
      case LLMProvider.openrouter:
        return []; // Dynamically fetched from API
      case LLMProvider.custom:
        return [];
    }
  }
}

/// OpenRouter specific model information
class OpenRouterModel {
  final String id;
  final String name;
  final String description;
  final Pricing pricing;
  final String? contextLength;

  OpenRouterModel({
    required this.id,
    required this.name,
    required this.description,
    required this.pricing,
    this.contextLength,
  });

  factory OpenRouterModel.fromJson(Map<String, dynamic> json) {
    return OpenRouterModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['id'] as String,
      description: json['description'] as String? ?? '',
      pricing: Pricing.fromJson(json['pricing'] as Map<String, dynamic>? ?? {}),
      contextLength: json['context_length']?.toString(),
    );
  }

  String get displayPrice {
    if (pricing.prompt == 0 && pricing.completion == 0) {
      return 'Free';
    }
    final avgPrice = ((pricing.prompt + pricing.completion) / 2 * 1000)
        .toStringAsFixed(2);
    return '\$$avgPrice per 1K tokens';
  }

  String get category {
    final price = (pricing.prompt + pricing.completion) / 2 * 1000;
    if (price == 0) return 'Free';
    if (price < 0.5) return 'Cheap';
    if (price < 2) return 'Balanced';
    return 'Premium';
  }
}

class Pricing {
  final double prompt;
  final double completion;

  Pricing({required this.prompt, required this.completion});

  factory Pricing.fromJson(Map<String, dynamic> json) {
    return Pricing(
      prompt: (json['prompt'] as num?)?.toDouble() ?? 0.0,
      completion: (json['completion'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// OpenRouter usage statistics
class OpenRouterUsage {
  final double balance;
  final double totalUsage;
  final double todayUsage;
  final String? currency;
  final DateTime? lastUpdated;

  OpenRouterUsage({
    required this.balance,
    required this.totalUsage,
    required this.todayUsage,
    this.currency,
    this.lastUpdated,
  });

  factory OpenRouterUsage.fromJson(Map<String, dynamic> json) {
    return OpenRouterUsage(
      balance: (json['data']?['limit']?['limit'] as num? ?? 0).toDouble() -
          (json['data']?['usage'] as num? ?? 0).toDouble(),
      totalUsage: (json['data']?['usage'] as num? ?? 0).toDouble(),
      todayUsage: 0.0, // Calculated separately if needed
      currency: json['data']?['limit']?['currency'] as String? ?? 'USD',
      lastUpdated: DateTime.now(),
    );
  }

  bool get isLowBalance => balance < 1.0;

  String get formattedBalance => '\$${balance.toStringAsFixed(2)}';
}
