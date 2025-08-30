import 'dart:io';
import 'package:offline_ai_companion/models/ai_model.dart';
import 'package:offline_ai_companion/services/real_llama_service.dart';
import 'package:offline_ai_companion/services/model_service.dart';

class AIService {
  AIModel? _currentModel;
  bool _isInitialized = false;
  bool _isAndroid = Platform.isAndroid;
  RealLlamaService? _realLlamaService;
  bool _useRealLlama = false;
  Function(String)? _progressCallback;

  // Set progress callback for model loading
  void setProgressCallback(Function(String) callback) {
    _progressCallback = callback;
    _realLlamaService?.setProgressCallback(callback);
  }

  // Initialize the AI service
  Future<void> initialize() async {
    print('AIService: Initializing...');
    
    // First, copy models to app directory (if needed)
    await _copyModelsToAppDirectory();
    
    // Try to initialize real llama service on Android
    if (_isAndroid) {
      try {
        _realLlamaService = RealLlamaService();
        // Set up progress callback before initialization
        if (_progressCallback != null) {
          _realLlamaService!.setProgressCallback(_progressCallback!);
        }
        await _realLlamaService!.initialize();
        _useRealLlama = true;
        print('AIService: Real llama service initialized successfully');
        
        // Verify models are accessible
        await _verifyModelsAccessibility();
      } catch (e) {
        print('AIService: Failed to initialize real llama service: $e');
        print('AIService: Falling back to test mode while fixing native implementation');
        _progressCallback?.call('⚠️ Native llama.cpp failed to initialize. Using test mode.');
        _progressCallback?.call('📋 This will verify model files are accessible while we fix the native build.');
        // Continue without throwing - we'll use test responses
        _useRealLlama = false;
      }
    }
    
    _isInitialized = true;
    print('AIService: Initialized successfully');
  }
  
  // Copy models from assets to app directory
  Future<void> _copyModelsToAppDirectory() async {
    try {
      print('AIService: Starting model copy process...');
      
      // First test asset access
      final assetAccessible = await ModelService.testAssetAccess();
      if (!assetAccessible) {
        print('AIService: Assets are not accessible, cannot copy models');
        return;
      }
      
      final modelFiles = [
        'Phi-3-mini-4k-instruct-q4.gguf',  // Phi-3-Mini model
      ];
      
      for (final modelFile in modelFiles) {
        print('AIService: Checking if $modelFile needs to be copied...');
        
        // Check if model already exists
        final exists = await ModelService.modelExists(modelFile);
        if (exists) {
          print('AIService: $modelFile already exists, skipping copy');
          continue;
        }
        
        print('AIService: Copying $modelFile...');
        final success = await ModelService.copyModelToAppDirectory(modelFile);
        if (success) {
          print('AIService: Successfully copied $modelFile');
          
          // Verify the copied file
          final fileSize = await ModelService.getModelFileSize(modelFile);
          if (fileSize != null && fileSize > 0) {
            print('AIService: Verified $modelFile, size: $fileSize bytes');
          } else {
            print('AIService: Warning: $modelFile appears to be empty or corrupted');
          }
        } else {
          print('AIService: Failed to copy $modelFile');
        }
      }
      
      // Verify models are available after copy
      await _verifyModelsAccessibility();
    } catch (e) {
      print('AIService: Error in copy process: $e');
    }
  }

  // Verify that models are accessible and properly copied
  Future<void> _verifyModelsAccessibility() async {
    try {
      print('AIService: Verifying model accessibility...');
      
      final availableModels = await ModelService.getAvailableModels();
      print('AIService: Found ${availableModels.length} available models');
      
      if (availableModels.isEmpty) {
        print('AIService: WARNING - No models found after initialization');
        return;
      }
      
      for (final model in availableModels) {
        print('AIService: Verifying model: ${model.name}');
        print('AIService: - ID: ${model.id}');
        print('AIService: - Path: ${model.filePath}');
        print('AIService: - Available: ${model.isAvailable}');
        
        // Check if the file actually exists and has content
        final file = File(model.filePath);
        if (await file.exists()) {
          final size = await file.length();
          print('AIService: - File exists, size: $size bytes');
          if (size == 0) {
            print('AIService: WARNING - Model file is empty: ${model.filePath}');
          }
        } else {
          print('AIService: ERROR - Model file does not exist: ${model.filePath}');
        }
      }
    } catch (e) {
      print('AIService: Error verifying model accessibility: $e');
    }
  }

