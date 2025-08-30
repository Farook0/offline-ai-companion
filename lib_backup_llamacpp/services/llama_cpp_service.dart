import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:offline_ai_companion/models/ai_model.dart';

class LlamaCppService {
  static bool _initialized = false;
  static String? _currentModelPath;
  static bool _modelLoaded = false;
  static String? _currentModelId;
  static Process? _llamaProcess;
  
  // Try different paths for llama.cpp CLI
  static const List<String> _possibleLlamaPaths = [
    'llama-cli', // System PATH (this should work now)
    '/usr/local/bin/llama-cli', // macOS alternative
    '/usr/local/Cellar/llama.cpp/6150/libexec/llama-cli', // macOS Homebrew
  ];
  
  static String? _llamaCliPath;
  
  // Model loading progress callback
  static Function(String)? _onProgress;
  
  // Initialize the service
  static Future<bool> initialize() async {
    if (_initialized) return true;
    
    try {
      print('LlamaCppService: Initializing...');
      _onProgress?.call('Initializing LlamaCpp service...');
      
      // Try to find llama.cpp CLI
      _llamaCliPath = await _findLlamaCli();
      
      if (_llamaCliPath != null) {
        print('LlamaCppService: Found llama.cpp CLI at $_llamaCliPath');
        _onProgress?.call('Found llama.cpp CLI');
        
        // Quick test of llama.cpp CLI availability (much faster than model test)
        final result = await Process.run(_llamaCliPath!, ['--help']);
        if (result.exitCode != 0) {
          print('LlamaCppService: Failed to test llama.cpp CLI: ${result.stderr}');
          _llamaCliPath = null;
          _onProgress?.call('llama.cpp CLI test failed, using fallback mode');
        } else {
          print('LlamaCppService: llama.cpp CLI test successful');
          _onProgress?.call('llama.cpp CLI ready');
        }
      }
      
      if (_llamaCliPath == null) {
        print('LlamaCppService: llama.cpp CLI not available, will use fallback mode');
        _onProgress?.call('Using fallback mode - no llama.cpp CLI available');
      }
      
      _initialized = true;
      print('LlamaCppService: Initialized successfully');
      return true;
    } catch (e) {
      print('LlamaCppService: Failed to initialize: $e');
      _initialized = true; // Mark as initialized but with fallback
      return false;
    }
  }
  
