import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:offline_ai_companion/providers/ai_model_provider.dart';
import 'package:offline_ai_companion/models/ai_model.dart';
import 'package:offline_ai_companion/widgets/model_card.dart';
import 'package:offline_ai_companion/widgets/model_loading_progress.dart';

class ModelsScreen extends StatefulWidget {
  const ModelsScreen({super.key});

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Model'),
        actions: [
          Consumer<AIModelProvider>(
            builder: (context, aiModelProvider, child) {
              return IconButton(
                onPressed: aiModelProvider.isLoading 
                    ? null 
                    : () => aiModelProvider.refreshModels(),
                icon: aiModelProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Refresh model',
              );
            },
          ),
        ],
      ),
      body: Consumer<AIModelProvider>(
        builder: (context, aiModelProvider, child) {
          if (aiModelProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading Qwen2...'),
                ],
              ),
            );
          }

          if (aiModelProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading model',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    aiModelProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => aiModelProvider.refreshModels(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Show Qwen2 model card
                  ModelCard(
                    model: AIModel.qwen2_5,
                    isSelected: aiModelProvider.selectedModel?.id == AIModel.qwen2_5.id,
                    onTap: () => _selectModel(context, aiModelProvider, AIModel.qwen2_5),
                  ),
                  const SizedBox(height: 24),
                  
                  // Model information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About Qwen2 1.5B',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Qwen2 1.5B is Alibaba\'s efficient language model optimized for mobile devices. '
                            'It provides fast and quality responses for everyday conversations while using minimal resources.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.speed,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Fast response times',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.memory,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Low memory usage (~1.2GB)',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.battery_saver,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Battery efficient',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Show loading dialog when model is loading
              if (aiModelProvider.isModelLoading)
                _buildLoadingOverlay(context, aiModelProvider),
            ],
          );
        },
      ),
    );
  }

  Future<void> _selectModel(
    BuildContext context,
    AIModelProvider aiModelProvider,
    AIModel model,
  ) async {
    if (!model.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${model.name} is not available. Please check if the model file exists.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    try {
      await aiModelProvider.selectModel(model);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully loaded ${model.name}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load ${model.name}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildLoadingOverlay(BuildContext context, AIModelProvider aiModelProvider) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ModelLoadingProgress(
            modelName: aiModelProvider.selectedModel?.name ?? 'Qwen2',
            currentStep: aiModelProvider.loadingStep,
            progress: aiModelProvider.loadingProgress,
            onCancel: () {
              // TODO: Implement cancel functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cancel functionality coming soon!'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
} 