/// model_manager_screen.dart - Screen for viewing local LLM model information
///
/// This screen shows information about the bundled local AI model.
/// No downloads needed - the model is already included in the app!

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/local_llm_service.dart';

class ModelManagerScreen extends StatefulWidget {
  const ModelManagerScreen({super.key});

  @override
  State<ModelManagerScreen> createState() => _ModelManagerScreenState();
}

class _ModelManagerScreenState extends State<ModelManagerScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Model Information')),
      body: Consumer<LocalLLMService>(
        builder: (context, llmService, child) {
          return CustomScrollView(
            slivers: [
              // Info header
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
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
                            size: 36,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Privacy-First AI',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your AI model runs completely offline on your device. No internet needed, no data leaves your phone.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Model status card
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: llmService.isReady
                          ? Colors.green.withAlpha(77)
                          : Colors.orange.withAlpha(77),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: llmService.isReady
                                  ? Colors.green.withAlpha(51)
                                  : Colors.orange.withAlpha(51),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              llmService.isReady
                                  ? Icons.check_circle
                                  : Icons.pending,
                              color: llmService.isReady
                                  ? Colors.green
                                  : Colors.orange,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  llmService.modelName,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: llmService.isReady
                                        ? Colors.green.withAlpha(51)
                                        : Colors.orange.withAlpha(51),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        llmService.state == LLMServiceState.ready
                                            ? Icons.check_circle
                                            : llmService.state ==
                                                  LLMServiceState.loading
                                            ? Icons.hourglass_empty
                                            : Icons.info_outline,
                                        size: 14,
                                        color: llmService.isReady
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        llmService.isReady
                                            ? 'Ready to Chat'
                                            : llmService.state ==
                                                  LLMServiceState.loading
                                            ? 'Loading...'
                                            : llmService.state ==
                                                  LLMServiceState
                                                      .extractingModel
                                            ? 'Extracting Model...'
                                            : 'Initializing',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: llmService.isReady
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Model specs
                      Text(
                        'Model Specifications',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildSpecRow(
                        Icons.memory,
                        'Parameters',
                        '360 Million',
                        theme,
                      ),
                      _buildSpecRow(
                        Icons.compress,
                        'Quantization',
                        'Q4_K_M (4-bit)',
                        theme,
                      ),
                      _buildSpecRow(
                        Icons.storage,
                        'Model Size',
                        '~258 MB',
                        theme,
                      ),
                      _buildSpecRow(
                        Icons.speed,
                        'Context Length',
                        '2048 tokens',
                        theme,
                      ),
                      _buildSpecRow(
                        Icons.device_hub,
                        'Architecture',
                        'SmolLM2',
                        theme,
                      ),

                      if (llmService.isReady) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),

                        Text(
                          'Performance',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Builder(
                          builder: (context) {
                            final stats = llmService.getPerformanceStats();
                            if (stats.containsKey('totalInferences')) {
                              return Column(
                                children: [
                                  _buildSpecRow(
                                    Icons.analytics,
                                    'Avg. Tokens/sec',
                                    stats['averageTokensPerSecond'] ?? 'N/A',
                                    theme,
                                  ),
                                  _buildSpecRow(
                                    Icons.access_time,
                                    'Avg. Latency',
                                    '${stats['averageDuration'] ?? 'N/A'}',
                                    theme,
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Information card
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'About This Model',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'SmolLM2-360M is a compact AI model optimized for mobile devices. '
                        'It provides conversational abilities while using minimal device resources. '
                        'The model is pre-installed with your app - no downloads or internet connection required!',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoBullet(
                        '✓ Complete privacy - all processing on-device',
                      ),
                      _buildInfoBullet('✓ Works without internet connection'),
                      _buildInfoBullet('✓ Low memory footprint'),
                      _buildInfoBullet('✓ Fast response times'),
                    ],
                  ),
                ),
              ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSpecRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
