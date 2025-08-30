import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:offline_ai_companion/models/ai_model.dart';

class ModelService {
  static const String _modelsDir = 'models';
  
  // Get the models directory path
  static Future<String> getModelsDirectory() async {
    if (Platform.isAndroid) {
      // On Android, use the app's internal storage
      final appDir = await getApplicationDocumentsDirectory();
      final modelsPath = '${appDir.path}/$_modelsDir';
      
      // Create directory if it doesn't exist
      final dir = Directory(modelsPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        print('ModelService: Created models directory: $modelsPath');
      }
      
      return modelsPath;
    } else {
      // On other platforms, use assets
      return 'assets/$_modelsDir';
    }
  }
  
  // Copy model from assets to app directory (Android only)
  static Future<bool> copyModelToAppDirectory(String modelFileName) async {
    if (!Platform.isAndroid) {
      print('ModelService: Not on Android, skipping copy');
      return true;
    }
    
    try {
      print('ModelService: Starting copy process for $modelFileName');
      
      final modelsDir = await getModelsDirectory();
      final destinationPath = '$modelsDir/$modelFileName';
      print('ModelService: Destination path: $destinationPath');
      
      // Check if model already exists and has content
      final destinationFile = File(destinationPath);
      if (await destinationFile.exists()) {
        final fileSize = await destinationFile.length();
        if (fileSize > 0) {
          print('ModelService: Model already exists with size $fileSize bytes at $destinationPath');
          return true;
        } else {
          print('ModelService: Model file exists but is empty, will recopy');
          await destinationFile.delete();
        }
      }
      
      // Copy from assets using Flutter's asset system
      try {
        final assetPath = 'assets/$_modelsDir/$modelFileName';
        print('ModelService: Loading asset from: $assetPath');
        
        // Check if asset exists in manifest first
        final manifestExists = await _checkAssetInManifest(assetPath);
        if (!manifestExists) {
          print('ModelService: Asset $assetPath not found in manifest');
          return false;
        }
        
        final byteData = await rootBundle.load(assetPath);
        final bytes = byteData.lengthInBytes;
        print('ModelService: Asset loaded, size: $bytes bytes');
        
        if (bytes == 0) {
          print('ModelService: Asset is empty');
          return false;
        }
        
        // Ensure destination directory exists
        await destinationFile.parent.create(recursive: true);
        
        // Write file in chunks to handle large files better
        final sink = destinationFile.openWrite();
        try {
          final buffer = byteData.buffer.asUint8List();
          sink.add(buffer);
          await sink.flush();
          await sink.close();
        } catch (e) {
          await sink.close();
          throw e;
        }
        
        print('ModelService: Model copied to $destinationPath');
        
        // Verify the file was created and has correct size
        if (await destinationFile.exists()) {
          final fileSize = await destinationFile.length();
          print('ModelService: File verified, size: $fileSize bytes');
          
          if (fileSize == bytes) {
            print('ModelService: File size matches expected size');
            return true;
          } else {
            print('ModelService: File size mismatch. Expected: $bytes, Got: $fileSize');
            return false;
          }
        } else {
          print('ModelService: File was not created successfully');
          return false;
        }
      } catch (e) {
        print('ModelService: Error loading asset $modelFileName: $e');
        return false;
      }
    } catch (e) {
      print('ModelService: Error copying model: $e');
      return false;
    }
  }
  
  // Check if asset exists in manifest
  static Future<bool> _checkAssetInManifest(String assetPath) async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifest = json.decode(manifestContent);
      
