#include <jni.h>
#include <string>
#include <memory>
#include <android/log.h>
#include <fstream>
#include <vector>

// Android NDK compatibility - provide stub for posix_madvise
extern "C" {
    int android_posix_madvise_stub(void* addr, size_t len, int advice) {
        // Return success without doing anything
        // This is safe for Android where we don't rely on memory mapping optimizations
        return 0;
    }
}

// Modern llama.cpp includes
#include "llama.h"

#define LOG_TAG "LlamaCppWrapper"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// Global variables for llama.cpp context
static llama_context* g_ctx = nullptr;
static llama_model* g_model = nullptr;
static bool g_initialized = false;

// Helper functions
std::string jstringToString(JNIEnv* env, jstring jstr) {
    if (jstr == nullptr) return "";
    const char* chars = env->GetStringUTFChars(jstr, nullptr);
    std::string str(chars);
    env->ReleaseStringUTFChars(jstr, chars);
    return str;
}

jstring stringToJstring(JNIEnv* env, const std::string& str) {
    return env->NewStringUTF(str.c_str());
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_example_offline_1ai_1companion_MainActivity_initializeLlama(JNIEnv* env, jobject thiz) {
    try {
        LOGI("🔄 Initializing modern llama.cpp...");
        
        if (g_initialized) {
            LOGI("✅ llama.cpp already initialized");
            return JNI_TRUE;
        }
        
        // Initialize llama.cpp backend (modern API)
        llama_backend_init();
        g_initialized = true;
        
        LOGI("✅ Modern llama.cpp initialized successfully");
        return JNI_TRUE;
    } catch (const std::exception& e) {
        LOGE("❌ Failed to initialize llama.cpp: %s", e.what());
        return JNI_FALSE;
    } catch (...) {
        LOGE("❌ Failed to initialize llama.cpp: unknown error");
        return JNI_FALSE;
    }
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_example_offline_1ai_1companion_MainActivity_loadModelNative(JNIEnv* env, jobject thiz, jstring model_path) {
    try {
        if (!g_initialized) {
            LOGE("❌ llama.cpp not initialized");
            return JNI_FALSE;
        }
        
        std::string modelPath = jstringToString(env, model_path);
        LOGI("🔄 Loading model: %s", modelPath.c_str());
        
        // Check if model file exists
        std::ifstream file(modelPath);
        if (!file.good()) {
            LOGE("❌ Model file not found: %s", modelPath.c_str());
            return JNI_FALSE;
        }
        file.close();
        LOGI("✅ Model file found and accessible");
        
        // Clean up previous model if any
        if (g_ctx != nullptr) {
            llama_free(g_ctx);
            g_ctx = nullptr;
        }
        if (g_model != nullptr) {
            llama_model_free(g_model);
            g_model = nullptr;
        }
        
        // Load model with modern API
        llama_model_params model_params = llama_model_default_params();
        
        // Configure for mobile
        model_params.n_gpu_layers = 0;  // CPU only for compatibility
        model_params.use_mmap = true;   // Memory mapping for efficiency
        model_params.use_mlock = false; // No memory locking on mobile
        
        LOGI("🔄 Loading model with modern API...");
        g_model = llama_model_load_from_file(modelPath.c_str(), model_params);
        
        if (g_model == nullptr) {
            LOGE("❌ Failed to load model: %s", modelPath.c_str());
            return JNI_FALSE;
        }
        
        // Create context with SMART mobile optimization for complete responses
        llama_context_params ctx_params = llama_context_default_params();
        ctx_params.n_ctx = 512;        // Sufficient context for complete answers
        ctx_params.n_threads = 2;      // Use 2 threads for better speed
        ctx_params.n_batch = 32;       // Balanced batch size for efficiency
        ctx_params.flash_attn = false; // Disable flash attention
        ctx_params.offload_kqv = false; // Disable KV offloading
        
        LOGI("🔄 Creating context...");
        g_ctx = llama_init_from_model(g_model, ctx_params);
        
        if (g_ctx == nullptr) {
            LOGE("❌ Failed to create context");
            llama_model_free(g_model);
            g_model = nullptr;
            return JNI_FALSE;
        }
        
        LOGI("✅ Model loaded successfully with modern API");
        return JNI_TRUE;
        
    } catch (const std::exception& e) {
        LOGE("❌ Exception loading model: %s", e.what());
        return JNI_FALSE;
    } catch (...) {
        LOGE("❌ Unknown error loading model");
        return JNI_FALSE;
    }
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_example_offline_1ai_1companion_MainActivity_generateResponseNative(
    JNIEnv* env, jobject thiz, jstring prompt, jint maxTokens, jdouble temperature) {
    
    try {
        if (g_ctx == nullptr || g_model == nullptr) {
            LOGE("❌ No model loaded");
            return stringToJstring(env, "Error: No model loaded");
        }
        
        std::string promptStr = jstringToString(env, prompt);
        LOGI("🔄 Generating response for user prompt: %s", promptStr.c_str());
        
        // REAL AI INFERENCE: Generate actual intelligent responses using the GGUF model
        
        // Verify we have a valid model and context
        if (g_model == nullptr || g_ctx == nullptr) {
            LOGE("❌ Model or context is null");
            return stringToJstring(env, "Error: Model not properly loaded");
        }
        
        try {
            // Get the vocabulary from the model
            const auto* vocab = llama_model_get_vocab(g_model);
            if (vocab == nullptr) {
                LOGE("❌ Failed to get vocabulary");
                return stringToJstring(env, "Error: Failed to get vocabulary");
            }
            
            // Smart prompt template for accurate and helpful responses
            std::string formattedPrompt = "You are a helpful AI assistant. Answer the user's question completely and accurately.\n\nUser: " + promptStr + "\n\nAssistant:";
            
            // Reasonable prompt size limit for mobile
            if (formattedPrompt.length() > 300) {
                std::string userPrompt = promptStr;
                if (userPrompt.length() > 200) {
                    userPrompt = userPrompt.substr(0, 200) + "...";
                }
                formattedPrompt = "You are a helpful AI assistant. Answer the user's question completely and accurately.\n\nUser: " + userPrompt + "\n\nAssistant:";
            }
            
            LOGI("📝 Formatted prompt: %s", formattedPrompt.c_str());
            
            std::vector<llama_token> tokens_input;
            tokens_input.resize(formattedPrompt.size() + 1);
            
            const int n_tokens = llama_tokenize(vocab, formattedPrompt.c_str(), formattedPrompt.length(), 
                                              tokens_input.data(), tokens_input.size(), false, true);
            
            if (n_tokens <= 0) {
                LOGE("❌ Failed to tokenize prompt");
                return stringToJstring(env, "Error: Failed to tokenize prompt");
            }
            
            tokens_input.resize(n_tokens);
            LOGI("✅ Tokenized prompt: %d tokens", n_tokens);
            
            // Clear memory/KV cache first
            llama_memory_t memory = llama_get_memory(g_ctx);
            llama_memory_clear(memory, true);
            
            // Process tokens efficiently in reasonable batches
            const int max_batch_size = std::min(n_tokens, 64); // Larger batch for efficiency
            llama_batch batch = llama_batch_init(max_batch_size, 0, 1);
            
            // Process all prompt tokens at once for maximum speed
            batch.n_tokens = n_tokens;
            
            // Add all tokens to batch
            for (int i = 0; i < n_tokens; i++) {
                batch.token[i] = tokens_input[i];
                batch.pos[i] = i;
                batch.n_seq_id[i] = 1;
                batch.seq_id[i][0] = 0;
                batch.logits[i] = false;
            }
            
            // Only need logits for the last token
            batch.logits[n_tokens - 1] = true;
            
            LOGI("🔄 Decoding prompt (%d tokens)", n_tokens);
            
            // Decode all tokens at once
            if (llama_decode(g_ctx, batch) != 0) {
                LOGE("❌ Failed to decode prompt");
                llama_batch_free(batch);
                return stringToJstring(env, "Error: Failed to decode prompt");
            }
            
            // Set up simple sampling chain for mobile
            auto sparams = llama_sampler_chain_default_params();
            auto sampler = llama_sampler_chain_init(sparams);
            
            // Balanced samplers for quality and speed
            llama_sampler_chain_add(sampler, llama_sampler_init_temp(0.7f)); // Good creativity balance
            llama_sampler_chain_add(sampler, llama_sampler_init_top_k(20)); // Sufficient variety for quality
            llama_sampler_chain_add(sampler, llama_sampler_init_top_p(0.9f, 1)); // Add top-p for better quality (min_keep=1)
            llama_sampler_chain_add(sampler, llama_sampler_init_dist(12345)); // Random seed
            
            // Generate response tokens with mobile limits
            std::string response = "";
            int n_generated = 0;
            const int max_tokens = std::min(static_cast<int>(maxTokens), 50); // Allow complete responses
            
            while (n_generated < max_tokens) {
                // Reduced logging overhead - only log every 10 tokens
                if (n_generated > 0 && n_generated % 10 == 0) {
                    LOGI("🔄 Generated %d tokens so far...", n_generated);
                }
                
                // Sample the next token
                const llama_token next_token = llama_sampler_sample(sampler, g_ctx, -1);
                
                // Check for end of generation
                if (llama_vocab_is_eog(vocab, next_token)) {
                    LOGI("✅ End of generation token reached");
                    break;
                }
                
                // Convert token to text (optimized)
                char token_str[64]; // Larger buffer for efficiency
                const int n_chars = llama_token_to_piece(vocab, next_token, token_str, sizeof(token_str), 0, true);
                if (n_chars > 0) {
                    response.append(token_str, n_chars); // More efficient than += operator
                }
                
                // Accept the token (important for stateful samplers)
                llama_sampler_accept(sampler, next_token);
                
                // Prepare simple batch for next token
                batch.n_tokens = 1;
                batch.token[0] = next_token;
                batch.pos[0] = n_tokens + n_generated;
                batch.n_seq_id[0] = 1;
                batch.seq_id[0][0] = 0;
                batch.logits[0] = true;
                
                                // Fast decode with optimized error handling
                if (llama_decode(g_ctx, batch) != 0) {
                    LOGE("❌ Failed to decode token %d", n_generated);
                    // Return what we have so far rather than breaking
                    if (!response.empty()) {
                        LOGI("✅ Returning partial response (%d tokens)", n_generated);
                        break;
                    }
                    response = "I apologize, but I'm having trouble processing your request.";
                    break;
                }
            
                n_generated++;
                
                // Safety check: if response is getting long, stop
                if (response.length() > 100) {
                    LOGI("✅ Response length limit reached");
                break;
                }
            }
            
            // Cleanup
            llama_sampler_free(sampler);
            llama_batch_free(batch);
            
            LOGI("✅ Generated %d tokens: %s", n_generated, response.c_str());
            
            // Return the actual AI-generated response
            if (response.empty()) {
                return stringToJstring(env, "I understand your message, but I'm having trouble generating a response right now. Please try again.");
            }
            
            return stringToJstring(env, response);
            
        } catch (const std::exception& e) {
            LOGE("❌ Exception in inference: %s", e.what());
            return stringToJstring(env, "Error during AI inference: " + std::string(e.what()));
        }
        
    } catch (const std::exception& e) {
        LOGE("❌ Exception generating response: %s", e.what());
        return stringToJstring(env, "Error: Exception during generation");
    } catch (...) {
        LOGE("❌ Unknown error generating response");
        return stringToJstring(env, "Error: Unknown error during generation");
    }
}

extern "C" JNIEXPORT void JNICALL
Java_com_example_offline_1ai_1companion_MainActivity_unloadModelNative(JNIEnv* env, jobject thiz) {
    try {
        LOGI("🔄 Unloading model...");
        
        if (g_ctx != nullptr) {
            llama_free(g_ctx);
            g_ctx = nullptr;
        }
        
        if (g_model != nullptr) {
            llama_model_free(g_model);
            g_model = nullptr;
        }
        
        LOGI("✅ Model unloaded successfully");
    } catch (...) {
        LOGE("❌ Error unloading model");
    }
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_example_offline_1ai_1companion_MainActivity_isModelLoadedNative(JNIEnv* env, jobject thiz) {
    return (g_ctx != nullptr && g_model != nullptr) ? JNI_TRUE : JNI_FALSE;
} 