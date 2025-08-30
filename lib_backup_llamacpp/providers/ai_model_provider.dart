import 'package:flutter/foundation.dart';
import 'package:offline_ai_companion/models/ai_model.dart';
import 'package:offline_ai_companion/services/model_service.dart';
import 'package:offline_ai_companion/services/real_llama_service.dart';

class AIModelProvider with ChangeNotifier {
  AIModel? _selectedModel;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Model loading progress tracking
  bool _isModelLoading = false;
  String _loadingStep = '';
  double _loadingProgress = 0.0;
  
  // Real llama service for actual model loading
  RealLlamaService? _realLlamaService;

  AIModelProvider() {
    print('AIModelProvider: Constructor called');
  }

  // Getters
  AIModel? get selectedModel => _selectedModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasModels => true; // Always true since we have Qwen2
  
  // Model loading progress getters
  bool get isModelLoading => _isModelLoading;
  String get loadingStep => _loadingStep;
  double get loadingProgress => _loadingProgress;

  // Initialize models - simplified for TinyLlama only
  Future<void> initializeModels() async {
    print('AIModelProvider: initializeModels() called');
    Future.microtask(() => _setLoading(true));
    try {
      print('AIModelProvider: Starting initialization...');
      
      // Ensure Qwen2 model is copied from assets
      await _ensureQwen2Copied();
      
      // Set Qwen2 as the default model and load it
      _selectedModel = AIModel.qwen2_5;
      
      // Actually load the model with llama.cpp
      await selectModel(AIModel.qwen2_5);
      
      _errorMessage = null;
      print('AIModelProvider: Initialization completed successfully');
    } catch (e) {
      _errorMessage = 'Failed to initialize models: $e';
      print('AIModelProvider: Initialization failed: $e');
    } finally {
      Future.microtask(() => _setLoading(false));
    }
  }

  // Ensure Qwen2 is copied from assets
  Future<void> _ensureQwen2Copied() async {
    try {
      print('AIModelProvider: Ensuring Qwen2 is copied...');
      
      // Test if assets are accessible
      print('AIModelProvider: Testing asset access...');
      final assetAccess = await ModelService.testAssetAccess();
      if (!assetAccess) {
        print('AIModelProvider: Asset access failed!');
        return;
      }
      
      // Copy Qwen2 model
      print('AIModelProvider: Copying Qwen2...');
      final success = await ModelService.copyModelToAppDirectory('qwen2.5-1.5b-instruct-q4_k_m.gguf');
      if (success) {
        print('AIModelProvider: Successfully copied Qwen2');
      } else {
        print('AIModelProvider: Failed to copy Qwen2');
      }
    } catch (e) {
      print('AIModelProvider: Error copying Qwen2: $e');
    }
  }

  // Select Qwen2 model with real llama.cpp loading
  Future<void> selectModel(AIModel model) async {
    if (model.id != 'qwen2.5-1_5b') {
      _errorMessage = 'Only Qwen2 1.5B is supported';
      notifyListeners();
      return;
    }

    if (_selectedModel?.id == model.id && _realLlamaService?.isModelLoaded == true) {
      // Model is already selected and loaded
      return;
    }

    _setModelLoading(true);
    _updateLoadingProgress(0.0, '🚀 Loading Qwen2 1.5B (Q4_K_M)...');
    
    try {
      // Initialize real llama service if not already done
      if (_realLlamaService == null) {
        _updateLoadingProgress(0.1, 'Initializing AI service...');
        _realLlamaService = RealLlamaService();
        
        // Set up progress callback
        _realLlamaService!.setProgressCallback((progress) {
          _updateLoadingProgress(0.1 + (_loadingProgress * 0.3), progress);
        });
        
        try {
          await _realLlamaService!.initialize();
          _updateLoadingProgress(0.4, 'AI service initialized');
        } catch (e) {
          print('AIModelProvider: Failed to initialize real llama service: $e');
          throw Exception('Failed to initialize llama.cpp service: $e');
        }
      }

      // Load the model
      _updateLoadingProgress(0.5, 'Loading model into memory...');
      
      // Set up progress callback for model loading
      _realLlamaService!.setProgressCallback((progress) {
        _updateLoadingProgress(0.5 + (_loadingProgress * 0.4), progress);
      });
      
      bool success = false;
      try {
        success = await _realLlamaService!.loadModel(model);
      } catch (e) {
        print('AIModelProvider: Failed to load model with real service: $e');
        throw Exception('Failed to load model with llama.cpp: $e');
      }
      
      if (success) {
        _updateLoadingProgress(1.0, '🎉 Qwen2 1.5B Q4_K_M loaded successfully! Ready for inference.');
        _selectedModel = model;
        _errorMessage = null;
        
        // Small delay to show completion
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        throw Exception('Failed to load model');
      }
    } catch (e) {
      _errorMessage = 'Failed to load Qwen2: $e';
      print('AIModelProvider: Error loading Qwen2: $e');
    } finally {
      _setModelLoading(false);
    }
  }

  // Generate response using the loaded model (with yield to prevent UI blocking)
  Future<String> generateResponse(String prompt) async {
    if (_realLlamaService?.isModelLoaded == true) {
      try {
        print('AIModelProvider: Using real llama.cpp for response generation');
        
        // Yield control to UI thread before starting AI processing
        await Future.delayed(Duration.zero);
        
        return await _realLlamaService!.generateResponse(prompt);
      } catch (e) {
        print('AIModelProvider: Error with real llama.cpp: $e');
        throw Exception('Failed to generate response with llama.cpp: $e');
      }
    } else {
      print('AIModelProvider: No model loaded, cannot generate response');
      throw Exception('No model loaded. Please load a model first.');
    }
  }

  // Get available models (only TinyLlama)
  List<AIModel> get availableModels => AIModel.availableModels;

  // Get model by ID
  AIModel? getModelById(String id) {
    return AIModel.getById(id);
  }

  // Check if model is available
  bool isModelAvailable(String modelId) {
    return modelId == 'qwen2.5-1_5b';
  }

  // Get model configuration
  ModelConfiguration getModelConfiguration(String modelId) {
    if (modelId == 'qwen2.5-1_5b') {
      return const ModelConfiguration();
    }
    return const ModelConfiguration();
  }

  // Update model configuration
  Future<void> updateModelConfiguration(
    String modelId,
    ModelConfiguration configuration,
  ) async {
    // Simplified - just notify listeners
    notifyListeners();
  }

  // Refresh models (simplified)
  Future<void> refreshModels() async {
    Future.microtask(() => _setLoading(true));
    try {
      await _ensureQwen2Copied();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to refresh models: $e';
    } finally {
      Future.microtask(() => _setLoading(false));
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setModelLoading(bool loading) {
    _isModelLoading = loading;
    if (!loading) {
      _loadingProgress = 0.0;
      _loadingStep = '';
    }
    notifyListeners();
  }

  void _updateLoadingProgress(double progress, String step) {
    _loadingProgress = progress;
    _loadingStep = step;
    notifyListeners();
  }

  @override
  void dispose() {
    _realLlamaService?.dispose();
    super.dispose();
  }
} 