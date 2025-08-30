import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:offline_ai_companion/models/mlc_model.dart';

/// MLC-LLM service for high-performance AI inference
class MLCService {
  static const MethodChannel _channel = MethodChannel('mlc_llm_channel');
  
  bool _isInitialized = false;
  MLCModel? _currentModel;
  Function(String)? _progressCallback;
  
  // Device capabilities
  int? _deviceVramBytes;
  bool? _supportsGPU;
  String? _deviceInfo;

  /// Initialize MLC-LLM runtime
  Future<void> initialize() async {
    try {
      print('MLCService: Initializing TVM runtime...');
      
      final result = await _channel.invokeMethod('initialize');
      if (result['success'] == true) {
        _isInitialized = true;
        
        // Get device capabilities
        await _queryDeviceCapabilities();
        
        print('MLCService: ✅ TVM runtime initialized successfully');
        _progressCallback?.call('✅ MLC-LLM runtime initialized');
      } else {
        throw Exception('Failed to initialize TVM runtime: ${result['error']}');
      }
    } catch (e) {
      print('MLCService: ❌ Failed to initialize: $e');
      _progressCallback?.call('❌ Failed to initialize MLC-LLM: $e');
      rethrow;
    }
  }

  /// Query device GPU and VRAM capabilities
  Future<void> _queryDeviceCapabilities() async {
    try {
      final result = await _channel.invokeMethod('getDeviceCapabilities');
      
      _deviceVramBytes = result['vramBytes'];
      _supportsGPU = result['supportsGPU'] ?? false;
      _deviceInfo = result['deviceInfo'];
      
      print('MLCService: Device Info - GPU: $_supportsGPU, VRAM: ${(_deviceVramBytes ?? 0) ~/ (1024 * 1024)}MB');
      _progressCallback?.call('📱 Device: ${_supportsGPU ? 'GPU' : 'CPU'}-accelerated, ${(_deviceVramBytes ?? 0) ~/ (1024 * 1024)}MB VRAM');
    } catch (e) {
      print('MLCService: Warning - Could not query device capabilities: $e');
      // Continue without GPU info
    }
  }

  /// Load MLC model (ZIP extraction + binary loading)
  Future<bool> loadModel(MLCModel model) async {
    if (!_isInitialized) {
      throw Exception('MLC service not initialized');
    }

    try {
      print('MLCService: Loading model: ${model.name}');
      _progressCallback?.call('🔄 Loading ${model.name}...');

      // Check VRAM requirements
      if (_deviceVramBytes != null && model.hasInsufficientVram(_deviceVramBytes!)) {
        _progressCallback?.call('⚠️ Warning: Model requires ${model.vramMB.toInt()}MB VRAM, device has ${(_deviceVramBytes! / 1024 / 1024).toInt()}MB');
      }

      // Step 1: Extract model ZIP if needed
      _progressCallback?.call('📦 Extracting model files...');
      final extractResult = await _channel.invokeMethod('extractModel', {
        'modelPath': model.filename,
        'modelId': model.id,
      });

      if (extractResult['success'] != true) {
        throw Exception('Failed to extract model: ${extractResult['error']}');
      }

      // Step 2: Load model configuration
      _progressCallback?.call('⚙️ Loading model configuration...');
      final configResult = await _channel.invokeMethod('loadModelConfig', {
        'modelId': model.id,
        'modelLib': model.modelLib,
        'config': model.modelConfig,
      });

      if (configResult['success'] != true) {
        throw Exception('Failed to load model config: ${configResult['error']}');
      }

      // Step 3: Initialize TVM model
      _progressCallback?.call('🧠 Initializing AI model...');
      final loadResult = await _channel.invokeMethod('loadTVMModel', {
        'modelId': model.id,
        'useGPU': _supportsGPU ?? false,
        'maxVramBytes': _deviceVramBytes,
      });

      if (loadResult['success'] == true) {
        _currentModel = model;
        print('MLCService: ✅ Model loaded successfully: ${model.name}');
        _progressCallback?.call('✅ ${model.name} ready!');
        return true;
      } else {
        throw Exception('Failed to load TVM model: ${loadResult['error']}');
      }
    } catch (e) {
      print('MLCService: ❌ Failed to load model: $e');
      _progressCallback?.call('❌ Failed to load ${model.name}: $e');
      return false;
    }
  }

  /// Generate AI response using MLC inference
  Future<String> generateResponse(
    String prompt, {
    int maxTokens = 150,
    double temperature = 0.7,
    double topP = 0.9,
    int topK = 40,
  }) async {
    if (!_isInitialized || _currentModel == null) {
      throw Exception('MLC service not initialized or no model loaded');
    }

    try {
      print('MLCService: Generating response for prompt: ${prompt.substring(0, prompt.length.clamp(0, 50))}...');

      // Format prompt with system message for LLaMA-3.2-Instruct
      final formattedPrompt = _formatPromptWithSystem(prompt);

      final result = await _channel.invokeMethod('generateResponse', {
        'prompt': formattedPrompt,
        'maxTokens': maxTokens,
        'temperature': temperature,
        'topP': topP,
        'topK': topK,
        'modelId': _currentModel!.id,
      });

      if (result['success'] == true) {
        final response = result['response'] as String;
        print('MLCService: ✅ Generated response (${response.length} chars)');
        return response;
      } else {
        throw Exception('Failed to generate response: ${result['error']}');
      }
    } catch (e) {
      print('MLCService: ❌ Failed to generate response: $e');
      rethrow;
    }
  }

