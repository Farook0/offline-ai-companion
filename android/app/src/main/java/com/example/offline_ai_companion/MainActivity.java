package com.example.offline_ai_companion;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodCall;
import android.util.Log;
import android.content.Context;
import android.content.res.AssetManager;
import android.os.AsyncTask;
import java.io.File;
import java.io.InputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;
import java.util.zip.ZipInputStream;
import java.util.zip.ZipEntry;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import java.lang.reflect.Type;

// Direct TVM JNI calls (same approach as Llamao)
// No high-level wrappers, just direct native calls to TVM runtime

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "mlc_llm_plugin";
    private static final String TAG = "MLCLLMActivity";
    
    // MLC-LLM integration (exact same pattern as Llamao)
    private static boolean _modelLoaded = false;
    private static String _currentModelId = null;
    private static ExecutorService _executor = Executors.newSingleThreadExecutor();
    private static Map<String, Object> _mlcConfig = null;
    
    // TVM runtime handles (direct native pointers)
    private static long _tvmRuntimeHandle = 0;
    private static long _modelHandle = 0;
    
    // Load TVM runtime library (same as Llamao)
    static {
        try {
            System.loadLibrary("tvm4j_runtime_packed");
            Log.d(TAG, "✅ TVM runtime library loaded successfully");
        } catch (UnsatisfiedLinkError e) {
            Log.e(TAG, "❌ TVM runtime library not available: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    // Native TVM method declarations (direct JNI interface)
    // These will be implemented in native code later
    private long tvmCreateRuntime() {
        // Stub implementation - return success for now
        Log.d(TAG, "📱 TVM Runtime creation (stub)");
        return 1; // Simulate success
    }
    
    private long tvmLoadModule(long runtimeHandle, String modelPath) {
        // Stub implementation - return success for now
        Log.d(TAG, "📱 TVM Module loading (stub): " + modelPath);
        return 1; // Simulate success
    }
    
    private String tvmRunInference(long moduleHandle, String input) {
        // Stub implementation - return test response for now
        Log.d(TAG, "📱 TVM Inference (stub): " + input);
        return "This is a test response from TVM stub. Input was: " + input;
    }
    
    private void tvmReleaseModule(long moduleHandle) {
        Log.d(TAG, "📱 TVM Module release (stub)");
    }
    
    private void tvmReleaseRuntime(long runtimeHandle) {
        Log.d(TAG, "📱 TVM Runtime release (stub)");
    }
    
    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler(
                (call, result) -> {
                    switch (call.method) {
                        case "initialize":
                            handleInitialize(result);
                            break;
                        case "loadModel":
                            handleLoadModel(call, result);
                            break;
                        case "generateResponse":
                            handleGenerateResponse(call, result);
                            break;
                        case "unloadModel":
                            handleUnloadModel(result);
                            break;
                        case "isModelLoaded":
                            handleIsModelLoaded(result);
                            break;
                        case "getModelInfo":
                            handleGetModelInfo(result);
                            break;
                        case "getAvailableModels":
                            handleGetAvailableModels(result);
                            break;
                        default:
                            result.notImplemented();
                            break;
                    }
                }
            );
    }
    
    private void handleInitialize(MethodChannel.Result result) {
        try {
            Log.d(TAG, "🚀 Initializing MLC-LLM with TVM runtime...");
            
            // Load MLC configuration
            loadMLCConfig();
            
            // Initialize TVM Runtime (like Llamao)
            _tvmRuntimeHandle = tvmCreateRuntime();
            
            if (_tvmRuntimeHandle > 0) {
                Log.d(TAG, "✅ TVM runtime initialized successfully!");
                result.success(true);
            } else {
                Log.e(TAG, "❌ TVM runtime initialization failed");
                result.success(false);
            }
        } catch (Exception e) {
            Log.e(TAG, "❌ Failed to initialize MLC-LLM: " + e.getMessage());
            e.printStackTrace();
            result.error("INIT_ERROR", "Failed to initialize MLC-LLM", e.getMessage());
        }
    }
    
    private void loadMLCConfig() {
        try {
            Log.d(TAG, "📋 Loading MLC config from assets...");
            AssetManager assetManager = getAssets();
            InputStream inputStream = assetManager.open("mlc-app-config.json");
            byte[] buffer = new byte[inputStream.available()];
            inputStream.read(buffer);
            inputStream.close();
            
            String configJson = new String(buffer, "UTF-8");
            Log.d(TAG, "📋 Config JSON loaded, length: " + configJson.length());
            Log.d(TAG, "📋 Config JSON preview: " + configJson.substring(0, Math.min(200, configJson.length())));
            
            Gson gson = new Gson();
            Type type = new TypeToken<Map<String, Object>>(){}.getType();
            _mlcConfig = gson.fromJson(configJson, type);
            
            Log.d(TAG, "✅ MLC config loaded successfully");
            Log.d(TAG, "📋 Config keys: " + _mlcConfig.keySet());
        } catch (Exception e) {
            Log.e(TAG, "❌ Failed to load MLC config: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    private void handleLoadModel(MethodCall call, MethodChannel.Result result) {
        try {
            String modelId = call.argument("modelId");
            if (modelId == null) {
                modelId = "Llama-3.2-1B-Instruct-q4f16_0-MLC"; // Default to fast model
            }
            
            final String finalModelId = modelId; // Make final for lambda
            Log.d(TAG, "🔄 Loading MLC model: " + finalModelId);
            
            // Run model loading on background thread
            _executor.execute(() -> {
                try {
                    // Find model in config
                    Map<String, Object> modelInfo = findModelInConfig(finalModelId);
                    if (modelInfo == null) {
                        result.error("MODEL_NOT_FOUND", "Model not found in config: " + finalModelId, null);
                        return;
                    }
                    
                    // Get model path
                    String modelPath = getModelPath(finalModelId);
                    
                    if (modelPath != null) {
                        // Load TVM module (like Llamao)
                        _modelHandle = tvmLoadModule(_tvmRuntimeHandle, modelPath);
                        
                        if (_modelHandle > 0) {
                            _modelLoaded = true;
                            _currentModelId = finalModelId;
                            Log.d(TAG, "✅ TVM model loaded successfully: " + finalModelId);
                            result.success(true);
                        } else {
                            Log.e(TAG, "❌ Failed to load TVM module for: " + finalModelId);
                            result.success(false);
                        }
                    } else {
                        Log.e(TAG, "❌ Model path is null for: " + finalModelId);
                        result.error("MODEL_PATH_ERROR", "Could not extract model: " + finalModelId, null);
                    }
                } catch (Exception e) {
                    Log.e(TAG, "❌ Exception loading MLC model: " + e.getMessage());
                    e.printStackTrace();
                    result.error("LOAD_ERROR", "Exception loading model", e.getMessage());
                }
            });
        } catch (Exception e) {
            Log.e(TAG, "❌ Exception in handleLoadModel: " + e.getMessage());
            e.printStackTrace();
            result.error("LOAD_ERROR", "Exception in handleLoadModel", e.getMessage());
        }
    }
    
    private void handleGenerateResponse(MethodCall call, MethodChannel.Result result) {
        try {
            String prompt = call.argument("prompt");
            Integer maxTokens = call.argument("maxTokens");
            Double temperature = call.argument("temperature");
            
            if (maxTokens == null) maxTokens = 50;
            if (temperature == null) temperature = 0.7;
            
            final String finalPrompt = prompt; // Make final for lambda
            final int finalMaxTokens = maxTokens; // Make final for lambda
            final double finalTemperature = temperature; // Make final for lambda
            
            Log.d(TAG, "🔄 Generating response for: \"" + finalPrompt + "\"");
            
            if (!_modelLoaded || _modelHandle == 0) {
                Log.e(TAG, "❌ No model loaded");
                result.error("MODEL_NOT_LOADED", "No model is currently loaded", null);
                return;
            }
            
            // Run generation on background thread
            _executor.execute(() -> {
                try {
                    // Format prompt for TVM inference
                    String formattedInput = String.format(
                        "{\"prompt\": \"%s\", \"max_tokens\": %d, \"temperature\": %.2f}", 
                        finalPrompt, finalMaxTokens, finalTemperature
                    );
                    
                    // Generate response using TVM module (like Llamao)
                    String response = tvmRunInference(_modelHandle, formattedInput);
                    
                    if (response != null && !response.isEmpty()) {
                        Log.d(TAG, "✅ Generated response: " + response.substring(0, Math.min(50, response.length())) + "...");
                        result.success(response);
                    } else {
                        Log.e(TAG, "❌ Empty response from MLC generation");
                        result.error("EMPTY_RESPONSE", "Generated response is empty", null);
                    }
                } catch (Exception e) {
                    Log.e(TAG, "❌ Exception during MLC generation: " + e.getMessage());
                    e.printStackTrace();
                    result.error("GENERATE_ERROR", "Exception during generation", e.getMessage());
                }
            });
        } catch (Exception e) {
            Log.e(TAG, "❌ Exception in handleGenerateResponse: " + e.getMessage());
            e.printStackTrace();
            result.error("GENERATE_ERROR", "Exception in handleGenerateResponse", e.getMessage());
        }
    }
    
    private void handleUnloadModel(MethodChannel.Result result) {
        try {
            if (_modelLoaded && _modelHandle > 0) {
                tvmReleaseModule(_modelHandle);
                _modelHandle = 0;
                _modelLoaded = false;
                _currentModelId = null;
                Log.d(TAG, "✅ TVM model unloaded successfully");
            }
            result.success(null);
        } catch (Exception e) {
            Log.e(TAG, "❌ Exception unloading TVM model: " + e.getMessage());
            result.error("UNLOAD_ERROR", "Exception unloading model", e.getMessage());
        }
    }
    
    private void handleIsModelLoaded(MethodChannel.Result result) {
        result.success(_modelLoaded);
    }
    
    private void handleGetModelInfo(MethodChannel.Result result) {
        try {
            Map<String, Object> info = new HashMap<>();
            info.put("loaded", _modelLoaded);
            info.put("platform", "Android MLC-LLM");
            info.put("runtime", "TVM + GPU Acceleration");
            info.put("current_model", _currentModelId != null ? _currentModelId : "None");
            info.put("gpu_support", true);
            info.put("framework", "MLC-LLM v0.15.0");
            result.success(info);
        } catch (Exception e) {
            Log.e(TAG, "❌ Exception getting model info: " + e.getMessage());
            result.error("INFO_ERROR", "Exception getting model info", e.getMessage());
        }
    }
    
    private void handleGetAvailableModels(MethodChannel.Result result) {
        try {
            if (_mlcConfig != null) {
                result.success(_mlcConfig.get("model_list"));
            } else {
                result.success(new ArrayList<>());
            }
        } catch (Exception e) {
            Log.e(TAG, "❌ Exception getting available models: " + e.getMessage());
            result.error("MODELS_ERROR", "Exception getting available models", e.getMessage());
        }
    }
    
    private Map<String, Object> findModelInConfig(String modelId) {
        if (_mlcConfig == null) {
            Log.e(TAG, "❌ MLC config is null!");
            return null;
        }
        
        Log.d(TAG, "🔍 Looking for model ID: '" + modelId + "'");
        Log.d(TAG, "📋 MLC config keys: " + _mlcConfig.keySet());
        
        Object modelListObj = _mlcConfig.get("model_list");
        if (!(modelListObj instanceof List)) {
            Log.e(TAG, "❌ model_list is not a List, it's: " + (modelListObj != null ? modelListObj.getClass().getSimpleName() : "null"));
            return null;
        }
        
        List<Object> modelList = (List<Object>) modelListObj;
        Log.d(TAG, "📋 Found " + modelList.size() + " models in config");
        
        for (Object modelObj : modelList) {
            if (modelObj instanceof Map) {
                Map<String, Object> model = (Map<String, Object>) modelObj;
                String configModelId = (String) model.get("model_id");
                Log.d(TAG, "🔍 Checking model: '" + configModelId + "' vs '" + modelId + "'");
                if (modelId.equals(configModelId)) {
                    Log.d(TAG, "✅ Found matching model: " + modelId);
                    return model;
                }
            }
        }
        
        Log.e(TAG, "❌ Model not found in config: " + modelId);
        return null;
    }
    
    private String getModelPath(String modelId) {
        // Extract model from assets if needed (same approach as Llamao)
        // Map model ID to actual asset filename
        String assetPath;
        if (modelId.equals("Llama-3.2-1B-Instruct-q4f16_0-MLC")) {
            assetPath = "models/Llama-3.2-1B-Instruct-q4f16_0-MLC 6.36.51 PM.zip";
        } else {
            assetPath = modelId + ".zip";
        }
        String extractedPath = getFilesDir().getAbsolutePath() + "/mlc_models/" + modelId;
        
        Log.d(TAG, "🔍 Checking model path for: " + modelId);
        Log.d(TAG, "📦 Asset path: " + assetPath);
        Log.d(TAG, "📁 Extract path: " + extractedPath);
        
        // Check if already extracted
        File extractedDir = new File(extractedPath);
        if (extractedDir.exists() && extractedDir.isDirectory()) {
            // Verify it's not empty
            File[] files = extractedDir.listFiles();
            if (files != null && files.length > 0) {
                Log.d(TAG, "✅ Model already extracted at: " + extractedPath + " (" + files.length + " files)");
                return extractedPath;
            } else {
                Log.w(TAG, "⚠️ Extracted directory is empty, re-extracting...");
                extractedDir.delete();
            }
        }
        
        // Extract from assets (same as Llamao does)
        try {
            Log.d(TAG, "🔄 Model not found, extracting from assets...");
            extractModelFromAssets(assetPath, extractedPath);
            
            // Verify extraction was successful
            File extractedDirVerify = new File(extractedPath);
            if (extractedDirVerify.exists() && extractedDirVerify.listFiles() != null && extractedDirVerify.listFiles().length > 0) {
                Log.d(TAG, "✅ Model extraction verified: " + extractedPath);
                return extractedPath;
            } else {
                Log.e(TAG, "❌ Model extraction verification failed");
                return null;
            }
        } catch (Exception e) {
            Log.e(TAG, "❌ Failed to extract model: " + e.getMessage());
            e.printStackTrace();
            return null;
        }
    }
    
    private void extractModelFromAssets(String assetPath, String extractPath) throws IOException {
        Log.d(TAG, "📦 Extracting MLC model from: " + assetPath + " to: " + extractPath);
        
        AssetManager assetManager = getAssets();
        InputStream inputStream = assetManager.open(assetPath);
        
        // Create extraction directory
        File extractDir = new File(extractPath);
        if (!extractDir.exists()) {
            extractDir.mkdirs();
        }
        
        // Use ZipInputStream to extract (same as Llamao)
        ZipInputStream zipInputStream = new ZipInputStream(inputStream);
        ZipEntry entry;
        byte[] buffer = new byte[8192];
        
        Log.d(TAG, "🔄 Starting ZIP extraction...");
        int extractedFiles = 0;
        
        while ((entry = zipInputStream.getNextEntry()) != null) {
            String entryName = entry.getName();
            File outputFile = new File(extractDir, entryName);
            
            Log.d(TAG, "📄 Extracting: " + entryName);
            
            if (entry.isDirectory()) {
                // Create directory
                outputFile.mkdirs();
            } else {
                // Create parent directories if needed
                File parentDir = outputFile.getParentFile();
                if (parentDir != null && !parentDir.exists()) {
                    parentDir.mkdirs();
                }
                
                // Extract file
                FileOutputStream outputStream = new FileOutputStream(outputFile);
                int length;
                long totalBytes = 0;
                
                while ((length = zipInputStream.read(buffer)) > 0) {
                    outputStream.write(buffer, 0, length);
                    totalBytes += length;
                }
                
                outputStream.close();
                extractedFiles++;
                
                Log.d(TAG, "✅ Extracted: " + entryName + " (" + totalBytes + " bytes)");
            }
            
            zipInputStream.closeEntry();
        }
        
        zipInputStream.close();
        inputStream.close();
        
        Log.d(TAG, "🎉 MLC model extraction completed! Files extracted: " + extractedFiles);
        Log.d(TAG, "📁 Model available at: " + extractPath);
    }
}