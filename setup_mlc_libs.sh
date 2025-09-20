#!/bin/bash

# MLC-LLM Library Setup Script for Android
# This script downloads and sets up the required MLC-LLM libraries

set -e

echo "🚀 Setting up MLC-LLM libraries for Android..."

# Create directories
mkdir -p android/app/src/main/cpp/libs/arm64-v8a
cd android/app/src/main/cpp/libs

# Download TVM Runtime Library
echo "📦 Setting up TVM Runtime Library..."
if [ ! -f "arm64-v8a/libtvm_runtime.so" ]; then
    echo "⚠️ Pre-built TVM Android ARM64 libraries are not available from official releases"
    echo "📝 You need to either:"
    echo "   1. Build TVM from source for Android ARM64"
    echo "   2. Use the TVM libraries that come with MLC-LLM"
    echo "   3. Get the libraries from a custom build"
    echo ""
    echo "🔧 Building TVM for Android ARM64:"
    echo "   git clone https://github.com/apache/tvm.git"
    echo "   cd tvm"
    echo "   mkdir build && cd build"
    echo "   cmake -DUSE_ANDROID=ON -DUSE_LLVM=ON -DUSE_OPENCL=ON .."
    echo "   make -j4"
    echo ""
    echo "📦 Or use MLC-LLM's bundled TVM libraries (recommended)"
else
    echo "✅ TVM Runtime Library already exists"
fi

# Download MLC-LLM Library
echo "📦 Downloading MLC-LLM Library..."
if [ ! -f "arm64-v8a/libmlc_llm.so" ]; then
    # Try to download from MLC-LLM releases
    wget -O mlc-llm-android-arm64.tar.gz https://github.com/mlc-ai/mlc-llm/releases/download/latest/mlc-llm-android-arm64.tar.gz || {
        echo "⚠️ Pre-built MLC-LLM library not available, you may need to build it from source"
        echo "📝 Please follow the instructions in libs/README.md to build MLC-LLM libraries"
    }
    
    if [ -f "mlc-llm-android-arm64.tar.gz" ]; then
        tar -xzf mlc-llm-android-arm64.tar.gz
        cp mlc-llm-android-arm64/lib/*.so arm64-v8a/
        rm -rf mlc-llm-android-arm64.tar.gz mlc-llm-android-arm64
        echo "✅ MLC-LLM Library downloaded"
    fi
else
    echo "✅ MLC-LLM Library already exists"
fi

# Verify libraries
echo "🔍 Verifying libraries..."
if [ -f "arm64-v8a/libtvm_runtime.so" ]; then
    echo "✅ libtvm_runtime.so found"
else
    echo "❌ libtvm_runtime.so missing"
fi

if [ -f "arm64-v8a/libmlc_llm.so" ]; then
    echo "✅ libmlc_llm.so found"
else
    echo "❌ libmlc_llm.so missing - you may need to build it from source"
fi

echo ""
echo "🎉 MLC-LLM library setup complete!"
echo ""
echo "📝 Next steps:"
echo "1. If libmlc_llm.so is missing, build it from source following libs/README.md"
echo "2. Run 'flutter clean && flutter pub get'"
echo "3. Build the APK with 'flutter build apk --release'"
echo ""
echo "🔧 For building MLC-LLM from source:"
echo "   git clone https://github.com/mlc-ai/mlc-llm.git"
echo "   cd mlc-llm"
echo "   ./scripts/build_android.sh"
echo "   cp build/android/arm64-v8a/lib/*.so android/app/src/main/cpp/libs/arm64-v8a/"


