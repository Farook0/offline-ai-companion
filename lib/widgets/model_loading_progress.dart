import 'package:flutter/material.dart';
import 'dart:async';

class ModelLoadingProgress extends StatefulWidget {
  final String modelName;
  final String currentStep;
  final double progress; // 0.0 to 1.0
  final VoidCallback? onCancel;

  const ModelLoadingProgress({
    super.key,
    required this.modelName,
    required this.currentStep,
    required this.progress,
    this.onCancel,
  });

  @override
  State<ModelLoadingProgress> createState() => _ModelLoadingProgressState();
}

class _ModelLoadingProgressState extends State<ModelLoadingProgress> {
  late Timer _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (widget.progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with model name and timer
          Row(
            children: [
              Icon(
                Icons.model_training,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loading ${widget.modelName}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Elapsed: ${_formatTime(_elapsedSeconds)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onCancel != null)
                IconButton(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close),
                  tooltip: 'Cancel loading',
                ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Progress bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.currentStep,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: widget.progress,
                backgroundColor: theme.colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
                minHeight: 8,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Estimated time remaining
          if (widget.progress > 0.1) // Only show after 10% progress
            _buildTimeEstimate(theme),
        ],
      ),
    );
  }

  Widget _buildTimeEstimate(ThemeData theme) {
    final progress = widget.progress;
    final elapsed = _elapsedSeconds;
    
    if (progress <= 0) return const SizedBox.shrink();
    
    final estimatedTotalSeconds = (elapsed / progress).round();
    final remainingSeconds = estimatedTotalSeconds - elapsed;
    
    if (remainingSeconds <= 0) return const SizedBox.shrink();
    
    final remainingMinutes = remainingSeconds ~/ 60;
    final remainingSecs = remainingSeconds % 60;
    
    String timeText;
    if (remainingMinutes > 0) {
      timeText = '~${remainingMinutes}m ${remainingSecs}s remaining';
    } else {
      timeText = '~${remainingSecs}s remaining';
    }
    
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 4),
        Text(
          timeText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}







