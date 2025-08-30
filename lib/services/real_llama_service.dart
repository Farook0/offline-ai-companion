import 'dart:io';
import 'package:flutter/services.dart';
import 'package:offline_ai_companion/models/ai_model.dart';
import 'package:offline_ai_companion/services/model_service.dart';

class RealLlamaService {
  static const MethodChannel _channel = MethodChannel('android_llama_plugin');
  
  bool _isInitialized = false;
  bool _isModelLoaded = false;
  String? _loadedModelId;
  Function(String)? _onProgress;

  // Set progress callback
  void setProgressCallback(Function(String) callback) {
    _onProgress = callback;
  }

  // Initialize the native llama.cpp
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _onProgress?.call('🔧 Initializing native llama.cpp... (5%)');
      await Future.delayed(Duration(milliseconds: 300));
      
      final result = await _channel.invokeMethod('initialize');
      _isInitialized = result == true;
      
      if (_isInitialized) {
        _onProgress?.call('✅ Native llama.cpp initialized successfully (10%)');
        print('RealLlamaService: Native llama.cpp initialized');
      } else {
        throw Exception('Failed to initialize native llama.cpp');
      }
    } catch (e) {
      print('RealLlamaService: Error initializing native llama.cpp: $e');
      _onProgress?.call('❌ Failed to initialize native llama.cpp: $e');
      rethrow;
    }
  }

  // Load a model
  Future<bool> loadModel(AIModel model) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _onProgress?.call('🔍 Locating model file... (10%)');
      await Future.delayed(Duration(milliseconds: 200)); // Small delay for UI
      
      // Get the model file path
      final modelPath = await _getModelFilePath(model);
      if (!await File(modelPath).exists()) {
        throw Exception('Model file not found: $modelPath');
      }

      _onProgress?.call('✅ Model file found: ${model.name} (20%)');
      await Future.delayed(Duration(milliseconds: 300));

      _onProgress?.call('🧠 Initializing model context... (30%)');
      await Future.delayed(Duration(milliseconds: 400));
      
      _onProgress?.call('📚 Loading model weights into memory... (40%)');
      await Future.delayed(Duration(milliseconds: 500));
      
      // Load the model using native llama.cpp
      print('RealLlamaService: Calling native loadModel with path: $modelPath');
      _onProgress?.call('⚡ Starting native llama.cpp inference engine... (60%)');
      
      final result = await _channel.invokeMethod('loadModel', {
        'modelPath': modelPath,
        'contextLength': model.configuration['context_length'] ?? 2048,
        'temperature': model.configuration['temperature'] ?? 0.7,
        'topP': model.configuration['top_p'] ?? 0.9,
        'maxTokens': model.configuration['max_tokens'] ?? 150,
      });
      print('RealLlamaService: Native loadModel returned: $result');

      _onProgress?.call('🔧 Configuring model parameters... (80%)');
      await Future.delayed(Duration(milliseconds: 300));

      if (result == true) {
        _isModelLoaded = true;
        _loadedModelId = model.id;
        _onProgress?.call('🎉 Model loaded successfully! Ready for inference (100%)');
        print('RealLlamaService: Model ${model.name} loaded successfully');
        return true;
      } else {
        throw Exception('Failed to load model');
      }
    } catch (e) {
      print('RealLlamaService: Error loading model: $e');
      _onProgress?.call('Failed to load model: $e');
      return false;
    }
  }

  // Generate response using the loaded model
  Future<String> generateResponse(String prompt, {int? maxTokens, double? temperature}) async {
    if (!_isModelLoaded) {
      throw Exception('No model loaded. Please load a model first.');
    }

    try {
      print('RealLlamaService: Generating response for: "$prompt"');
      
      final result = await _channel.invokeMethod('generateResponse', {
        'prompt': prompt,
        'maxTokens': maxTokens ?? 150,
        'temperature': temperature ?? 0.7,
      });
      print('RealLlamaService: Native generateResponse returned: $result');

      if (result is String) {
        print('RealLlamaService: Generated response: $result');
        return result;
      } else {
        throw Exception('Invalid response from native code: $result');
      }
    } catch (e) {
      print('RealLlamaService: Error generating response: $e');
      rethrow;
    }
  }

  // Unload the current model
  Future<void> unloadModel() async {
    if (!_isModelLoaded) return;

    try {
      await _channel.invokeMethod('unloadModel');
      _isModelLoaded = false;
      _loadedModelId = null;
      print('RealLlamaService: Model unloaded');
    } catch (e) {
      print('RealLlamaService: Error unloading model: $e');
    }
  }

  // Get model file path
  Future<String> _getModelFilePath(AIModel model) async {
    final modelsDir = await ModelService.getModelsDirectory();
    final modelFileName = model.filePath.split('/').last;
    return '$modelsDir/$modelFileName';
  }

  // Check if a model is loaded
  bool get isModelLoaded => _isModelLoaded;
  
  // Get the ID of the currently loaded model
  String? get loadedModelId => _loadedModelId;

  // Get the current model path
  String? get currentModelPath => _loadedModelId != null ? 'model loaded' : null;

  // Check if the service is initialized
  bool get isInitialized => _isInitialized;

  // Dispose resources
  void dispose() {
    unloadModel();
  }
} 