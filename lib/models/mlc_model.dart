import 'package:offline_ai_companion/models/ai_model.dart';

/// MLC-LLM optimized model definitions
class MLCModel extends AIModel {
  final String modelLib;
  final int estimatedVramBytes;
  final String quantization;
  final int contextWindowSize;
  final int prefillChunkSize;
  final Map<String, dynamic> modelConfig;

  const MLCModel({
    required super.id,
    required super.name,
    required super.description,
    required super.filename,
    required super.sizeGB,
    required this.modelLib,
    required this.estimatedVramBytes,
    required this.quantization,
    required this.contextWindowSize,
    required this.prefillChunkSize,
    required this.modelConfig,
  });

  /// Get VRAM requirement in MB
  double get vramMB => estimatedVramBytes / (1024 * 1024);

  /// Get VRAM requirement in GB
  double get vramGB => estimatedVramBytes / (1024 * 1024 * 1024);

  /// Check if device has sufficient VRAM
  bool hasInsufficientVram(int deviceVramBytes) {
    return estimatedVramBytes > deviceVramBytes;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'modelLib': modelLib,
      'estimatedVramBytes': estimatedVramBytes,
      'quantization': quantization,
      'contextWindowSize': contextWindowSize,
      'prefillChunkSize': prefillChunkSize,
      'modelConfig': modelConfig,
    };
  }

  factory MLCModel.fromJson(Map<String, dynamic> json) {
    return MLCModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      filename: json['filename'],
      sizeGB: json['sizeGB'],
      modelLib: json['modelLib'],
      estimatedVramBytes: json['estimatedVramBytes'],
      quantization: json['quantization'],
      contextWindowSize: json['contextWindowSize'],
      prefillChunkSize: json['prefillChunkSize'],
      modelConfig: json['modelConfig'] ?? {},
    );
  }
}

/// Available MLC-LLM models for the app
class MLCModels {
  // LLaMA 3.2 1B - Primary model (fast, efficient)
  static const llama32_1b = MLCModel(
    id: 'llama-3.2-1b-instruct',
    name: 'LLaMA 3.2 1B',
    description: 'Fast and efficient 1B parameter model optimized for mobile devices',
    filename: 'Llama-3.2-1B-Instruct-q4f16_0-MLC.zip',
    sizeGB: 0.58, // 581MB
    modelLib: 'llama_q4f16_0_103234372b479fcb179199b6d1b3d127',
    estimatedVramBytes: 879040000, // ~838MB
    quantization: 'q4f16_0',
    contextWindowSize: 131072,
    prefillChunkSize: 8192,
    modelConfig: {
      'hidden_size': 2048,
      'intermediate_size': 8192,
      'num_attention_heads': 32,
      'num_hidden_layers': 16,
      'vocab_size': 128256,
      'max_batch_size': 128,
      'temperature': 0.6,
      'top_p': 0.9,
    },
  );

  // Qwen2.5 0.5B - Ultra-fast model
  static const qwen25_05b = MLCModel(
    id: 'qwen2.5-0.5b-instruct',
    name: 'Qwen2.5 0.5B',
    description: 'Ultra-fast 0.5B parameter model for quick responses',
    filename: 'Qwen2.5-0.5B-Instruct-q4f16_1-MLC.zip',
    sizeGB: 0.45, // ~450MB
    modelLib: 'qwen2_q4f16_1_dbc9845947d563a3c13bf93ebf315c83',
    estimatedVramBytes: 944620000, // ~900MB
    quantization: 'q4f16_1',
    contextWindowSize: 32768,
    prefillChunkSize: 4096,
    modelConfig: {
      'hidden_size': 1024,
      'intermediate_size': 2816,
      'num_attention_heads': 16,
      'num_hidden_layers': 24,
      'vocab_size': 151936,
      'max_batch_size': 64,
      'temperature': 0.7,
      'top_p': 0.8,
    },
  );

  // Qwen2.5 1.5B - Balanced model
  static const qwen25_15b = MLCModel(
    id: 'qwen2.5-1.5b-instruct',
    name: 'Qwen2.5 1.5B',
    description: 'Balanced 1.5B parameter model with good quality and speed',
    filename: 'Qwen2.5-1.5B-Instruct-q4f16_1-MLC.zip',
    sizeGB: 1.0, // ~1GB
    modelLib: 'qwen2_q4f16_1_2e221f430380225c03990ad24c3d030e',
    estimatedVramBytes: 1629750000, // ~1.5GB
    quantization: 'q4f16_1',
    contextWindowSize: 32768,
    prefillChunkSize: 4096,
    modelConfig: {
      'hidden_size': 1536,
      'intermediate_size': 8960,
      'num_attention_heads': 12,
      'num_hidden_layers': 28,
      'vocab_size': 151936,
      'max_batch_size': 64,
      'temperature': 0.7,
      'top_p': 0.8,
    },
  );

  // TinyLlama 1.1B - Compatibility model
  static const tinyLlama_11b = MLCModel(
    id: 'tinyllama-1.1b-chat',
    name: 'TinyLlama 1.1B',
    description: 'Compact 1.1B parameter model for older devices',
    filename: 'TinyLlama-1.1B-Chat-v0.4-q4f16_1-MLC.zip',
    sizeGB: 0.42, // ~420MB
    modelLib: 'llama_q4f16_1_1bc9353beea186187c9a2b6a20202864',
    estimatedVramBytes: 697240000, // ~665MB
    quantization: 'q4f16_1',
    contextWindowSize: 2048,
    prefillChunkSize: 1024,
    modelConfig: {
      'hidden_size': 2048,
      'intermediate_size': 5632,
      'num_attention_heads': 32,
      'num_hidden_layers': 22,
      'vocab_size': 32000,
      'max_batch_size': 32,
      'temperature': 0.8,
      'top_p': 0.9,
    },
  );

  /// Get all available MLC models
  static List<MLCModel> get availableModels => [
    llama32_1b,    // Primary - fast and efficient
    qwen25_05b,    // Ultra-fast for quick responses
    qwen25_15b,    // Balanced quality/speed
    tinyLlama_11b, // Compatibility for older devices
  ];

  /// Get model by ID
  static MLCModel? getModelById(String id) {
    return availableModels.firstWhere(
      (model) => model.id == id,
      orElse: () => throw Exception('Model not found: $id'),
    );
  }

  /// Get models that fit within VRAM limit
  static List<MLCModel> getModelsForVram(int vramBytes) {
    return availableModels
        .where((model) => model.estimatedVramBytes <= vramBytes)
        .toList()
        ..sort((a, b) => a.estimatedVramBytes.compareTo(b.estimatedVramBytes));
  }

  /// Get recommended model for device
  static MLCModel getRecommendedModel({int? vramBytes, bool prioritizeSpeed = false}) {
    if (vramBytes != null) {
      final compatibleModels = getModelsForVram(vramBytes);
      if (compatibleModels.isNotEmpty) {
        return prioritizeSpeed 
            ? compatibleModels.first  // Smallest/fastest
            : compatibleModels.last;  // Largest that fits
      }
    }
    
    // Default fallback - LLaMA 3.2 1B for best balance
    return llama32_1b;
  }
}