  /// Format prompt with system message for LLaMA-3.2-Instruct
  String _formatPromptWithSystem(String userPrompt) {
    const systemPrompt = '''<|begin_of_text|><|start_header_id|>system<|end_header_id|>

You are a helpful, respectful, and honest AI assistant with broad knowledge across many domains. You can answer questions about any subject including:

- Science and Technology (physics, chemistry, biology, computer science, engineering)
- Mathematics (algebra, calculus, statistics, geometry)
- History and Politics (world history, current events, political systems)
- Literature and Arts (books, poetry, music, visual arts, film)
- Philosophy and Religion (ethics, logic, world religions, moral questions)
- Business and Economics (finance, marketing, entrepreneurship, economics)
- Health and Medicine (anatomy, nutrition, mental health, medical conditions)
- Geography and Travel (countries, cultures, travel tips, world geography)
- Sports and Recreation (games, fitness, outdoor activities, sports history)
- Personal Development (self-improvement, relationships, career advice)
- And any other domain or topic the user asks about

Key guidelines:
- Be helpful and informative across all domains
- Be concise but thorough in your explanations
- If you're unsure about something, say so honestly
- Don't make up information - stick to what you know
- Be respectful and professional in all interactions
- Focus on being useful to the user regardless of the topic
- Provide accurate, well-reasoned responses to any question
- Use clear, accessible language appropriate to the subject

<|eot_id|><|start_header_id|>user<|end_header_id|>

''';

    const assistantPrefix = '<|eot_id|><|start_header_id|>assistant<|end_header_id|>

';

    return '$systemPrompt$userPrompt$assistantPrefix';
  }

  /// Stream response generation for real-time updates
  Stream<String> generateResponseStream(
    String prompt, {
    int maxTokens = 150,
    double temperature = 0.7,
    double topP = 0.9,
    int topK = 40,
  }) async* {
    if (!_isInitialized || _currentModel == null) {
      throw Exception('MLC service not initialized or no model loaded');
    }

    try {
      print('MLCService: Starting streaming response...');
      
      // Set up event channel for streaming
      const EventChannel streamChannel = EventChannel('mlc_llm_stream');
      
      // Format prompt with system message for LLaMA-3.2-Instruct
      final formattedPrompt = _formatPromptWithSystem(prompt);
      
      // Start streaming inference
      await _channel.invokeMethod('startStreamingResponse', {
        'prompt': formattedPrompt,
        'maxTokens': maxTokens,
        'temperature': temperature,
        'topP': topP,
        'topK': topK,
        'modelId': _currentModel!.id,
      });

      // Listen for tokens
      await for (final event in streamChannel.receiveBroadcastStream()) {
        if (event['type'] == 'token') {
          yield event['token'] as String;
        } else if (event['type'] == 'done') {
          break;
        } else if (event['type'] == 'error') {
          throw Exception('Streaming error: ${event['error']}');
        }
      }
    } catch (e) {
      print('MLCService: ❌ Streaming failed: $e');
      rethrow;
    }
  }

  /// Unload current model to free memory
  Future<void> unloadModel() async {
    if (_currentModel != null) {
      try {
        await _channel.invokeMethod('unloadModel', {
          'modelId': _currentModel!.id,
        });
        
        print('MLCService: ✅ Model unloaded: ${_currentModel!.name}');
        _currentModel = null;
      } catch (e) {
        print('MLCService: ⚠️ Error unloading model: $e');
      }
    }
  }

  /// Get memory usage statistics
  Future<Map<String, dynamic>> getMemoryStats() async {
    try {
      final result = await _channel.invokeMethod('getMemoryStats');
      return {
        'vramUsed': result['vramUsed'] ?? 0,
        'vramTotal': result['vramTotal'] ?? 0,
        'systemRam': result['systemRam'] ?? 0,
        'modelSize': result['modelSize'] ?? 0,
      };
    } catch (e) {
      print('MLCService: Warning - Could not get memory stats: $e');
      return {};
    }
  }

  /// Cleanup and dispose service
  Future<void> dispose() async {
    await unloadModel();
    
    if (_isInitialized) {
      try {
        await _channel.invokeMethod('dispose');
        _isInitialized = false;
        print('MLCService: ✅ Service disposed');
      } catch (e) {
        print('MLCService: ⚠️ Error disposing service: $e');
      }
    }
  }

  /// Set progress callback for loading updates
  void setProgressCallback(Function(String) callback) {
    _progressCallback = callback;
  }

  /// Get current model info
  MLCModel? get currentModel => _currentModel;
  
  /// Check if service is ready
  bool get isReady => _isInitialized && _currentModel != null;
  
  /// Get device capabilities
  Map<String, dynamic> get deviceCapabilities => {
    'vramBytes': _deviceVramBytes,
    'supportsGPU': _supportsGPU,
    'deviceInfo': _deviceInfo,
  };

  /// Get recommended models for this device
  List<MLCModel> get recommendedModels {
    return MLCModels.getModelsForVram(_deviceVramBytes ?? 2000000000); // Default 2GB
  }
}
