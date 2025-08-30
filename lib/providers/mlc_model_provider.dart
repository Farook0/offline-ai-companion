import 'package:flutter/foundation.dart';
import 'package:offline_ai_companion/models/mlc_model.dart';
import 'package:offline_ai_companion/services/mlc_ai_service.dart';

/// Provider for MLC-LLM model management with GPU acceleration
class MLCModelProvider with ChangeNotifier {
  final MLCAIService _aiService = MLCAIService();
  
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isGenerating = false;
  MLCModel? _selectedModel;
  String _loadingProgress = '';
  String? _error;
  
  // Device capabilities
  bool _supportsGPU = false;
  int _deviceVramMB = 0;
  String _deviceInfo = '';
  
  // Performance metrics
  Map<String, dynamic> _memoryStats = {};
  Map<String, dynamic> _serviceInfo = {};

  /// Initialize MLC-LLM provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _setLoading(true, 'Initializing MLC-LLM...');
      _clearError();
      
      // Set up progress callback
      _aiService.setProgressCallback(_updateProgress);
      
      // Initialize AI service
      await _aiService.initialize();
      
      // Get device capabilities
      await _updateDeviceCapabilities();
      
      // Get service info
      _updateServiceInfo();
      
      // Select default model based on device capabilities
      await _selectDefaultModel();
      
      _isInitialized = true;
      _setLoading(false, '');
      
