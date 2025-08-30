import 'package:flutter/material.dart';
import 'package:offline_ai_companion/models/ai_model.dart';
import 'package:offline_ai_companion/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:offline_ai_companion/providers/ai_model_provider.dart';

class ModelCard extends StatelessWidget {
  final AIModel model;
  final bool isSelected;
  final VoidCallback onTap;

  const ModelCard({
    super.key,
    required this.model,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final successColor = const Color(0xFF10B981);
    
    return Consumer<AIModelProvider>(
      builder: (context, aiModelProvider, child) {
        final isCurrentlyLoading = aiModelProvider.isModelLoading && 
                                 aiModelProvider.selectedModel?.id == model.id;

    return Card(
      elevation: isSelected ? 4 : 2,
      color: isSelected 
          ? theme.colorScheme.primary.withValues(alpha: 0.1)
          : theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.model_training,
                      size: 20,
                      color: isSelected 
                          ? theme.colorScheme.onPrimary 
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                                  fontWeight: FontWeight.w600,
                                  color: isSelected 
                                      ? theme.colorScheme.primary 
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${model.version} • ${_formatParameters(model.parameters)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCurrentlyLoading
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : model.isAvailable 
                              ? successColor.withValues(alpha: 0.1)
                              : theme.colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCurrentlyLoading) ...[
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          isCurrentlyLoading 
                              ? 'Loading...' 
                              : model.isAvailable ? 'Available' : 'Not Found',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isCurrentlyLoading
                                ? theme.colorScheme.primary
                                : model.isAvailable 
                                    ? successColor 
                                    : theme.colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                model.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.storage,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    model.format,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const Spacer(),
                  if (isCurrentlyLoading)
                    Text(
                      'Loading...',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else if (model.isAvailable)
                    Text(
                      'Ready to use',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: successColor,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    Text(
                      'File missing',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  String _formatParameters(int parameters) {
    if (parameters >= 1000000000) {
      return '${(parameters / 1000000000).toStringAsFixed(1)}B';
    } else if (parameters >= 1000000) {
      return '${(parameters / 1000000).toStringAsFixed(1)}M';
    } else if (parameters >= 1000) {
      return '${(parameters / 1000).toStringAsFixed(1)}K';
    } else {
      return parameters.toString();
    }
  }
} 