# MLC-LLM Libraries for Android

This directory should contain the required MLC-LLM and TVM runtime libraries for Android ARM64.

## Required Libraries

You need to download and place the following libraries in the `arm64-v8a/` subdirectory:

### 1. TVM Runtime Library
- **File**: `libtvm_runtime.so`
- **Source**: Download from [Apache TVM releases](https://github.com/apache/tvm/releases)
- **Version**: v0.15.0 or later
- **Architecture**: Android ARM64

### 2. MLC-LLM Library
- **File**: `libmlc_llm.so`
- **Source**: Download from [MLC-LLM releases](https://github.com/mlc-ai/mlc-llm/releases)
- **Version**: Latest stable release
- **Architecture**: Android ARM64

### 3. MLC Model Library
- **File**: `libmlc_model.so`
- **Source**: Generated from MLC model compilation
- **Architecture**: Android ARM64

## Download Instructions

### Option 1: Use MLC-LLM Build Script
```bash
# Clone MLC-LLM repository
git clone https://github.com/mlc-ai/mlc-llm.git
cd mlc-llm

# Build for Android ARM64
./scripts/build_android.sh

# Copy libraries to this directory
cp build/android/arm64-v8a/lib/*.so android/app/src/main/cpp/libs/arm64-v8a/
```

### Option 2: Download Pre-built Libraries
```bash
# Download TVM runtime
wget https://github.com/apache/tvm/releases/download/v0.15.0/tvm-android-arm64.tar.gz
tar -xzf tvm-android-arm64.tar.gz
cp tvm-android-arm64/lib/libtvm_runtime.so android/app/src/main/cpp/libs/arm64-v8a/

# Download MLC-LLM libraries
wget https://github.com/mlc-ai/mlc-llm/releases/download/latest/mlc-llm-android-arm64.tar.gz
tar -xzf mlc-llm-android-arm64.tar.gz
cp mlc-llm-android-arm64/lib/*.so android/app/src/main/cpp/libs/arm64-v8a/
```

## Verification

After downloading, verify that the following files exist:
- `arm64-v8a/libtvm_runtime.so`
- `arm64-v8a/libmlc_llm.so`
- `arm64-v8a/libmlc_model.so` (if available)

## Notes

- These libraries are required for the MLC-LLM integration to work properly
- Without these libraries, the app will fall back to the legacy llama.cpp implementation
- The libraries should be optimized for Android ARM64 architecture
- GPU acceleration requires OpenCL and Vulkan libraries to be available on the device


