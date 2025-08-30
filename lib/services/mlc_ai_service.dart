import 'dart:io';
import 'package:offline_ai_companion/models/ai_model.dart';
import 'package:offline_ai_companion/models/mlc_model.dart';
import 'package:offline_ai_companion/services/mlc_service.dart';
import 'package:offline_ai_companion/services/real_llama_service.dart';

/// Enhanced AI Service with MLC-LLM support
/// Provides 5-10x faster model loading and GPU acceleration
class MLCAIService {
  MLCService? _mlcService;
  RealLlamaService? _legacyService; // Fallback to legacy llama.cpp
  MLCModel? _currentModel;
  bool _isInitialized = false;
  bool _useMLC = false;
  bool _useLegacy = false;
  Function(String)? _progressCallback;

  /// Initialize the AI service with MLC-LLM support
  Future<void> initialize() async {
    print('MLCAIService: Initializing with MLC-LLM support...');
    _progressCallback?.call('🚀 Initializing MLC-LLM runtime...');

    try {
      // Try MLC-LLM first (preferred)
      await _initializeMLC();
    } catch (e) {
      print('MLCAIService: MLC initialization failed, trying legacy: $e');
      _progressCallback?.call('⚠️ MLC-LLM failed, trying legacy llama.cpp...');
      
      try {
        // Fallback to legacy llama.cpp
        await _initializeLegacy();
      } catch (legacyError) {
        print('MLCAIService: Both MLC and legacy failed: $legacyError');
        _progressCallback?.call('❌ Both MLC and legacy initialization failed');
        throw Exception('Failed to initialize any AI service: MLC($e), Legacy($legacyError)');
      }
    }

    _isInitialized = true;
    print('MLCAIService: Initialized successfully (MLC: $_useMLC, Legacy: $_useLegacy)');
  }

  /// Initialize MLC-LLM service
  Future<void> _initializeMLC() async {
    _mlcService = MLCService();
    if (_progressCallback != null) {
      _mlcService!.setProgressCallback(_progressCallback!);
    }

    await _mlcService!.initialize();
    _useMLC = true;
    _progressCallback?.call('✅ MLC-LLM runtime ready! 🚀');
    print('MLCAIService: MLC-LLM initialized successfully');
  }

  /// Initialize legacy llama.cpp service as fallback
  Future<void> _initializeLegacy() async {
    _legacyService = RealLlamaService();
    if (_progressCallback != null) {
      _legacyService!.setProgressCallback(_progressCallback!);
    }

    await _legacyService!.initialize();
    _useLegacy = true;
    _progressCallback?.call('✅ Legacy llama.cpp ready');
    print('MLCAIService: Legacy service initialized as fallback');
  }

  /// Load MLC model (5-10x faster than GGUF)
  Future<bool> loadModel(MLCModel model) async {
    if (!_isInitialized) {
      throw Exception('AI service not initialized');
    }

    try {
      if (_useMLC) {
        _progressCallback?.call('🔄 Loading ${model.name} with MLC-LLM...');
        print('MLCAIService: Loading MLC model: ${model.name}');
        
        bool success = await _mlcService!.loadModel(model);
        if (success) {
          _currentModel = model;
          _progressCallback?.call('✅ ${model.name} loaded! (${model.vramMB.toInt()}MB VRAM)');
          print('MLCAIService: MLC model loaded successfully');
          return true;
        } else {
          throw Exception('MLC model loading failed');
        }
      } else if (_useLegacy) {
        // Convert MLCModel to legacy AIModel for compatibility
        AIModel legacyModel = AIModel(
          id: model.id,
          name: model.name,
          description: model.description,
          filename: model.filename.replaceAll('-MLC.zip', '.gguf'), // Convert to GGUF
          sizeGB: model.sizeGB,
        );
        
        _progressCallback?.call('🔄 Loading ${model.name} with legacy llama.cpp...');
        bool success = await _legacyService!.loadModel(legacyModel.filename);
        if (success) {
          _currentModel = model;
          _progressCallback?.call('✅ ${model.name} loaded (legacy mode)');
          return true;
        }
      }

      return false;
    } catch (e) {
      print('MLCAIService: Failed to load model: $e');
      _progressCallback?.call('❌ Failed to load ${model.name}: $e');
      return false;
    }
  }

