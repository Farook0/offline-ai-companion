import 'package:flutter/services.dart';

/// Android MLC Plugin for native MLC-LLM integration
/// Connects Flutter to the native Android MLC implementation
class AndroidMLCPlugin {
  static const MethodChannel _channel = MethodChannel('mlc_llm_channel');
  
  static bool _isInitialized = false;
  static bool _isModelLoaded = false;
  static String? _currentModelId;

  /// Initialize the MLC-LLM runtime
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      print('AndroidMLCPlugin: Initializing MLC-LLM runtime...');
      
      final result = await _channel.invokeMethod('initialize');
      if (result['success'] == true) {
        _isInitialized = true;
        print('AndroidMLCPlugin: ✅ MLC-LLM runtime initialized successfully');
        return true;
      } else {
        print('AndroidMLCPlugin: ❌ Failed to initialize: ${result['error']}');
        return false;
      }
    } catch (e) {
      print('AndroidMLCPlugin: ❌ Exception during initialization: $e');
      return false;
    }
  }

  /// Load a model
  static Future<bool> loadModel(String modelId) async {
    if (!_isInitialized) {
      print('AndroidMLCPlugin: Runtime not initialized, initializing first...');
      final initialized = await initialize();
      if (!initialized) {
        return false;
      }
    }

    try {
      print('AndroidMLCPlugin: Loading model: $modelId');
      
      final result = await _channel.invokeMethod('loadModel', {
        'modelId': modelId,
        'useGPU': true,
        'maxVramBytes': 879040000, // Llama 3.2 1B VRAM requirement
      });

      if (result == true) {
        _isModelLoaded = true;
        _currentModelId = modelId;
        print('AndroidMLCPlugin: ✅ Model loaded successfully: $modelId');
        return true;
      } else {
        print('AndroidMLCPlugin: ❌ Failed to load model: $modelId');
        return false;
      }
    } catch (e) {
      print('AndroidMLCPlugin: ❌ Exception loading model: $e');
      return false;
    }
  }

  /// Generate response using the loaded model
  static Future<String> generateResponse(String prompt) async {
    if (!_isModelLoaded) {
      throw Exception('No model loaded. Please load a model first.');
    }

    try {
      print('AndroidMLCPlugin: Generating response for prompt: ${prompt.substring(0, prompt.length.clamp(0, 50))}...');
      
      final result = await _channel.invokeMethod('generateResponse', {
        'prompt': prompt,
        'maxTokens': 150,
        'temperature': 0.7,
        'topP': 0.9,
        'topK': 40,
      });

      if (result is String) {
        print('AndroidMLCPlugin: ✅ Generated response (${result.length} chars)');
        return result;
      } else {
        throw Exception('Invalid response from native code: $result');
      }
    } catch (e) {
      print('AndroidMLCPlugin: ❌ Exception generating response: $e');
      rethrow;
    }
  }

  /// Check if a model is loaded
  static Future<bool> isModelLoaded() async {
    return _isModelLoaded;
  }

  /// Unload the current model
  static Future<void> unloadModel() async {
    if (!_isModelLoaded) return;

    try {
      await _channel.invokeMethod('unloadModel');
      _isModelLoaded = false;
      _currentModelId = null;
      print('AndroidMLCPlugin: Model unloaded');
    } catch (e) {
      print('AndroidMLCPlugin: Error unloading model: $e');
    }
  }

  /// Get device capabilities
  static Future<Map<String, dynamic>> getDeviceCapabilities() async {
    try {
      final result = await _channel.invokeMethod('queryDeviceCapabilities');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('AndroidMLCPlugin: Error getting device capabilities: $e');
      return {};
    }
  }

  /// Get memory statistics
  static Future<Map<String, dynamic>> getMemoryStats() async {
    try {
      final result = await _channel.invokeMethod('getMemoryStats');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('AndroidMLCPlugin: Error getting memory stats: $e');
      return {};
    }
  }

  /// Get current model ID
  static String? get currentModelId => _currentModelId;

  /// Check if runtime is initialized
  static bool get isInitialized => _isInitialized;
}