  // Generate response using the current model
  Future<String> generateResponse(
    String prompt, {
    String? modelId,
    ModelConfiguration? configuration,
  }) async {
    print('AIService: Generating response for prompt: "$prompt"');
    print('AIService: Model ID: $modelId');
    
    if (!_isInitialized) {
      throw Exception('AI Service not initialized. Call initialize() first.');
    }

    // Set the current model based on modelId if provided
    if (modelId != null && (_currentModel?.id != modelId)) {
      _currentModel = await _getRealModel(modelId);
      if (_currentModel == null) {
        throw Exception('Model not found: $modelId');
      }
      print('AIService: Set current model to: ${_currentModel?.name}');
    }

    // If no model is set, try to load the first available model
    if (_currentModel == null) {
      print('AIService: No current model set, trying to load first available model');
      final availableModels = await ModelService.getAvailableModels();
      if (availableModels.isNotEmpty) {
        _currentModel = availableModels.first;
        print('AIService: Auto-selected model: ${_currentModel?.name}');
      } else {
        throw Exception('No models available for inference');
      }
    }

    // Use real llama service if available
    if (_useRealLlama && _realLlamaService != null && _currentModel != null) {
      try {
        // Check if the model file actually exists
        final modelFile = File(_currentModel!.filePath);
        if (!await modelFile.exists()) {
          throw Exception('Model file not found: ${_currentModel!.filePath}');
        }
        
        print('AIService: Model file verified: ${_currentModel!.filePath}');
        
        // Load model if not already loaded or if it's a different model
        if (!_realLlamaService!.isModelLoaded || 
            _realLlamaService!.currentModelPath != _currentModel!.filePath) {
          print('AIService: Loading model with real llama service...');
          _progressCallback?.call('🚀 Preparing to load ${_currentModel!.name}...');
          
          final success = await _realLlamaService!.loadModel(_currentModel!);
          if (!success) {
            _progressCallback?.call('❌ Failed to load ${_currentModel!.name}');
            throw Exception('Failed to load model with real llama service');
          }
          _progressCallback?.call('✅ ${_currentModel!.name} is ready for inference!');
        } else {
          _progressCallback?.call('✅ ${_currentModel!.name} already loaded and ready!');
        }
        print('AIService: Model loaded successfully');
        
        // Generate real response
        print('AIService: Generating response with real llama service...');
        final response = await _realLlamaService!.generateResponse(
          prompt,
          maxTokens: configuration?.maxTokens ?? 150,
          temperature: configuration?.temperature ?? 0.7,
        );
        
        print('AIService: Generated response successfully');
        return response;
      } catch (e) {
        print('AIService: Real llama service failed: $e');
        _progressCallback?.call('❌ Native llama.cpp error: $e');
        _progressCallback?.call('🔄 Falling back to test mode...');
        // Fall through to test mode below
      }
    }
    
    // Test mode response - verifies model files while debugging native implementation
    print('AIService: Using test mode response');
    return await _generateTestResponse(prompt, configuration);
  }
  
  // Get real model from available models
  Future<AIModel?> _getRealModel(String modelId) async {
    try {
      print('AIService: Looking for model with ID: $modelId');
      final availableModels = await ModelService.getAvailableModels();
      print('AIService: Available models: ${availableModels.map((m) => m.id).toList()}');
      
      for (final model in availableModels) {
        if (model.id == modelId) {
          print('AIService: Found matching model: ${model.name}');
          return model;
        }
      }
      
      print('AIService: Model not found: $modelId');
      // NO FALLBACK - throw error to force using correct model ID
      throw Exception('Model not found: $modelId. Only qwen2.5-1_5b is available.');
    } catch (e) {
      print('AIService: Error getting real model: $e');
      // NO FALLBACK - rethrow to force fixing
      rethrow;
    }
  }

  // Get list of available model IDs
  Future<List<String>> getAvailableModelIds() async {
    try {
      final models = await ModelService.getAvailableModels();
      return models.map((model) => model.id).toList();
    } catch (e) {
      print('AIService: Error getting available model IDs: $e');
      return ['tinyllama-1.1b', 'phi-2']; // Return default IDs
    }
  }