  /// Generate AI response with GPU acceleration (MLC) or CPU fallback
  Future<String> generateResponse(
    String prompt, {
    int maxTokens = 150,
    double temperature = 0.7,
    double topP = 0.9,
    int topK = 40,
  }) async {
    if (!_isInitialized || _currentModel == null) {
      throw Exception('AI service not ready or no model loaded');
    }

    try {
      if (_useMLC) {
        // Use MLC-LLM for fast GPU-accelerated inference
        return await _mlcService!.generateResponse(
          prompt,
          maxTokens: maxTokens,
          temperature: temperature,
          topP: topP,
          topK: topK,
        );
      } else if (_useLegacy) {
        // Use legacy llama.cpp service
        return await _legacyService!.generateResponse(
          prompt,
          maxTokens: maxTokens,
          temperature: temperature,
        );
      } else {
        throw Exception('No AI service available');
      }
    } catch (e) {
      print('MLCAIService: Response generation failed: $e');
      rethrow;
    }
  }

  /// Stream response generation (real-time tokens)
  Stream<String> generateResponseStream(
    String prompt, {
    int maxTokens = 150,
    double temperature = 0.7,
    double topP = 0.9,
    int topK = 40,
  }) async* {
    if (!_isInitialized || _currentModel == null) {
      throw Exception('AI service not ready or no model loaded');
    }

    if (_useMLC) {
      // Use MLC streaming for real-time response
      yield* _mlcService!.generateResponseStream(
        prompt,
        maxTokens: maxTokens,
        temperature: temperature,
        topP: topP,
        topK: topK,
      );
    } else {
      // Legacy doesn't support streaming, return complete response
      String response = await generateResponse(
        prompt,
        maxTokens: maxTokens,
        temperature: temperature,
        topP: topP,
        topK: topK,
      );
      yield response;
    }
  }

  /// Get available MLC models for current device
  List<MLCModel> getAvailableModels() {
    if (_useMLC && _mlcService != null) {
      return _mlcService!.recommendedModels;
    }
    
    // Return all models if MLC not available
    return MLCModels.availableModels;
  }

  /// Get device capabilities
  Map<String, dynamic> getDeviceCapabilities() {
    if (_useMLC && _mlcService != null) {
      return _mlcService!.deviceCapabilities;
    }
    
    return {
      'supportsGPU': false,
      'vramBytes': 0,
      'deviceInfo': 'Legacy CPU-only mode',
    };
  }

  /// Get memory usage statistics
  Future<Map<String, dynamic>> getMemoryStats() async {
    if (_useMLC && _mlcService != null) {
      return await _mlcService!.getMemoryStats();
    }
    
    return {
      'vramUsed': 0,
      'vramTotal': 0,
      'systemRam': 0,
      'modelSize': _currentModel?.sizeGB ?? 0,
    };
  }

  /// Unload current model to free memory
  Future<void> unloadModel() async {
    if (_currentModel != null) {
      if (_useMLC && _mlcService != null) {
        await _mlcService!.unloadModel();
      } else if (_useLegacy && _legacyService != null) {
        await _legacyService!.unloadModel();
      }
      
      _currentModel = null;
      print('MLCAIService: Model unloaded');
    }
  }

  /// Dispose and cleanup service
  Future<void> dispose() async {
    await unloadModel();
    
    if (_mlcService != null) {
      await _mlcService!.dispose();
      _mlcService = null;
    }
    
    if (_legacyService != null) {
      await _legacyService!.dispose();
      _legacyService = null;
    }
    
    _isInitialized = false;
    _useMLC = false;
    _useLegacy = false;
    print('MLCAIService: Service disposed');
  }

  /// Set progress callback for loading updates
  void setProgressCallback(Function(String) callback) {
    _progressCallback = callback;
    _mlcService?.setProgressCallback(callback);
    _legacyService?.setProgressCallback(callback);
  }

  /// Get service status and performance info
  Map<String, dynamic> getServiceInfo() {
    return {
      'isInitialized': _isInitialized,
      'useMLC': _useMLC,
      'useLegacy': _useLegacy,
      'currentModel': _currentModel?.toJson(),
      'framework': _useMLC ? 'MLC-LLM + TVM' : 'llama.cpp',
      'acceleration': _useMLC ? 'GPU' : 'CPU',
      'expectedSpeedup': _useMLC ? '5-10x faster' : 'baseline',
    };
  }

  // Getters
  bool get isReady => _isInitialized && _currentModel != null;
  bool get usesMLC => _useMLC;
  bool get usesGPU => _useMLC;
  MLCModel? get currentModel => _currentModel;
  String get frameworkName => _useMLC ? 'MLC-LLM' : 'llama.cpp';
}
