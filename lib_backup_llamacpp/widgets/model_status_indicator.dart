import 'package:flutter/material.dart';
import 'package:offline_ai_companion/services/llama_cpp_service.dart';

class ModelStatusIndicator extends StatelessWidget {
  final String? modelId;
  final bool isLoading;

  const ModelStatusIndicator({
    super.key,
    this.modelId,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 16,
            color: _getStatusColor(),
          ),
          const SizedBox(width: 4),
          Text(
            _getStatusText(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _getStatusColor(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (isLoading) {
      return Colors.orange;
    }
    
    if (LlamaCppService.isModelLoaded) {
      return Colors.green;
    }
    
    return Colors.grey;
  }

  IconData _getStatusIcon() {
    if (isLoading) {
      return Icons.hourglass_empty;
    }
    
    if (LlamaCppService.isModelLoaded) {
      return Icons.check_circle;
    }
    
    return Icons.info;
  }

  String _getStatusText() {
    if (isLoading) {
      return 'Loading...';
    }
    
    if (LlamaCppService.isModelLoaded) {
      final modelPath = LlamaCppService.currentModelPath;
      if (modelPath?.contains('phi-2') == true) {
        return 'Phi-2 Active';
      } else if (modelPath?.contains('tinyllama') == true) {
        return 'TinyLlama Active';
      } else {
        return 'Model Active';
      }
    }
    
    return 'Mock Mode';
  }
} 