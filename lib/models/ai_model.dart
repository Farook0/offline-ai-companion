import 'package:flutter/foundation.dart';

@immutable
class AIModel {
  final String id;
  final String name;
  final String version;
  final int parameters;
  final String description;
  final String format;
  final String filePath;
  final bool isAvailable;
  final Map<String, dynamic> configuration;

  const AIModel({
    required this.id,
    required this.name,
    required this.version,
    required this.parameters,
    required this.description,
    required this.format,
    required this.filePath,
    required this.isAvailable,
    this.configuration = const {},
  });

  // Qwen2.5 1.5B model (latest with complete download)
  static const AIModel llama32_1b = AIModel(
    id: 'Llama-3.2-1B-Instruct-q4f16_0-MLC',
    name: 'Llama 3.2 1B',
    version: '3.2-1B',
    parameters: 1200000000,
    description: 'Meta Llama 3.2 1B optimized with MLC-LLM for fast mobile inference with GPU acceleration.',
    format: 'MLC (q4f16_0)',
    filePath: 'Llama-3.2-1B-Instruct-q4f16_0-MLC.zip',
    isAvailable: true,
    configuration: {
      'context_length': 2048,
      'temperature': 0.7,
      'top_p': 0.9,
      'max_tokens': 50,
      'estimated_vram_bytes': 879040000,
    },
  );
  
  static const AIModel qwen2_5_1_5b = AIModel(
    id: 'Qwen2.5-1.5B-Instruct-q4f16_1-MLC',
    name: 'Qwen2.5 1.5B',
    version: '2.5-1.5B',
    parameters: 1500000000,
    description: 'Alibaba Qwen2.5 1.5B optimized with MLC-LLM for advanced reasoning and instruction following.',
    format: 'MLC (q4f16_1)',
    filePath: 'Qwen2.5-1.5B-Instruct-q4f16_1-MLC.zip',
    isAvailable: false, // Optional download
    configuration: {
      'context_length': 2048,
      'temperature': 0.7,
      'top_p': 0.9,
      'max_tokens': 50,
      'estimated_vram_bytes': 1629750000,
    },
  );

  // Get all available models (Llama 3.2 1B bundled, Qwen2.5 optional)
  static List<AIModel> get availableModels => [llama32_1b, qwen2_5_1_5b];

  // Get model by ID
  static AIModel? getById(String id) {
    try {
      return availableModels.firstWhere((model) => model.id == id);
    } catch (e) {
      return null;
    }
  }

  // Copy with modifications
  AIModel copyWith({
    String? id,
    String? name,
    String? version,
    int? parameters,
    String? description,
    String? format,
    String? filePath,
    bool? isAvailable,
    Map<String, dynamic>? configuration,
  }) {
    return AIModel(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      parameters: parameters ?? this.parameters,
      description: description ?? this.description,
      format: format ?? this.format,
      filePath: filePath ?? this.filePath,
      isAvailable: isAvailable ?? this.isAvailable,
      configuration: configuration ?? this.configuration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AIModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AIModel(id: $id, name: $name, version: $version)';
  }
}

// Simple model configuration
class ModelConfiguration {
  final int contextLength;
  final double temperature;
  final double topP;
  final int maxTokens;

  const ModelConfiguration({
    this.contextLength = 2048,
    this.temperature = 0.7,
    this.topP = 0.9,
    this.maxTokens = 150,
  });

  Map<String, dynamic> toJson() {
    return {
      'context_length': contextLength,
      'temperature': temperature,
      'top_p': topP,
      'max_tokens': maxTokens,
    };
  }

  factory ModelConfiguration.fromJson(Map<String, dynamic> json) {
    return ModelConfiguration(
      contextLength: json['context_length'] ?? 2048,
      temperature: (json['temperature'] ?? 0.7).toDouble(),
      topP: (json['top_p'] ?? 0.9).toDouble(),
      maxTokens: json['max_tokens'] ?? 150,
    );
  }
} 