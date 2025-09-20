# Offline AI Companion - MLC-LLM Flutter App

A Flutter application that integrates MLC-LLM (Machine Learning Compilation for Large Language Models) to provide offline AI chat capabilities on Android devices.

## 🚀 Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd offline_ai_companion

# Set up Python environment (for testing MLC-LLM)
conda create -n mlc python=3.10.18
conda activate mlc
pip install -r requirements.txt

# Download MLC-LLM libraries (REQUIRED for Android build)
chmod +x setup_mlc_libs.sh
./setup_mlc_libs.sh

# Set up Flutter and build
flutter pub get
flutter build apk --release
```

## 📋 Table of Contents

- [System Requirements](#system-requirements)
- [Dependencies](#dependencies)
- [Architecture](#architecture)
- [Installation](#installation)
- [Building APK](#building-apk)
- [Project Structure](#project-structure)
- [Development](#development)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## 🖥️ System Requirements

### Development Environment
- **Operating System**: macOS 10.15+ / Linux Ubuntu 18.04+ / Windows 10+
- **Python**: 3.10.18 (exact version tested)
- **Flutter**: 3.32.8 (exact version tested)
- **Dart**: 3.8.1 (comes with Flutter)
- **Android SDK**: API Level 21+ (Android 5.0+)
- **Android NDK**: r21e or later
- **CMake**: 4.1.0 (exact version tested)
- **Conda**: 4.10.0+

### Target Device
- **Android**: API Level 21+ (Android 5.0+)
- **Architecture**: ARM64 (aarch64)
- **RAM**: 4GB+ recommended
- **Storage**: 2GB+ free space for models

## 📦 Dependencies

### ⚠️ IMPORTANT: MLC Libraries Required
**Before building the APK, you MUST have the MLC-LLM libraries:**

```bash
# Run the setup script to check and guide you through library setup
chmod +x setup_mlc_libs.sh
./setup_mlc_libs.sh
```

**Required Libraries:**
- `libtvm_runtime.so` (Apache TVM runtime for Android ARM64)
- `libmlc_llm.so` (MLC-LLM library for Android ARM64)

**Note:** These libraries are NOT available as pre-built downloads. You need to:
1. **Build from source** (recommended for development)
2. **Use MLC-LLM's bundled libraries** (if available)
3. **Get from a custom build** (if you have access)

**Without these libraries, the app will not work!**

### ✅ Tested Versions (Exact)
The following versions have been tested and verified to work together:

| Component | Version | Notes |
|-----------|---------|-------|
| Python | 3.10.18 | Exact version tested |
| Flutter | 3.32.8 | Stable channel |
| Dart | 3.8.1 | Comes with Flutter |
| MLC-LLM | 0.20.0.dev0 | Development version |
| Apache TVM | 0.10.0 | Runtime engine |
| Apache TVM FFI | 0.1.0b4 | Foreign Function Interface |
| NumPy | 1.26.4 | Compatible with TVM |
| CMake | 4.1.0 | Build system |

### Python Dependencies (Development/Testing)
```txt
# Core MLC-LLM packages
mlc-llm==0.20.0.dev0
apache-tvm==0.10.0
apache-tvm-ffi==0.1.0b4

# Build dependencies
cmake==4.1.0
numpy==1.26.4

# System dependencies
setuptools>=40.0.0
wheel>=0.30.0
```

### Flutter Dependencies
```yaml
# pubspec.yaml
dependencies:
  flutter: ^3.32.8
  provider: ^6.1.1
  path_provider: ^2.1.1
  shared_preferences: ^2.2.2
  sqflite: ^2.3.0
  permission_handler: ^11.0.1
  device_info_plus: ^9.1.1

dev_dependencies:
  flutter_test: ^3.16.0
  flutter_lints: ^3.0.0
```

### Native Dependencies (Android)
```cmake
# CMakeLists.txt
target_link_libraries(mlc_tvm_wrapper
    ${log-lib}
    ${android-lib}
    tvm_runtime
    mlc_llm
    dl
    opencl
    vulkan
)
```

## 🏗️ Architecture

### High-Level Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter UI    │    │   Dart Layer    │    │   Native Layer  │
│                 │    │                 │    │                 │
│ • Chat Screen   │◄──►│ • Providers     │◄──►│ • JNI Interface │
│ • Model Screen  │    │ • Services      │    │ • C++ Wrapper   │
│ • Settings      │    │ • Models        │    │ • MLC-LLM Libs  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Detailed Component Flow
```
Flutter App (Dart)
    ↓
