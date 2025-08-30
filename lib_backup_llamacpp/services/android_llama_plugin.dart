import 'dart:io';
import 'package:flutter/services.dart';

class AndroidLlamaPlugin {
  static const MethodChannel _channel = MethodChannel('android_llama_plugin');
  
  // Initialize the plugin
  static Future<bool> initialize() async {
    if (!Platform.isAndroid) {
      return false;
    }
    
    try {
      final bool result = await _channel.invokeMethod('initialize');
      return result;
    } on PlatformException catch (e) {
      print('AndroidLlamaPlugin: Failed to initialize: ${e.message}');
      return false;
    }
  }
  
  // Load a model
  static Future<bool> loadModel(String modelPath) async {
    if (!Platform.isAndroid) {
      return false;
    }
    
    try {
      final bool result = await _channel.invokeMethod('loadModel', {
        'modelPath': modelPath,
      });
      return result;
    } on PlatformException catch (e) {
      print('AndroidLlamaPlugin: Failed to load model: ${e.message}');
      return false;
    }
  }
  
  // Generate response
  static Future<String> generateResponse(String prompt, {
    int maxTokens = 150,
    double temperature = 0.7,
  }) async {
    if (!Platform.isAndroid) {
      return 'Error: Not on Android platform';
    }
    
    try {
      final String result = await _channel.invokeMethod('generateResponse', {
        'prompt': prompt,
        'maxTokens': maxTokens,
        'temperature': temperature,
      });
      return result;
    } on PlatformException catch (e) {
      print('AndroidLlamaPlugin: Failed to generate response: ${e.message}');
      return 'Error: ${e.message}';
    }
  }
  
  // Unload model
  static Future<void> unloadModel() async {
    if (!Platform.isAndroid) {
      return;
    }
    
    try {
      await _channel.invokeMethod('unloadModel');
    } on PlatformException catch (e) {
      print('AndroidLlamaPlugin: Failed to unload model: ${e.message}');
    }
  }
  
  // Check if model is loaded
  static Future<bool> isModelLoaded() async {
    if (!Platform.isAndroid) {
      return false;
    }
    
    try {
      final bool result = await _channel.invokeMethod('isModelLoaded');
      return result;
    } on PlatformException catch (e) {
      print('AndroidLlamaPlugin: Failed to check model status: ${e.message}');
      return false;
    }
  }
  
  // Get model info
  static Future<Map<String, dynamic>> getModelInfo() async {
    if (!Platform.isAndroid) {
      return {'error': 'Not on Android platform'};
    }
    
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('getModelInfo');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      print('AndroidLlamaPlugin: Failed to get model info: ${e.message}');
      return {'error': e.message};
    }
  }
} 