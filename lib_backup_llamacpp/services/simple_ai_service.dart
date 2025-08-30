import 'dart:io';
import 'package:offline_ai_companion/models/ai_model.dart';
import 'package:offline_ai_companion/services/model_service.dart';

/// Simplified AI Service for testing without native llama.cpp
/// This provides mock responses while you debug the native integration
class SimpleAIService {
  AIModel? _currentModel;
  bool _isInitialized = false;
  Function(String)? _progressCallback;

  void setProgressCallback(Function(String) callback) {
    _progressCallback = callback;
  }

  Future<void> initialize() async {
    print('SimpleAIService: Initializing...');
    
    // Copy models to device storage
    await _copyModelsToAppDirectory();
    
    _isInitialized = true;
    print('SimpleAIService: Initialized successfully');
  }

  Future<void> _copyModelsToAppDirectory() async {
    try {
      print('SimpleAIService: Testing model copy...');
      
      final modelFiles = ['Phi-3-mini-4k-instruct-q4.gguf'];
      
      for (final modelFile in modelFiles) {
        _progressCallback?.call('📋 Checking $modelFile...');
        
        final exists = await ModelService.modelExists(modelFile);
        if (exists) {
          _progressCallback?.call('✅ $modelFile already exists');
          continue;
        }
        
        _progressCallback?.call('📥 Copying $modelFile...');
        final success = await ModelService.copyModelToAppDirectory(modelFile);
        
        if (success) {
          _progressCallback?.call('✅ Successfully copied $modelFile');
        } else {
          _progressCallback?.call('❌ Failed to copy $modelFile');
        }
      }
    } catch (e) {
      _progressCallback?.call('❌ Copy error: $e');
      print('SimpleAIService: Copy error: $e');
    }
  }

  Future<String> generateResponse(
    String prompt, {
    String? modelId,
    Map<String, dynamic>? configuration,
  }) async {
    if (!_isInitialized) {
      throw Exception('AI Service not initialized');
    }

    // Set current model
    if (modelId != null) {
      _currentModel = await _getModel(modelId);
    }

    if (_currentModel == null) {
      final availableModels = await ModelService.getAvailableModels();
      if (availableModels.isNotEmpty) {
        _currentModel = availableModels.first;
      } else {
        throw Exception('No models available');
      }
    }

    // Test file access
    final modelFile = File(_currentModel!.filePath);
    if (!await modelFile.exists()) {
      throw Exception('Model file not found: ${_currentModel!.filePath}');
    }

    final fileSize = await modelFile.length();
    
    // Generate test response
    return '''🤖 **${_currentModel!.name} - TEST MODE**

**Your question:** $prompt

**Model Status:**
✅ Model file found: ${_currentModel!.filePath}
✅ File size: ${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB
✅ Model format: ${_currentModel!.format}
✅ Parameters: ${(_currentModel!.parameters / 1000000).toStringAsFixed(1)}M

**Test Response:**
I am running in test mode while the native llama.cpp integration is being set up. The model file has been successfully loaded and verified. 

Your prompt was: "$prompt"

Once the native C++ integration is working, I will be able to generate real AI responses using the ${_currentModel!.name} model.

**Next Steps:**
1. Ensure native library compiles correctly
2. Test ADB installation on your device  
3. Check logs for any native library errors

**Technical Details:**
• Platform: ${Platform.isAndroid ? 'Android' : 'Desktop'}
• Model ID: ${_currentModel!.id}
• Ready for native integration: ✅
''';
  }

  Future<AIModel?> _getModel(String modelId) async {
    final availableModels = await ModelService.getAvailableModels();
    for (final model in availableModels) {
      if (model.id == modelId) {
        return model;
      }
    }
    return null;
  }

  Future<List<String>> getAvailableModelIds() async {
    final models = await ModelService.getAvailableModels();
    return models.map((model) => model.id).toList();
  }

  Future<bool> isModelAvailable(String modelId) async {
    final availableIds = await getAvailableModelIds();
    return availableIds.contains(modelId);
  }

  AIModel? get currentModel => _currentModel;
  bool get isInitialized => _isInitialized;
  bool get isAndroid => Platform.isAndroid;

  void dispose() {
    print('SimpleAIService: Disposing...');
    _currentModel = null;
    _isInitialized = false;
  }
}