Provider Pattern (State Management)
    ↓
Service Layer (MLC Service)
    ↓
JNI Interface (Method Channel)
    ↓
C++ Wrapper (mlc_tvm_wrapper.cpp)
    ↓
MLC-LLM Native Libraries (ARM64)
    ↓
TVM Runtime
    ↓
MLC Model Files (assets/models/)
```

### Key Components

1. **Flutter Layer** (`lib/`)
   - UI components and screens
   - State management with Provider
   - Business logic and services

2. **Native Layer** (`android/app/src/main/cpp/`)
   - JNI interface for Flutter communication
   - C++ wrapper for MLC-LLM integration
   - CMake build configuration

3. **Model Layer** (`assets/models/`)
   - MLC model files and configurations
   - Tokenizer and parameter files

## 🛠️ Installation

### 1. Clone Repository
```bash
git clone <repository-url>
cd offline_ai_companion
```

### 2. Set Up Python Environment
```bash
# Create conda environment with exact Python version
conda create -n mlc python=3.10.18.0
conda activate mlc

# Install Python dependencies
pip install -r requirements.txt

# Verify installation
python -c "import mlc_llm; print('✅ MLC-LLM installed successfully!')"
```

### 3. Set Up Flutter Environment
```bash
# Install Flutter dependencies
flutter pub get

# Verify Flutter setup
flutter doctor
```

### 4. Set Up Android Development
```bash
# Install Android SDK and NDK
# Set ANDROID_HOME and ANDROID_NDK_HOME environment variables

# Verify Android setup
flutter doctor --android-licenses
```

## 🔨 Building APK

### Development Build
```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build debug APK
flutter build apk --debug
```

### Release Build
```bash
# Clean and build release APK
flutter clean
flutter pub get
flutter build apk --release

# APK will be generated at:
# build/app/outputs/flutter-apk/app-release.apk
```

### Build with Specific Architecture
```bash
# Build for ARM64 only (recommended for MLC-LLM)
flutter build apk --release --target-platform android-arm64
```

## 📁 Project Structure

```
offline_ai_companion/
├── android/                          # Android-specific code
│   ├── app/
│   │   ├── build.gradle.kts         # Android build configuration
│   │   └── src/main/
│   │       ├── cpp/                 # Native C++ code
│   │       │   ├── mlc_tvm_wrapper.cpp  # MLC-LLM C++ wrapper
│   │       │   ├── CMakeLists.txt   # CMake build configuration
│   │       │   └── libs/            # Native library directory
│   │       └── AndroidManifest.xml  # Android app manifest
│   └── build.gradle.kts             # Root Android build file
├── assets/                           # App assets
│   ├── models/                      # MLC model files
│   │   ├── mlc-chat-config.json    # MLC chat configuration
│   │   ├── tokenizer.json          # Tokenizer configuration
│   │   └── params_shard_*.bin      # Model parameter files
│   └── mlc-app-config.json         # MLC app configuration
├── lib/                             # Flutter Dart code
│   ├── models/                      # Data models
│   │   ├── ai_model.dart           # AI model data structure
│   │   ├── chat_message.dart       # Chat message model
│   │   └── mlc_model.dart          # MLC-specific model
│   ├── providers/                   # State management
│   │   ├── ai_model_provider.dart  # AI model state provider
│   │   ├── chat_provider.dart      # Chat state provider
│   │   └── mlc_model_provider.dart # MLC model provider
│   ├── screens/                     # UI screens
│   │   ├── chat_screen.dart        # Main chat interface
│   │   ├── home_screen.dart        # Home screen
│   │   ├── models_screen.dart      # Model selection screen
│   │   └── settings_screen.dart    # Settings screen
│   ├── services/                    # Business logic
│   │   ├── mlc_ai_service.dart     # MLC AI service
│   │   ├── mlc_service.dart        # MLC service implementation
│   │   └── model_service.dart      # Model management service
│   ├── widgets/                     # Reusable UI components
│   │   ├── chat_input.dart         # Chat input widget
│   │   ├── message_bubble.dart     # Message display widget
│   │   └── model_card.dart         # Model selection card
│   └── main.dart                    # App entry point
├── requirements.txt                 # Python dependencies
├── DEVELOPMENT_SETUP.md            # Development setup guide
├── pubspec.yaml                    # Flutter dependencies
└── README.md                       # This file
```

## 💻 Development

### Running in Development Mode
```bash
# Start Flutter app in debug mode
flutter run

