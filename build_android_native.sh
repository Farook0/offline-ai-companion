#!/bin/bash

# Build script for Android native llama.cpp integration
echo "🔧 Building Android native llama.cpp integration..."

# Set up environment
export ANDROID_NDK_HOME=$ANDROID_SDK_ROOT/ndk/27.0.12077973
export PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin:$PATH

# Clean previous builds
echo "🧹 Cleaning previous builds..."
cd android
./gradlew clean
cd ..

# Build for ARM64 (Samsung A56)
echo "🏗️ Building for ARM64..."
cd android
./gradlew assembleDebug

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "📱 APK location: android/app/build/outputs/apk/debug/app-debug.apk"
    echo ""
    echo "🚀 Next steps:"
    echo "1. Install the APK on your Samsung A56"
    echo "2. Open the app and try loading a model"
    echo "3. Check the logs with: adb logcat | grep -E '(MainActivity|LlamaCppWrapper)'"
else
    echo "❌ Build failed!"
    echo "Check the error messages above for details."
fi

cd .. 