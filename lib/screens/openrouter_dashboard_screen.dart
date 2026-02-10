import 'package:flutter/material.dart';
import '../models/api_config_model.dart';
import '../services/storage_service.dart';
import '../services/openrouter_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// OpenRouter Dashboard - Balance, usage, and model selection
class OpenRouterDashboardScreen extends StatefulWidget {
  const OpenRouterDashboardScreen({super.key});

  @override
  State<OpenRouterDashboardScreen> createState() =>
      _OpenRouterDashboardScreenState();
}

class _OpenRouterDashboardScreenState extends State<OpenRouterDashboardScreen> {
  final StorageService _storage = StorageService();
  final OpenRouterService _openRouterService = OpenRouterService();

  ApiConfig? _config;
  OpenRouterUsage? _usage;
  List<OpenRouterModel> _models = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final config = await _storage.getApiConfig();
      if (config == null || config.provider != LLMProvider.openrouter) {
        setState(() {
          _error = 'OpenRouter is not configured. Please set up your API key first.';
          _isLoading = false;
        });
        return;
      }

      _config = config;

      // Load usage and models in parallel
      final results = await Future.wait([
        _openRouterService.getUsage(config.apiKey),
        _openRouterService.getAvailableModels(config.apiKey),
      ]);

      setState(() {
        _usage = results[0] as OpenRouterUsage?;
        _models = results[1] as List<OpenRouterModel>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  void _openTopUp() {
    _openRouterService.openCreditsPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenRouter Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, Routes.apiSetup);
              },
              child: const Text('Configure API'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        children: [
          // Balance Card
          _buildBalanceCard(),
          
          // Quick Actions
          _buildQuickActions(),
          
          // Popular Models
          _buildPopularModels(),
          
          // All Models
          _buildAllModels(),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final balance = _usage?.balance ?? 0.0;
    final isLowBalance = balance < 1.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isLowBalance
            ? LinearGradient(
                colors: [Colors.orange.shade400, Colors.red.shade400],
              )
            : const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isLowBalance ? Colors.red : Colors.blue).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              if (isLowBalance)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Low Balance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (isLowBalance)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openTopUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                ),
                child: const Text('Add Credits'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              icon: Icons.account_balance_wallet,
              label: 'Top Up',
              onTap: _openTopUp,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              icon: Icons.key,
              label: 'API Keys',
              onTap: () => _openRouterService.openKeysPage(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              icon: Icons.receipt,
              label: 'Billing',
              onTap: () => _openRouterService.openCreditsPage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(
                icon,
                color: context.colors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: context.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularModels() {
    final popularModels = _openRouterService.getPopularModels(_models);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            'Popular Models',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: popularModels.length,
            itemBuilder: (context, index) {
              final model = popularModels[index];
              return _buildModelCard(model, isCompact: true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAllModels() {
    // Group models by category
    final groupedModels = <String, List<OpenRouterModel>>{};
    for (final model in _models) {
      groupedModels.putIfAbsent(model.category, () => []).add(model);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            'All Models',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...groupedModels.entries.map((entry) {
          return ExpansionTile(
            title: Text(
              '${entry.key} (${entry.value.length})',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            children: entry.value.map((model) {
              return _buildModelListTile(model);
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildModelCard(OpenRouterModel model, {bool isCompact = false}) {
    final isSelected = _config?.defaultModel == model.id;

    return Container(
      width: isCompact ? 180 : double.infinity,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        color: isSelected
            ? context.colors.primary.withOpacity(0.1)
            : null,
        child: InkWell(
          onTap: () {
            // Set as default model
            if (_config != null) {
              final updatedConfig = _config!.copyWith(defaultModel: model.id);
              _storage.saveApiConfig(updatedConfig);
              setState(() => _config = updatedConfig);
              Helpers.showSnackbar(
                context,
                message: '${model.name} set as default',
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _openRouterService.formatModelName(model.id),
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: context.colors.primary,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _openRouterService.getProviderName(model.id),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurface.withOpacity(0.6),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(model.category)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    model.displayPrice,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getCategoryColor(model.category),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModelListTile(OpenRouterModel model) {
    final isSelected = _config?.defaultModel == model.id;

    return ListTile(
      title: Text(_openRouterService.formatModelName(model.id)),
      subtitle: Text(_openRouterService.getProviderName(model.id)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getCategoryColor(model.category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              model.displayPrice,
              style: TextStyle(
                fontSize: 12,
                color: _getCategoryColor(model.category),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.check_circle,
              color: context.colors.primary,
              size: 20,
            ),
          ],
        ],
      ),
      onTap: () {
        if (_config != null) {
          final updatedConfig = _config!.copyWith(defaultModel: model.id);
          _storage.saveApiConfig(updatedConfig);
          setState(() => _config = updatedConfig);
          Helpers.showSnackbar(
            context,
            message: '${model.name} set as default',
          );
        }
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Free':
        return Colors.green;
      case 'Cheap':
        return Colors.blue;
      case 'Balanced':
        return Colors.orange;
      case 'Premium':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