# Run with specific device
flutter run -d <device-id>

# Hot reload during development
# Press 'r' in terminal or save files in IDE
```

### Testing MLC-LLM Integration
```bash
# Activate Python environment
conda activate mlc

# Test MLC-LLM functionality
python -c "
import mlc_llm
from mlc_llm import MLCEngine
print('✅ MLC-LLM integration working!')
print(f'Version: {mlc_llm.__version__}')
"
```

### Code Structure Guidelines

1. **Models** (`lib/models/`): Data structures and serialization
2. **Providers** (`lib/providers/`): State management with Provider pattern
3. **Services** (`lib/services/`): Business logic and external integrations
4. **Screens** (`lib/screens/`): UI screens and navigation
5. **Widgets** (`lib/widgets/`): Reusable UI components

## 🐛 Troubleshooting

### Common Issues

#### 1. MLC-LLM Import Errors
```bash
# Error: cannot import name 'register_global_func'
# Solution: Compatibility fixes are already applied
# Check if symlinks exist:
ls -la /path/to/conda/envs/mlc/lib/libmlc_llm.dylib
```

#### 2. Build Failures
```bash
# Error: CMake not found
# Solution: Install CMake
conda install cmake

# Error: NDK not found
# Solution: Install Android NDK and set ANDROID_NDK_HOME
```

#### 3. Flutter Build Issues
```bash
# Error: Gradle build failed
# Solution: Clean and rebuild
flutter clean
flutter pub get
flutter build apk --debug
```

#### 4. Model Loading Issues
```bash
# Error: Model files not found
# Solution: Verify model files in assets/models/
ls -la assets/models/
```

### Debug Commands
```bash
# Check Flutter environment
flutter doctor -v

# Check Android setup
flutter doctor --android-licenses

# Check Python environment
conda list | grep -E "(mlc|tvm)"

# Check native libraries
ls -la android/app/src/main/cpp/libs/
```

## 📝 Version Information

### Current Versions
- **Flutter**: 3.16.0
- **Dart**: 3.2.0
- **Python**: 3.10.0
- **MLC-LLM**: 0.20.0.dev0
- **Apache TVM**: 0.10.0
- **Apache TVM FFI**: 0.1.0b4
- **Android SDK**: API Level 34
- **Android NDK**: r25c

### Compatibility Matrix
| Component | Min Version | Recommended | Max Version |
|-----------|-------------|-------------|-------------|
| Flutter   | 3.0.0       | 3.16.0      | 3.20.0      |
| Python    | 3.10.0      | 3.10.0      | 3.11.0      |
| Android   | API 21      | API 34      | API 35      |
| NDK       | r21e        | r25c        | r26b        |

## 🤝 Contributing

### Development Workflow
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Set up development environment following this README
4. Make your changes
5. Test thoroughly with MLC-LLM integration
6. Commit your changes: `git commit -m 'Add amazing feature'`
7. Push to the branch: `git push origin feature/amazing-feature`
8. Open a Pull Request

### Code Style
- Follow Flutter/Dart style guidelines
- Use Provider pattern for state management
- Add comments for complex MLC-LLM integrations
- Test MLC-LLM functionality before submitting PR

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [MLC-LLM](https://github.com/mlc-ai/mlc-llm) - Machine Learning Compilation for Large Language Models
- [Apache TVM](https://github.com/apache/tvm) - Tensor Virtual Machine
- [Flutter](https://flutter.dev/) - UI toolkit for building natively compiled applications

## 📞 Support

For issues and questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review [DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md)
3. Open an issue on GitHub
4. Check MLC-LLM documentation for model-specific issues

---

**Note**: This app requires MLC model files to function. Ensure you have the appropriate model files in the `assets/models/` directory before building.