      // Check if the asset path exists in the manifest
      final exists = manifest.containsKey(assetPath);
      print('ModelService: Asset $assetPath ${exists ? 'found' : 'not found'} in manifest');
      return exists;
    } catch (e) {
      print('ModelService: Error checking asset manifest: $e');
      return false;
    }
  }
  
  // Test if assets are accessible
  static Future<bool> testAssetAccess() async {
    try {
      print('ModelService: Testing asset access...');
      
      // Try to load the asset manifest
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      print('ModelService: Asset manifest loaded successfully');
      
      // Parse the manifest
      final Map<String, dynamic> manifest = json.decode(manifestContent);
      print('ModelService: Asset manifest parsed, found ${manifest.keys.length} assets');
      
      // Check if our model files are in the manifest
      final modelFiles = [
        'assets/models/qwen2.5-1.5b-instruct-q4_k_m.gguf',  // Qwen2.5 1.5B model
      ];
      
      bool allModelsFound = true;
      for (final modelFile in modelFiles) {
        if (manifest.containsKey(modelFile)) {
          print('ModelService: ✅ Found $modelFile in asset manifest');
        } else {
          print('ModelService: ❌ NOT found $modelFile in asset manifest');
          allModelsFound = false;
        }
      }
      
      if (!allModelsFound) {
        print('ModelService: Some model files are missing from assets');
        print('ModelService: Available model-related assets:');
        manifest.keys.where((key) => key.contains('model')).forEach((key) {
          print('ModelService: - $key');
        });
      }
      
      return allModelsFound;
    } catch (e) {
      print('ModelService: Error testing asset access: $e');
      return false;
    }
  }

  // Get available models - FAST VERSION (no slow file operations)
  static Future<List<AIModel>> getAvailableModels() async {
    final models = <AIModel>[];
    
    try {
      final modelsDir = await getModelsDirectory();
      print('ModelService: Looking for models in: $modelsDir');
      
      final dir = Directory(modelsDir);
      
      if (await dir.exists()) {
        print('ModelService: Models directory exists');
        
        // TESTING: Only use the Qwen2 model for now
        final modelFiles = [
          'qwen2.5-1.5b-instruct-q4_k_m.gguf',    // Qwen2.5 1.5B 1.0GB model
        ];
        
        for (final modelFileName in modelFiles) {
          final modelPath = '$modelsDir/$modelFileName';
          final modelFile = File(modelPath);
          
          if (await modelFile.exists()) {
            print('ModelService: Found model file: $modelFileName');
            
            // Create model without checking file size (faster)
            final model = _createModelFromFileName(modelFileName, modelPath);
            if (model != null) {
              models.add(model);
              print('ModelService: Added model: ${model.name}');
            }
          } else {
            print('ModelService: Model file not found: $modelFileName');
          }
        }
      } else {
        print('ModelService: Models directory does not exist, creating it...');
        await dir.create(recursive: true);
      }
      
      print('ModelService: Found ${models.length} valid models total');
      
      // If no models found, try to copy them quickly
      if (models.isEmpty) {
        print('ModelService: No models found, attempting quick copy...');
        await _quickCopyModels();
        
        // Check again after copy
        for (final modelFileName in ['qwen2.5-1.5b-instruct-q4_k_m.gguf']) {
          final modelPath = '$modelsDir/$modelFileName';
          final modelFile = File(modelPath);
          
          if (await modelFile.exists()) {
            final model = _createModelFromFileName(modelFileName, modelPath);
            if (model != null) {
              models.add(model);
              print('ModelService: Added model after copy: ${model.name}');
            }
          }
        }
      }
      
      return models;
    } catch (e) {
      print('ModelService: Error getting available models: $e');
      return [];
    }
  }
  
  // Quick model copy without reading entire files
  static Future<void> _quickCopyModels() async {
    try {
      final modelsDir = await getModelsDirectory();
      final modelFiles = [
        'qwen2.5-1.5b-instruct-q4_k_m.gguf',  // Qwen2.5 1.5B model
      ];
      
      for (final modelFile in modelFiles) {
        final destinationPath = '$modelsDir/$modelFile';
        final destinationFile = File(destinationPath);
        
        if (!await destinationFile.exists()) {
          print('ModelService: Quick copying $modelFile...');
          try {
            final assetPath = 'assets/models/$modelFile';
            final byteData = await rootBundle.load(assetPath);
            final bytes = byteData.buffer.asUint8List();
            await destinationFile.writeAsBytes(bytes);
            print('ModelService: Quick copy completed for $modelFile');
          } catch (e) {
            print('ModelService: Quick copy failed for $modelFile: $e');
          }
        }
      }
    } catch (e) {
      print('ModelService: Error in quick copy: $e');
    }
  }
  
  // Debug directory contents
  static Future<void> _debugDirectoryContents(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        print('ModelService: Directory contents:');
        final files = await dir.list(recursive: true).toList();
        for (final file in files) {
          if (file is File) {
            final size = await file.length();
            print('ModelService: - ${file.path} (${size} bytes)');
          } else if (file is Directory) {
            print('ModelService: - ${file.path} (directory)');
          }
        }
      } else {
        print('ModelService: Directory does not exist: $dirPath');
      }
    } catch (e) {
      print('ModelService: Error debugging directory: $e');
    }
  }
  
  // Create model from file name
  static AIModel? _createModelFromFileName(String fileName, String filePath) {
    print('ModelService: Creating model from filename: $fileName');
    
    switch (fileName) {
      case 'qwen2.5-1.5b-instruct-q4_k_m.gguf':
        return AIModel(
          id: 'qwen2.5-1_5b',
          name: 'Qwen2.5 1.5B',
          description: 'Latest Alibaba Qwen2.5 1.5B with improved reasoning and instruction following. Complete 1.0GB model for optimal performance.',
          version: '1.5B Q4_K_M',
          filePath: filePath,
          parameters: 1500000000,
          format: 'GGUF',
          isAvailable: true,
        );
      // Removed old Q4_K_M model
      // Removed Phi-2 - too large for mobile
      case 'mistral-7b-instruct.Q4_K_M.gguf':
        return AIModel(
          id: 'mistral-7b',
          name: 'Mistral 7B',
          description: 'Mistral 7B is a 7B parameter language model with strong reasoning and instruction-following capabilities.',
          version: '7B',
          filePath: filePath,
          parameters: 7000000000,
          format: 'GGUF',
          isAvailable: true,
        );
      default:
        // Create a generic model for unknown files
        final baseId = fileName.replaceAll('.gguf', '').toLowerCase();
        print('ModelService: Creating generic model with ID: $baseId');
        return AIModel(
          id: baseId,
          name: fileName.replaceAll('.gguf', ''),
          description: 'GGUF model file',
          version: 'Unknown',
          filePath: filePath,
          parameters: 0,
          format: 'GGUF',
          isAvailable: true,
        );
    }
  }
  
  // Check if model file exists
  static Future<bool> modelExists(String modelFileName) async {
    try {
      final modelsDir = await getModelsDirectory();
      final modelPath = '$modelsDir/$modelFileName';
      final file = File(modelPath);
      final exists = await file.exists();
      
      if (exists) {
        // Also check if file has content
        final size = await file.length();
        print('ModelService: Model $modelFileName exists with size $size bytes');
        return size > 0;
      } else {
        print('ModelService: Model $modelFileName does not exist');
        return false;
      }
    } catch (e) {
      print('ModelService: Error checking model existence: $e');
      return false;
    }
  }
  
  // Get model file size
  static Future<int?> getModelFileSize(String modelFileName) async {
    try {
      final modelsDir = await getModelsDirectory();
      final modelPath = '$modelsDir/$modelFileName';
      final file = File(modelPath);
      
      if (await file.exists()) {
        final size = await file.length();
        print('ModelService: Model $modelFileName size: $size bytes');
        return size;
      } else {
        print('ModelService: Model $modelFileName does not exist');
      }
      return null;
    } catch (e) {
      print('ModelService: Error getting model file size: $e');
      return null;
    }
  }

  // Get model by ID
  static Future<AIModel?> getModelById(String modelId) async {
    try {
      final availableModels = await getAvailableModels();
      for (final model in availableModels) {
        if (model.id == modelId) {
          print('ModelService: Found model $modelId: ${model.name}');
          return model;
        }
      }
      print('ModelService: Model $modelId not found');
      return null;
    } catch (e) {
      print('ModelService: Error getting model by ID: $e');
      return null;
    }
  }

  // Validate model file integrity
  static Future<bool> validateModelFile(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        print('ModelService: Model file does not exist: $filePath');
        return false;
      }
      
      final size = await file.length();
      if (size == 0) {
        print('ModelService: Model file is empty: $filePath');
        return false;
      }
      
      // Check if it's a valid GGUF file (basic check)
      final bytes = await file.openRead(0, 4).first;
      final header = String.fromCharCodes(bytes);
      
      if (header == 'GGUF') {
        print('ModelService: Valid GGUF file: $filePath ($size bytes)');
        return true;
      } else {
        print('ModelService: Invalid GGUF header in file: $filePath');
        return false;
      }
    } catch (e) {
      print('ModelService: Error validating model file: $e');
      return false;
    }
  }

  // Clean up corrupted or empty model files
  static Future<void> cleanupCorruptedModels() async {
    try {
      print('ModelService: Starting cleanup of corrupted models...');
      final modelsDir = await getModelsDirectory();
      final dir = Directory(modelsDir);
      
      if (!await dir.exists()) {
        print('ModelService: Models directory does not exist');
        return;
      }
      
      final files = await dir.list().toList();
      for (final file in files) {
        if (file is File && file.path.endsWith('.gguf')) {
          final isValid = await validateModelFile(file.path);
          if (!isValid) {
            print('ModelService: Removing corrupted model: ${file.path}');
            await file.delete();
          }
        }
      }
      
      print('ModelService: Cleanup completed');
    } catch (e) {
      print('ModelService: Error during cleanup: $e');
    }
  }
}