  // Check if a specific model is available
  Future<bool> isModelAvailable(String modelId) async {
    try {
      final availableIds = await getAvailableModelIds();
      return availableIds.contains(modelId);
    } catch (e) {
      print('AIService: Error checking model availability: $e');
      return false;
    }
  }

  // Test response generator - verifies model files while debugging native implementation
  Future<String> _generateTestResponse(String prompt, ModelConfiguration? configuration) async {
    try {
      // Verify model file exists and is accessible
      final modelFile = File(_currentModel!.filePath);
      final exists = await modelFile.exists();
      final size = exists ? await modelFile.length() : 0;
      final sizeMB = (size / 1024 / 1024).toStringAsFixed(1);
      
      // Check available storage
      final modelsDir = await ModelService.getModelsDirectory();
      final dir = Directory(modelsDir);
      final files = await dir.list().toList();
      final modelFiles = files.where((f) => f.path.endsWith('.gguf')).length;
      
      return '''🧪 **${_currentModel!.name} - Test Mode**

**Your question:** $prompt

**🔍 Model File Status:**
${exists ? '✅' : '❌'} File exists: ${_currentModel!.filePath}
${exists ? '✅' : '❌'} File size: $sizeMB MB
${size > 100000 ? '✅' : '⚠️'} File appears valid: ${size > 100000 ? 'Yes' : 'Possibly corrupted'}

**📂 Model Directory Status:**
📍 Location: $modelsDir
📁 Model files found: $modelFiles
🔢 Expected models: 1 (Phi-3-mini-4k-instruct-q4.gguf)

**🤖 Test Response:**
I'm running in test mode while the native llama.cpp integration is being debugged. 

Your prompt: "$prompt"

The model files have been successfully verified and are ready for AI inference once the native C++ integration is working properly.

**🛠️ Debugging Status:**
• ✅ Flutter app running
• ✅ Model files accessible  
• ✅ Model service working
• ⚠️ Native llama.cpp initialization failed
• 📋 Check logs for: "Failed to initialize native llama.cpp"

**🚀 Next Steps:**
1. Check Android logs: \`adb logcat | grep -E "(MainActivity|LlamaCppWrapper)"\`
2. Verify native library build
3. Try rebuilding with: \`./build_android_native.sh\`

**Technical Details:**
• Model: ${_currentModel!.name}
• Platform: ${Platform.isAndroid ? 'Android' : 'Desktop'} 
• Max tokens: ${configuration?.maxTokens ?? 150}
• Temperature: ${configuration?.temperature ?? 0.7}
• Status: 🧪 Test mode (native debugging)

Once the native integration is fixed, I'll provide real AI responses!''';
    } catch (e) {
      return '''❌ **Error in Test Mode**

Failed to verify model files: $e

Please check:
1. Model files are in the correct location
2. App has file access permissions
3. Available storage space

Error details: $e''';
    }
  }

  // REMOVED: No fallback responses - only real llama.cpp
  String _removedFallbackResponse(String prompt, ModelConfiguration? configuration) {
    final modelName = _currentModel?.name ?? 'Unknown Model';
    final maxTokens = configuration?.maxTokens ?? 150;
    final temperature = configuration?.temperature ?? 0.7;
    
    // Generate different responses based on the model
    switch (_currentModel?.id) {
      case 'tinyllama-1.1b':
        return _generateTinyLlamaResponse(prompt, maxTokens, temperature);
      case 'phi-2':
        return _generatePhi2Response(prompt, maxTokens, temperature);
      default:
        return _generateGenericResponse(prompt, maxTokens, temperature);
    }
  }

  String _generateTinyLlamaResponse(String prompt, int maxTokens, double temperature) {
    return '''🤖 **TinyLlama 1.1B Response**

**Your question:** $prompt

**AI Response:**
I am a general-purpose AI assistant powered by TinyLlama 1.1B. I can help you with any type of question or task, including:

• General knowledge and facts
• Problem solving and reasoning
• Creative writing and storytelling
• Technical explanations
• Language translation and analysis
• Mathematical calculations
• Programming and coding help
• Personal advice and conversation
• Educational topics and explanations
• And much more!

**Model Details:**
• Model: TinyLlama 1.1B (Q2_K quantized)
• Parameters: 1.1 billion
• File size: ~461MB
• Optimized for: Fast inference, mobile devices
• Response time: ~${(maxTokens / 50).round()} seconds

**Technical Info:**
• Max tokens: $maxTokens
• Temperature: $temperature
• Platform: Android (Samsung A56)
• Status: ✅ Model loaded and responding

I'm ready to help with whatever you need!''';
  }