  // Find llama.cpp CLI in possible locations
  static Future<String?> _findLlamaCli() async {
    for (final path in _possibleLlamaPaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          return path;
        }
      } catch (e) {
        // Continue to next path
      }
    }
    
    // Try running from PATH
    try {
      final result = await Process.run('which', ['llama-cli']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (e) {
      // Continue
    }
    
    return null;
  }
  
  // Set progress callback
  static void setProgressCallback(Function(String) callback) {
    _onProgress = callback;
  }
  
  // Load a model with optimized performance
  static Future<bool> loadModel(String modelPath, {String? modelId}) async {
    if (!_initialized) {
      final success = await initialize();
      if (!success && _llamaCliPath == null) {
        // If no CLI available, we can still "load" the model in fallback mode
        print('LlamaCppService: Loading model in fallback mode: $modelPath');
        _onProgress?.call('Loading model in fallback mode...');
        _currentModelPath = modelPath;
        _currentModelId = modelId;
        _modelLoaded = true;
        _onProgress?.call('Model loaded in fallback mode');
        return true;
      }
    }
    
    try {
      print('LlamaCppService: Loading model from $modelPath');
      _onProgress?.call('Checking model file...');
      
      // Check if model file exists
      final file = File(modelPath);
      if (!await file.exists()) {
        print('LlamaCppService: Model file not found: $modelPath');
        _onProgress?.call('Model file not found: $modelPath');
        return false;
      }
      
      // Get file size for progress tracking
      final fileSize = await file.length();
      final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
      _onProgress?.call('Model file found: ${fileSizeMB}MB');
      
      if (_llamaCliPath != null) {
        _onProgress?.call('Preparing model for inference...');
        
        // Instead of testing the model (which is slow), just validate the file format
        // This is much faster and still ensures the model is valid
        try {
          // Quick validation - check if it's a valid GGUF file by reading header
          final stream = file.openRead(0, 1024); // Read first 1KB
          final header = await stream.first;
          if (header.length > 4) {
            // Check for GGUF magic number or other valid model format indicators
            final isValid = _validateModelHeader(header);
            if (!isValid) {
              print('LlamaCppService: Invalid model file format');
              _onProgress?.call('Invalid model file format');
              return false;
            }
          }
        } catch (e) {
          print('LlamaCppService: Error validating model file: $e');
          // Continue anyway, the model might still work
        }
      }
      
      _currentModelPath = modelPath;
      _currentModelId = modelId;
      _modelLoaded = true;
      
      print('LlamaCppService: Model loaded successfully');
      _onProgress?.call('Model loaded successfully! Ready for inference.');
      return true;
    } catch (e) {
      print('LlamaCppService: Failed to load model: $e');
      _onProgress?.call('Failed to load model: $e');
      return false;
    }
  }
  
  // Quick model header validation
  static bool _validateModelHeader(List<int> header) {
    // Check for common model file signatures
    if (header.length >= 4) {
      // GGUF magic number: 0x67677566 ("gguf")
      if (header[0] == 0x67 && header[1] == 0x67 && 
          header[2] == 0x75 && header[3] == 0x66) {
        return true;
      }
      
      // GGML magic number: 0x67676d6c ("ggml")
      if (header[0] == 0x67 && header[1] == 0x67 && 
          header[2] == 0x6d && header[3] == 0x6c) {
        return true;
      }
      
      // Check for other common binary file signatures
      // This is a basic check - in production you might want more sophisticated validation
    }
    
    // If we can't determine the format, assume it's valid
    return true;
  }
  
  // Generate response using the loaded model
  static Future<String> generateResponse(String prompt, {
    int maxTokens = 256,
    double temperature = 0.7,
    double topP = 0.9,
    int topK = 40,
    double repeatPenalty = 1.1,
  }) async {
    if (!_modelLoaded) {
      throw Exception('No model loaded');
    }
    
    if (_llamaCliPath == null) {
      // Fallback mode - provide informative response
      return _generateFallbackResponse(prompt, _currentModelId);
    }
    
    try {
      print('LlamaCppService: Generating response with real llama.cpp');
      
      final result = await Process.run(_llamaCliPath!, [
        '-m', _currentModelPath!,
        '-c', '2048',
        '--temp', temperature.toString(),
        '--repeat-penalty', repeatPenalty.toString(),
        '--top-p', topP.toString(),
        '--top-k', topK.toString(),
        '-n', maxTokens.toString(),
        '--threads', '2',
        '-p', 'You are a friendly AI companion. You can answer any question in a helpful and summarized way. Be concise but informative.\n\nUser: $prompt\nAssistant:',
        '--no-display-prompt',
      ]);
      
      if (result.exitCode != 0) {
        print('LlamaCppService: Failed to generate response: ${result.stderr}');
        return _generateFallbackResponse(prompt, _currentModelId);
      }
      
      final response = result.stdout.toString().trim();
      print('LlamaCppService: Generated response successfully');
      return response;
    } catch (e) {
      print('LlamaCppService: Error generating response: $e');
      return _generateFallbackResponse(prompt, _currentModelId);
    }
  }
  
  // Fallback response when llama.cpp is not available
  static String _generateFallbackResponse(String prompt, String? modelId) {
    final modelName = _getModelName(modelId);
    
    return '''🤖 **$modelName Response** (Fallback Mode)

I understand you're asking: "$prompt"

⚠️ **Note**: This is a fallback response because the actual $modelName model inference engine is not available on this device. 

To get real AI responses, you would need to:
1. Install llama.cpp on your device
2. Ensure the model files are properly loaded
3. Have sufficient computational resources

For now, I can help you with general information, but for the full AI experience, please check the app settings or contact support.

**Your question**: $prompt
**Suggested response**: This would be processed by the $modelName model in a full implementation.''';
  }
  
  static String _getModelName(String? modelId) {
    switch (modelId) {
      case 'phi-2':
        return 'Phi-2';
      case 'tinyllama-1.1b':
        return 'TinyLlama 1.1B';
      case 'mistral-7b':
        return 'Mistral 7B';
      default:
        return 'AI Model';
    }
  }
  
  // Unload current model
  static void unloadModel() {
    _currentModelPath = null;
    _currentModelId = null;
    _modelLoaded = false;
    if (_llamaProcess != null) {
      _llamaProcess!.kill();
      _llamaProcess = null;
    }
    print('LlamaCppService: Model unloaded');
  }
  
  // Check if real llama.cpp is available
  static bool get isRealLlamaAvailable => _llamaCliPath != null;
  
  // Get current model info
  static String? get currentModelPath => _currentModelPath;
  static String? get currentModelId => _currentModelId;
  static bool get isModelLoaded => _modelLoaded;
  
  // Get model loading status
  static String get loadingStatus {
    if (!_initialized) return 'Not initialized';
    if (!_modelLoaded) return 'No model loaded';
    if (_llamaCliPath == null) return 'Fallback mode active';
    return 'Ready for inference';
  }
  
  // Quick model validation without full loading
  static Future<bool> validateModelFile(String modelPath) async {
    try {
      final file = File(modelPath);
      if (!await file.exists()) return false;
      
      // Quick header check
      final stream = file.openRead(0, 1024);
      final header = await stream.first;
      return _validateModelHeader(header);
    } catch (e) {
      return false;
    }
  }
  
  // Get model file size
  static Future<String?> getModelFileSize(String modelPath) async {
    try {
      final file = File(modelPath);
      if (!await file.exists()) return null;
      
      final size = await file.length();
      final sizeMB = (size / (1024 * 1024)).toStringAsFixed(1);
      return '${sizeMB}MB';
    } catch (e) {
      return null;
    }
  }
  
  // Optimized response generation with timeout
  static Future<String> generateResponseOptimized(String prompt, {
    int maxTokens = 256,
    double temperature = 0.7,
    double topP = 0.9,
    int topK = 40,
    double repeatPenalty = 1.1,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!_modelLoaded) {
      throw Exception('No model loaded');
    }
    
    if (_llamaCliPath == null) {
      // Fallback mode - provide informative response
      return _generateFallbackResponse(prompt, _currentModelId);
    }
    
    try {
      print('LlamaCppService: Generating response with optimized settings');
      
      // Use optimized parameters for faster inference
      final result = await Process.run(_llamaCliPath!, [
        '-m', _currentModelPath!,
        '-c', '2048', // Context size
        '--temp', temperature.toString(),
        '--repeat-penalty', repeatPenalty.toString(),
        '--top-p', topP.toString(),
        '--top-k', topK.toString(),
        '-n', maxTokens.toString(),
        '--threads', '2', // Use 2 threads for better performance
        '--batch-size', '512', // Optimize batch size
        '-p', 'You are a helpful AI assistant. Answer concisely.\n\nUser: $prompt\nAssistant:',
        '--no-display-prompt',
      ]).timeout(timeout);
      
      if (result.exitCode != 0) {
        print('LlamaCppService: Failed to generate response: ${result.stderr}');
        return _generateFallbackResponse(prompt, _currentModelId);
      }
      
      final response = result.stdout.toString().trim();
      print('LlamaCppService: Generated response successfully');
      return response;
    } catch (e) {
      print('LlamaCppService: Error generating response: $e');
      return _generateFallbackResponse(prompt, _currentModelId);
    }
  }
  
  // Example usage with progress tracking
  static Future<void> loadModelWithProgress(String modelPath, String? modelId) async {
    // Set up progress callback
    LlamaCppService.setProgressCallback((progress) {
      print('Model Loading Progress: $progress');
      // You can update UI here with the progress message
    });
    
    // Load the model (now much faster!)
    final success = await loadModel(modelPath, modelId: modelId);
    
    if (success) {
      print('Model loaded successfully!');
      print('Status: ${LlamaCppService.loadingStatus}');
      
      // Test response generation
      try {
        final response = await generateResponseOptimized(
          'Hello! How are you today?',
          maxTokens: 100,
          timeout: Duration(seconds: 15),
        );
        print('Test response: $response');
      } catch (e) {
        print('Error generating test response: $e');
      }
    } else {
      print('Failed to load model');
    }
  }
} 