      print('MLCModelProvider: Initialized successfully');
    } catch (e) {
      _setError('Failed to initialize MLC-LLM: $e');
      _setLoading(false, '');
      print('MLCModelProvider: Initialization failed: $e');
    }
  }

  /// Update device capabilities
  Future<void> _updateDeviceCapabilities() async {
    try {
      final capabilities = _aiService.getDeviceCapabilities();
      _supportsGPU = capabilities['supportsGPU'] ?? false;
      _deviceVramMB = (capabilities['vramBytes'] ?? 0) ~/ (1024 * 1024);
      _deviceInfo = capabilities['deviceInfo'] ?? 'Unknown device';
      
      print('MLCModelProvider: Device - GPU: $_supportsGPU, VRAM: ${_deviceVramMB}MB');
      notifyListeners();
    } catch (e) {
      print('MLCModelProvider: Failed to get device capabilities: $e');
    }
  }

  /// Update service info
  void _updateServiceInfo() {
    _serviceInfo = _aiService.getServiceInfo();
    notifyListeners();
  }

  /// Select default model based on device capabilities
  Future<void> _selectDefaultModel() async {
    final availableModels = getAvailableModels();
    if (availableModels.isEmpty) {
      _setError('No compatible models found for this device');
      return;
    }

    // Select recommended model for device
    MLCModel defaultModel;
    if (_deviceVramMB > 0) {
      defaultModel = MLCModels.getRecommendedModel(
        vramBytes: _deviceVramMB * 1024 * 1024,
        prioritizeSpeed: _deviceVramMB < 2000, // Prioritize speed for <2GB VRAM
      );
    } else {
      // Fallback to smallest model if no VRAM info
      defaultModel = MLCModels.tinyLlama_11b;
    }

    await selectModel(defaultModel);
  }

  /// Get models compatible with current device
  List<MLCModel> getAvailableModels() {
    if (_deviceVramMB > 0) {
      return MLCModels.getModelsForVram(_deviceVramMB * 1024 * 1024);
    }
    
    // Return all models if no VRAM info
    return MLCModels.availableModels;
  }

  /// Select and load a model
  Future<void> selectModel(MLCModel model) async {
    if (_isLoading) {
      print('MLCModelProvider: Model loading in progress, ignoring new request');
      return;
    }

    try {
      _setLoading(true, 'Loading ${model.name}...');
      _clearError();
      
      print('MLCModelProvider: Selecting model: ${model.name}');
      
      // Check VRAM requirements
      if (_deviceVramMB > 0 && model.hasInsufficientVram(_deviceVramMB * 1024 * 1024)) {
        _updateProgress('⚠️ Warning: ${model.name} needs ${model.vramMB.toInt()}MB VRAM, device has ${_deviceVramMB}MB');
        await Future.delayed(Duration(seconds: 2)); // Show warning
      }
      
      // Load model
      bool success = await _aiService.loadModel(model);
      
      if (success) {
        _selectedModel = model;
        await _updateMemoryStats();
        _updateServiceInfo();
        _setLoading(false, '');
        print('MLCModelProvider: Model loaded successfully: ${model.name}');
      } else {
        throw Exception('Model loading failed');
      }
    } catch (e) {
      _setError('Failed to load ${model.name}: $e');
      _setLoading(false, '');
      print('MLCModelProvider: Model loading failed: $e');
    }
  }

  /// Generate AI response
  Future<String> generateResponse(
    String prompt, {
    int maxTokens = 150,
    double temperature = 0.7,
    double topP = 0.9,
    int topK = 40,
  }) async {
    if (!_isInitialized || _selectedModel == null) {
      throw Exception('Service not ready or no model loaded');
    }

    try {
      _setGenerating(true);
      
      print('MLCModelProvider: Generating response...');
      final response = await _aiService.generateResponse(
        prompt,
        maxTokens: maxTokens,
        temperature: temperature,
        topP: topP,
        topK: topK,
      );
      
      // Update memory stats after generation
      await _updateMemoryStats();
      
      _setGenerating(false);
      return response;
    } catch (e) {
      _setGenerating(false);
      print('MLCModelProvider: Response generation failed: $e');
      rethrow;
    }
  }

  /// Generate streaming response (real-time tokens)
  Stream<String> generateResponseStream(
    String prompt, {
    int maxTokens = 150,
    double temperature = 0.7,
    double topP = 0.9,
    int topK = 40,
  }) async* {
    if (!_isInitialized || _selectedModel == null) {
      throw Exception('Service not ready or no model loaded');
    }

    try {
      _setGenerating(true);
      
      yield* _aiService.generateResponseStream(
        prompt,
        maxTokens: maxTokens,
        temperature: temperature,
        topP: topP,
        topK: topK,
      );
      
      // Update memory stats after generation
      await _updateMemoryStats();
      _setGenerating(false);
    } catch (e) {
      _setGenerating(false);
      print('MLCModelProvider: Streaming failed: $e');
      rethrow;
    }
  }

  /// Update memory usage statistics
  Future<void> _updateMemoryStats() async {
    try {
      _memoryStats = await _aiService.getMemoryStats();
      notifyListeners();
    } catch (e) {
      print('MLCModelProvider: Failed to update memory stats: $e');
    }
  }

  /// Unload current model
  Future<void> unloadModel() async {
    if (_selectedModel != null) {
      await _aiService.unloadModel();
      _selectedModel = null;
      _memoryStats.clear();
      _updateServiceInfo();
      notifyListeners();
      print('MLCModelProvider: Model unloaded');
    }
  }

  /// Helper methods for state management
  void _setLoading(bool loading, String progress) {
    _isLoading = loading;
    _loadingProgress = progress;
    notifyListeners();
  }

  void _setGenerating(bool generating) {
    _isGenerating = generating;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _updateProgress(String progress) {
    _loadingProgress = progress;
    notifyListeners();
  }

  /// Dispose provider and cleanup
  @override
  void dispose() {
    _aiService.dispose();
    super.dispose();
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  MLCModel? get selectedModel => _selectedModel;
  String get loadingProgress => _loadingProgress;
  String? get error => _error;
  bool get hasError => _error != null;
  
  // Device info
  bool get supportsGPU => _supportsGPU;
  int get deviceVramMB => _deviceVramMB;
  String get deviceInfo => _deviceInfo;
  
  // Performance metrics
  Map<String, dynamic> get memoryStats => _memoryStats;
  Map<String, dynamic> get serviceInfo => _serviceInfo;
  
  // Status checks
  bool get isReady => _isInitialized && _selectedModel != null && !_isLoading;
  bool get usesMLC => _serviceInfo['useMLC'] ?? false;
  bool get usesGPU => usesMLC && _supportsGPU;
  String get frameworkName => _aiService.frameworkName;
  String get performanceMode => usesGPU ? 'GPU Accelerated' : 'CPU Only';
  
  // Get VRAM usage info
  String get vramUsageInfo {
    if (_memoryStats.isEmpty || !_supportsGPU) return 'N/A';
    
    final used = (_memoryStats['vramUsed'] ?? 0) ~/ (1024 * 1024);
    final total = (_memoryStats['vramTotal'] ?? 0) ~/ (1024 * 1024);
    
    if (total > 0) {
      final percentage = (used / total * 100).round();
      return '$used/$total MB ($percentage%)';
    }
    
    return '${used}MB used';
  }
}
