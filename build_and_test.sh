#!/bin/bash

echo "🚀 Offline AI Companion - Build and Test Script"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "Please run this script from the offline_ai_companion directory"
    exit 1
fi

print_status "Starting build process..."

# Step 1: Clean previous builds
print_status "Step 1: Cleaning previous builds..."
flutter clean
cd android
./gradlew clean
cd ..

# Step 2: Get dependencies
print_status "Step 2: Getting Flutter dependencies..."
flutter pub get

# Step 3: Check if models are in assets
print_status "Step 3: Checking model assets..."
if [ -f "assets/models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf" ] && [ -f "assets/models/phi-2.Q4_K_M.gguf" ]; then
    print_success "Model files found in assets/models/"
    ls -lh assets/models/
else
    print_error "Model files not found in assets/models/"
    print_warning "Please ensure you have the following files:"
    print_warning "- assets/models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
    print_warning "- assets/models/phi-2.Q4_K_M.gguf"
    exit 1
fi

# Step 4: Build for Android
print_status "Step 4: Building for Android..."
cd android
./gradlew assembleDebug

if [ $? -eq 0 ]; then
    print_success "Android build completed successfully!"
else
    print_error "Android build failed!"
    print_warning "This might be due to missing Android SDK or NDK"
    print_warning "Please ensure you have:"
    print_warning "- Android SDK installed"
    print_warning "- Android NDK installed (version 27.0.12077973)"
    print_warning "- ANDROID_SDK_ROOT environment variable set"
    exit 1
fi

cd ..

# Step 5: Check APK location
APK_PATH="android/app/build/outputs/apk/debug/app-debug.apk"
if [ -f "$APK_PATH" ]; then
    print_success "APK created successfully!"
    print_status "APK location: $APK_PATH"
    print_status "APK size: $(du -h "$APK_PATH" | cut -f1)"
else
    print_error "APK not found at expected location"
    exit 1
fi

# Step 6: Install and test (if device is connected)
print_status "Step 6: Checking for connected devices..."
flutter devices

if flutter devices | grep -q "android"; then
    print_status "Android device detected. Installing app..."
    flutter install
    
    if [ $? -eq 0 ]; then
        print_success "App installed successfully!"
        print_status "Starting app for testing..."
        flutter run --debug
        
        print_status "App is now running!"
        print_status "Check the logs for model initialization status"
        print_status "You can also check logs with: adb logcat | grep -E '(MainActivity|LlamaCppWrapper|ModelService)'"
    else
        print_error "Failed to install app"
    fi
else
    print_warning "No Android device detected"
    print_status "To test the app:"
    print_status "1. Connect your Samsung A56 via USB"
    print_status "2. Enable USB debugging"
    print_status "3. Run: flutter devices"
    print_status "4. Run: flutter install"
    print_status "5. Run: flutter run --debug"
fi

print_status "Build and test process completed!"
print_status "If you encounter issues:"
print_status "1. Check the logs for detailed error messages"
print_status "2. Ensure all model files are in assets/models/"
print_status "3. Verify Android SDK and NDK are properly installed"
print_status "4. Check that the native llama.cpp library is being built correctly"
