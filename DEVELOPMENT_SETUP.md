# MLC-LLM Flutter App Development Setup

This guide helps other developers set up the development environment for the MLC-LLM Flutter application.

## Prerequisites

### 1. System Requirements
- macOS (for iOS development) or Linux/Windows (for Android development)
- Python 3.10
- Flutter SDK 3.0+
- Android SDK and NDK
- CMake 3.5+

### 2. Conda Environment Setup

```bash
# Create conda environment
conda create -n mlc python=3.10
conda activate mlc

# Install Python dependencies
pip install -r requirements.txt
```

### 3. Flutter Setup

```bash
# Install Flutter dependencies
flutter pub get

# Clean build cache
flutter clean
```

## MLC-LLM Integration

### Python Environment (Development/Testing)
The Python environment is used for:
- Testing MLC-LLM functionality
- Validating API calls
- Debugging model loading
- Development reference

### Android Native Integration
The Android app uses:
- Native C++ wrapper (`android/app/src/main/cpp/mlc_tvm_wrapper.cpp`)
- CMake build system (`android/app/src/main/cpp/CMakeLists.txt`)
- JNI bindings for Flutter communication
- ARM64 native libraries (downloaded separately)

## Key Files

### Python Dependencies
- `requirements.txt` - Python package requirements
- `DEVELOPMENT_SETUP.md` - This setup guide

### Android Integration
- `android/app/src/main/cpp/mlc_tvm_wrapper.cpp` - C++ wrapper
- `android/app/src/main/cpp/CMakeLists.txt` - Build configuration
- `android/app/src/main/cpp/libs/` - Native library directory

### Flutter App
- `lib/services/mlc_ai_service.dart` - MLC service integration
- `lib/providers/mlc_model_provider.dart` - Model management
- `assets/models/` - MLC model files

## Testing MLC-LLM

```bash
# Activate environment
conda activate mlc

# Test MLC-LLM installation
python -c "import mlc_llm; print('✅ MLC-LLM working!')"

# Test specific functionality
python -c "
from mlc_llm import MLCEngine
print('✅ MLCEngine imported successfully!')
"
```

## Building APK

```bash
# Clean and build
flutter clean
flutter pub get
flutter build apk --release
```

## Troubleshooting

### Common Issues

1. **Import Errors**: Ensure all compatibility fixes are applied
2. **Library Not Found**: Check symlinks in `/path/to/conda/envs/mlc/lib/`
3. **Build Failures**: Verify CMake and NDK installation

### Compatibility Fixes Applied

- Added `register_global_func` alias to `tvm`
- Created `tvm.base` compatibility module
- Added `Tensor` alias to `tvm.runtime`
- Created library symlinks for MLC-LLM dependencies

## Architecture Overview

```
Flutter App (Dart)
    ↓
JNI Interface
    ↓
C++ Wrapper (mlc_tvm_wrapper.cpp)
    ↓
MLC-LLM Native Libraries (ARM64)
    ↓
TVM Runtime
    ↓
MLC Model Files
```

## Development Workflow

1. **Test in Python**: Use MLC nightly CPU for development
2. **Write C++ Code**: Based on Python API reference
3. **Build APK**: Use native ARM64 libraries
4. **Test on Device**: Deploy and test on Android device

## Notes

- Python environment is for development only
- Final APK uses native ARM64 libraries
- MLC model files are included in app assets
- All compatibility issues have been resolved

