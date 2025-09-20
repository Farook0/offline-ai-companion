import 'package:flutter/foundation.dart';
import 'package:offline_ai_companion/models/ai_model.dart';
import 'package:offline_ai_companion/services/model_service.dart';
import 'package:offline_ai_companion/services/android_mlc_plugin.dart';

class AIModelProvider with ChangeNotifier {
  AIModel? _selectedModel;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Model loading progress tracking
  bool _isModelLoading = false;
  String _loadingStep = '';
  double _loadingProgress = 0.0;
  
  // MLC-LLM initialization status
  bool _mlcInitialized = false;

  AIModelProvider() {
    print('AIModelProvider: Constructor called');
  }

  // Getters
  AIModel? get selectedModel => _selectedModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasModels => true; // Always true since we have LLaMA MLC
  
  // Model loading progress getters
  bool get isModelLoading => _isModelLoading;
  String get loadingStep => _loadingStep;
  double get loadingProgress => _loadingProgress;

  // Initialize models - MLC-LLM with Llama 3.2 1B default
  Future<void> initializeModels() async {
    print('AIModelProvider: initializeModels() called');
    Future.microtask(() => _setLoading(true));
    try {
      print('AIModelProvider: Starting MLC-LLM initialization...');
      
      // Initialize MLC-LLM runtime
      _updateLoadingStep('Initializing MLC-LLM runtime...', 0.1);
      _mlcInitialized = await AndroidMLCPlugin.initialize();
      
      if (!_mlcInitialized) {
        throw Exception('Failed to initialize MLC-LLM runtime');
      }
      
      // Set Llama 3.2 1B as the default model (fast bundled model)
      _selectedModel = AIModel.llama32_1b;
      
      // Load the default model
      await selectModel(AIModel.llama32_1b);
      
      _errorMessage = null;
      print('AIModelProvider: Initialization completed successfully');
    } catch (e) {
      _errorMessage = 'Failed to initialize models: $e';
      print('AIModelProvider: Initialization failed: $e');
    } finally {
      Future.microtask(() => _setLoading(false));
    }
  }

  // Ensure LLaMA MLC model is available
  Future<void> _ensureLlamaMLCAvailable() async {
    try {
      print('AIModelProvider: Checking LLaMA MLC model availability...');
      
      // Test if assets are accessible
      print('AIModelProvider: Testing asset access...');
      final assetAccess = await ModelService.testAssetAccess();
      if (!assetAccess) {
        print('AIModelProvider: Asset access failed!');
        return;
      }
      
      print('AIModelProvider: LLaMA MLC model is bundled in APK');
    } catch (e) {
      print('AIModelProvider: Error checking LLaMA MLC model: $e');
    }
  }

  // Select model with MLC-LLM loading
  Future<void> selectModel(AIModel model) async {
    if (_selectedModel?.id == model.id && await AndroidMLCPlugin.isModelLoaded()) {
      // Model is already selected and loaded
      return;
    }

    _setModelLoading(true);
    _updateLoadingProgress(0.0, '🚀 Loading LLaMA 3.2 1B (MLC)...');
    
    try {
      // Ensure MLC-LLM is initialized
      if (!_mlcInitialized) {
        _updateLoadingStep('Initializing MLC-LLM runtime...', 0.1);
        _mlcInitialized = await AndroidMLCPlugin.initialize();
        if (!_mlcInitialized) {
          throw Exception('Failed to initialize MLC-LLM runtime');
        }
      }

      // Load the model using MLC-LLM
      _updateLoadingStep('Loading model with GPU acceleration...', 0.3);
      await Future.delayed(Duration.zero); // Yield to UI
      
      final success = await AndroidMLCPlugin.loadModel(model.id);
      
      if (success) {
        _selectedModel = model;
        _errorMessage = null;
        _updateLoadingStep('✅ Ready! ${model.name} loaded with GPU', 1.0);
        print('AIModelProvider: MLC model ${model.name} loaded successfully');
        
        // Small delay to show completion
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        _errorMessage = 'Failed to load MLC model: ${model.name}';
        print('AIModelProvider: Failed to load MLC model: ${model.name}');
      }
    } catch (e) {
      _errorMessage = 'Error loading MLC model: $e';
      print('AIModelProvider: Error selecting MLC model: $e');
    } finally {
      _setModelLoading(false);
    }
  }

  // Generate response using MLC-LLM (with yield to prevent UI blocking)
  Future<String> generateResponse(String prompt) async {
    if (await AndroidMLCPlugin.isModelLoaded()) {
      try {
        print('AIModelProvider: Using MLC-LLM for response generation');
        
        // Yield control to UI thread before starting AI processing
        await Future.delayed(Duration.zero);
        
        return await AndroidMLCPlugin.generateResponse(prompt);
      } catch (e) {
        print('AIModelProvider: Error with MLC-LLM: $e');
        throw Exception('Failed to generate response with MLC-LLM: $e');
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
    return modelId == 'Llama-3.2-1B-Instruct-q4f16_0-MLC';
  }

  // Get model configuration
  ModelConfiguration getModelConfiguration(String modelId) {
    if (modelId == 'Llama-3.2-1B-Instruct-q4f16_0-MLC') {
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
      await _ensureLlamaMLCAvailable();
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

  void _updateLoadingStep(String step, double progress) {
    _loadingStep = step;
    _loadingProgress = progress;
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up MLC-LLM resources
    AndroidMLCPlugin.unloadModel();
    super.dispose();
  }
} 