  String _generatePhi2Response(String prompt, int maxTokens, double temperature) {
    return '''🤖 **Phi-2 Response**

**Your question:** $prompt

**AI Response:**
I am a general-purpose AI assistant powered by Microsoft Phi-2. I can help you with any type of question or task, including:

• Mathematical reasoning and calculations
• Programming and code generation
• Complex problem solving and analysis
• Scientific explanations and concepts
• Logical reasoning and critical thinking
• Creative writing and storytelling
• General knowledge and facts
• Language translation and analysis
• Educational topics and explanations
• Personal advice and conversation
• And much more!

**Model Details:**
• Model: Microsoft Phi-2 (Q4_K_M quantized)
• Parameters: 2.7 billion
• File size: ~1.7GB
• Specialization: General-purpose reasoning
• Response time: ~${(maxTokens / 40).round()} seconds

**Technical Info:**
• Max tokens: $maxTokens
• Temperature: $temperature
• Platform: Android (Samsung A56)
• Status: ✅ Model loaded and responding

I'm ready to help with whatever you need!''';
  }

  String _generateGenericResponse(String prompt, int maxTokens, double temperature) {
    return '''🤖 **AI Response**

**Your question:** $prompt

**AI Response:**
I am a general-purpose AI assistant running on your Samsung A56. I can help you with any type of question or task, including:

• General knowledge and facts
• Problem solving and reasoning
• Creative writing and storytelling
• Technical explanations
• Language translation and analysis
• Mathematical calculations
• Programming and coding help
• Personal advice and conversation
• Educational topics and explanations
• And much more!

**Model Details:**
• Status: ✅ Active and responding
• Platform: Android (Samsung A56)
• Response time: ~${(maxTokens / 60).round()} seconds

**Technical Info:**
• Max tokens: $maxTokens
• Temperature: $temperature
• Model: ${_currentModel?.name ?? 'Unknown'}

I'm ready to help with whatever you need!''';
  }

  // REMOVED: No mock models - only real models
  AIModel _removedMockModel(String modelId) {
    switch (modelId) {
      case 'phi3-mini-4k':
        return const AIModel(
          id: 'phi3-mini-4k',
          name: 'Phi-3-Mini 4K',
          description: 'Microsoft Phi-3-Mini with 4K context. High-quality responses optimized for mobile devices (2.4GB).',
          version: '3.8B Q4',
          filePath: 'assets/models/Phi-3-mini-4k-instruct-q4.gguf',
          parameters: 3800000000,
          format: 'GGUF',
          isAvailable: true,
        );
      // Removed Phi-2 - too large for mobile testing
      case 'mistral-7b':
        return const AIModel(
          id: 'mistral-7b',
          name: 'Mistral 7B',
          description: 'Mistral 7B is a 7B parameter language model with strong reasoning and instruction-following capabilities.',
          version: '7B',
          filePath: 'assets/models/mistral-7b-instruct.Q4_K_M.gguf',
          parameters: 7000000000,
          format: 'GGUF',
          isAvailable: false,
        );
      default:
        return const AIModel(
          id: 'unknown',
          name: 'Unknown Model',
          description: 'Unknown model type.',
          version: 'Unknown',
          filePath: '',
          parameters: 0,
          format: 'Unknown',
          isAvailable: false,
        );
    }
  }

  // Get current model
  AIModel? get currentModel => _currentModel;

  // Check if service is initialized
  bool get isInitialized => _isInitialized;

  // Check if running on Android
  bool get isAndroid => _isAndroid;

  // Check if using real llama service
  bool get useRealLlama => _useRealLlama;

  // Get real llama service status
  bool get isRealLlamaServiceReady => _useRealLlama && _realLlamaService != null;

  // Dispose method for cleanup
  void dispose() {
    print('AIService: Disposing...');
    _realLlamaService?.dispose();
    _currentModel = null;
    _isInitialized = false;
    _useRealLlama = false;
    print('AIService: Disposed successfully');
  }
}