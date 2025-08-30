# 🤖 Offline AI Companion

A **privacy-first, cross-platform Flutter application** that provides a fully offline AI assistant experience using local language models. This app supports multiple AI models and works entirely without internet connectivity, ensuring complete privacy and data security.

## 🌟 Key Features

### 🚀 **Performance & Privacy**
- **100% Offline Operation**: No internet required for AI responses
- **GPU Acceleration**: MLC-LLM integration for 5-10x faster performance
- **Local Processing**: All AI inference happens on your device
- **Privacy-First**: Your conversations never leave your device
- **Multiple Model Support**: Switch between different AI models

### 💬 **Chat Interface**
- **Modern UI**: Beautiful, responsive Material Design 3 interface
- **Session Management**: Create, manage, and organize chat sessions
- **Message History**: Persistent chat history with local SQLite storage
- **Markdown Support**: Rich text formatting in AI responses
- **Code Highlighting**: Syntax highlighting for code blocks
- **Real-time Streaming**: See AI responses as they're generated

### ⚙️ **Customization & Settings**
- **Model Configuration**: Adjust temperature, max tokens, top-p, top-k, and repetition penalty
- **Theme Support**: Light and dark mode with system theme detection
- **Font Scaling**: Adjustable text size for accessibility
- **Performance Settings**: Metal acceleration for iOS/macOS, GPU optimization

## 🛠️ How the App Works

### **Architecture Overview**

The app uses a **multi-layered architecture** with the following components:

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter UI Layer                         │
├─────────────────────────────────────────────────────────────┤
│                 Provider State Management                   │
├─────────────────────────────────────────────────────────────┤
│                   Service Layer                             │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │ MLC Service │ │ Chat Service│ │Model Service│           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
├─────────────────────────────────────────────────────────────┤
│                 Native Platform Layer                       │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │   MLC-LLM   │ │  llama.cpp  │ │   SQLite    │           │
│  │ (Primary)   │ │ (Fallback)  │ │ (Storage)   │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
└─────────────────────────────────────────────────────────────┘
```

### **AI Model Processing Flow**

1. **Model Loading**: 
   - App loads MLC-LLM models (primary) or llama.cpp models (fallback)
   - Models are cached locally for faster subsequent loads
   - GPU acceleration is automatically detected and utilized

2. **Chat Processing**:
   - User input is processed through the selected AI model
   - Responses are generated using local inference
   - Real-time streaming provides immediate feedback
   - Messages are stored in local SQLite database

3. **Data Management**:
   - All chat history stored locally
   - Model files cached for performance
   - Automatic cleanup of old data
   - Export functionality for backup

## 🚀 Quick Setup Guide (Android-Only Development)

### **Step 1: Install Required Software**

#### **Install Homebrew (if not installed)**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### **Install Flutter SDK**
```bash
# Install Flutter via Homebrew
brew install flutter

# Verify installation
flutter doctor
```

#### **Install Android Studio (Required for Android development)**
```bash
# Download from https://developer.android.com/studio
# Or install via Homebrew
brew install --cask android-studio
```

#### **Install Cursor (recommended IDE)**
```bash
# Download Cursor from https://cursor.sh/
# Or install via Homebrew
brew install --cask cursor
```

#### **Install Java Development Kit (JDK)**
```bash
# Install OpenJDK 17 (required for Android development)
brew install openjdk@17

# Set JAVA_HOME
echo 'export JAVA_HOME=/opt/homebrew/opt/openjdk@17' >> ~/.zshrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.zshrc
source ~/.zshrc
```

### **Step 2: Setup Android Development Environment**

#### **Install Android SDK**
```bash
# Open Android Studio and install Android SDK
# Or install via command line
brew install --cask android-commandlinetools

# Set ANDROID_HOME
echo 'export ANDROID_HOME=$HOME/Library/Android/sdk' >> ~/.zshrc
echo 'export PATH=$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH' >> ~/.zshrc
source ~/.zshrc
```

#### **Install Android SDK Components**
```bash
# Install required SDK components
sdkmanager "platform-tools" "platforms;android-35" "build-tools;34.0.0"
sdkmanager "ndk;25.2.9519653" "cmake;3.22.1"
```

### **Step 3: Clone and Setup Project**

```bash
# Clone your repository
git clone <your-github-repo-url>
cd offline_ai_companion

# Install Flutter dependencies
flutter pub get
```

### **Step 4: Download AI Models**

```bash
# Create models directory
mkdir -p assets/models/

# Download MLC-LLM models (recommended)
cd assets/models/
curl -L -o Llama-3.2-1B-Instruct-q4f16_0-MLC.zip https://huggingface.co/mlc-ai/Llama-3.2-1B-Instruct-q4f16_0-MLC/resolve/main/Llama-3.2-1B-Instruct-q4f16_0-MLC.zip
unzip Llama-3.2-1B-Instruct-q4f16_0-MLC.zip
cd ../..
```

> **Note**: Model files are excluded from git (see .gitignore) to keep the repository size small. You need to download them separately after cloning the repository.

### **Step 5: Run the App**

```bash
# Check available devices
flutter devices

# Run on Android device/emulator
flutter run -d android

# Or run on specific Android device
flutter run -d <android-device-id>
```

### **Step 6: Verify Everything Works**

```bash
# Check Flutter installation
flutter doctor

# Check available devices
flutter devices

# Test the app
flutter test

# Build Android APK
flutter build apk --debug
```

## ✅ **Complete Setup Checklist**

- [ ] **Homebrew** installed
- [ ] **Flutter SDK** installed and verified (`flutter doctor`)
- [ ] **Android Studio** installed with Android SDK
- [ ] **Java JDK 17** installed and JAVA_HOME set
- [ ] **Android SDK** installed with required components
- [ ] **Android NDK** installed for native code compilation
- [ ] **Cursor** installed with Flutter extension
- [ ] **Repository** cloned from GitHub
- [ ] **Flutter dependencies** installed (`flutter pub get`)
- [ ] **AI models** downloaded and extracted
- [ ] **App runs** successfully on Android (`flutter run -d android`)

## 🔧 **Troubleshooting Common Issues**

### **Flutter Doctor Issues**
```bash
# If flutter doctor shows Android SDK issues:
flutter doctor --android-licenses
flutter config --android-sdk $ANDROID_HOME

# Accept Android licenses
yes | sdkmanager --licenses
```

### **Android SDK Issues**
```bash
# If Android SDK is not found:
# 1. Open Android Studio
# 2. Go to Tools > SDK Manager
# 3. Install Android SDK Platform 35
# 4. Install Android SDK Build-Tools 34.0.0
# 5. Install Android NDK 25.2.9519653
```

### **Java/JDK Issues**
```bash
# If Java is not found:
brew install openjdk@17
echo 'export JAVA_HOME=/opt/homebrew/opt/openjdk@17' >> ~/.zshrc
source ~/.zshrc

# Verify Java installation
java -version
```

### **Native Code Compilation Issues**
```bash
# If CMake/NDK compilation fails:
# 1. Install NDK via Android Studio SDK Manager
# 2. Set ANDROID_NDK_HOME environment variable
echo 'export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/25.2.9519653' >> ~/.zshrc
source ~/.zshrc
```

### **Model Download Issues**
```bash
# If model download fails, try manual download:
# 1. Visit: https://huggingface.co/mlc-ai/Llama-3.2-1B-Instruct-q4f16_0-MLC
# 2. Download the zip file manually
# 3. Extract to assets/models/ directory
```

### **Permission Issues**
```bash
# If you get permission errors:
sudo chown -R $(whoami) /usr/local/bin /usr/local/lib /usr/local/sbin
chmod u+w /usr/local/bin /usr/local/lib /usr/local/sbin
```

---

## 📋 Detailed Prerequisites & Installation

### **System Requirements**

#### **For Development**
- **Flutter SDK**: 3.0.0 or higher
- **Dart SDK**: 3.0.0 or higher
- **Android Studio** or **Cursor** with Flutter extensions
- **Git** for version control

#### **For Running the App**
- **iOS**: iOS 12.0+ (iPhone/iPad)
- **Android**: Android 6.0+ (API 23+)
- **macOS**: macOS 10.14+ (for development)
- **Windows**: Windows 10+ (for development)

## 📚 **Libraries & Technologies Used**

### **Programming Languages**
- **Dart**: Primary language for Flutter app development
- **Kotlin/Java**: Android native code and platform integration
- **C++**: Native AI model integration (MLC-LLM, llama.cpp)

### **Frameworks & Platforms**
- **Flutter**: Cross-platform UI framework
- **Android SDK**: Platform-specific Android development
- **MLC-LLM**: High-performance AI inference framework
- **llama.cpp**: Fallback AI inference library
- **SQLite**: Local database for chat history
- **CMake**: Native code build system
- **Android NDK**: Native code compilation for Android

### **Required Libraries & Dependencies**

The app uses the following key libraries (automatically installed via `pubspec.yaml`):

#### **Core Dependencies**
```yaml
# State Management
provider: ^6.1.1                    # Flutter state management

# Local Storage
shared_preferences: ^2.2.2          # App settings storage
sqflite: ^2.3.0                     # Local database
path: ^1.8.3                        # File path utilities
path_provider: ^2.1.1               # Platform-specific paths

# UI & Animation
flutter_markdown: ^0.6.18           # Markdown rendering
flutter_animate: ^4.2.0+1           # Smooth animations
flutter_staggered_animations: ^1.1.1 # Staggered animations
shimmer: ^3.0.0                     # Loading effects
flutter_svg: ^2.0.9                 # SVG support
lottie: ^2.7.0                      # Lottie animations

# Platform Integration
permission_handler: ^11.0.1         # Device permissions
device_info_plus: ^9.1.1            # Device information
package_info_plus: ^4.2.0           # App package info

# Utilities
http: ^1.1.0                        # HTTP requests (for model downloads)
intl: ^0.18.1                       # Internationalization
uuid: ^4.2.1                        # Unique identifiers
crypto: ^3.0.3                      # Cryptographic functions

# Native Integration
ffi: ^2.1.0                         # Foreign Function Interface
```

#### **Development Dependencies**
```yaml
flutter_test:
  sdk: flutter
flutter_lints: ^3.0.0               # Code quality and style
```

### **Installation Steps**

#### **1. Clone the Repository**
```bash
git clone <repository-url>
cd offline_ai_companion
```

#### **2. Install Flutter Dependencies**
```bash
flutter pub get
```

#### **3. Platform-Specific Setup**

**For Android:**
```bash
# No additional setup required - all native dependencies are included
flutter run
```

**For iOS:**
```bash
cd ios
pod install
cd ..
flutter run
```

**For macOS:**
```bash
cd macos
pod install
cd ..
flutter run
```

#### **4. Add AI Models**

Create the models directory and add your AI models:

```bash
# Create models directory
mkdir -p assets/models/

# Download MLC-LLM models (recommended)
cd assets/models/
wget https://huggingface.co/mlc-ai/Llama-3.2-1B-Instruct-q4f16_0-MLC/resolve/main/Llama-3.2-1B-Instruct-q4f16_0-MLC.zip
unzip Llama-3.2-1B-Instruct-q4f16_0-MLC.zip



#### **5. Run the App**
```bash
flutter run
```

## 🏗️ Project Structure

```
offline_ai_companion/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── models/                      # Data models
│   │   ├── ai_model.dart           # AI model definitions
│   │   ├── chat_message.dart       # Chat message structures
│   │   ├── chat_session.dart       # Chat session management
│   │   └── mlc_model.dart          # MLC-LLM model definitions
│   ├── providers/                   # State management
│   │   ├── ai_model_provider.dart  # AI model state
│   │   ├── chat_provider.dart      # Chat state management
│   │   ├── mlc_model_provider.dart # MLC model state
│   │   └── settings_provider.dart  # App settings state
│   ├── screens/                     # UI screens
│   │   ├── home_screen.dart        # Main navigation
│   │   ├── chat_screen.dart        # Chat interface
│   │   ├── models_screen.dart      # Model selection
│   │   └── settings_screen.dart    # Settings interface
│   ├── services/                    # Business logic
│   │   ├── ai_service.dart         # AI service interface
│   │   ├── chat_service.dart       # Chat management
│   │   ├── mlc_service.dart        # MLC-LLM integration
│   │   ├── mlc_ai_service.dart     # Enhanced AI service
│   │   └── model_service.dart      # Model management
│   ├── widgets/                     # Reusable UI components
│   │   ├── chat_input.dart         # Chat input widget
│   │   ├── message_bubble.dart     # Message display
│   │   ├── model_card.dart         # Model selection cards
│   │   ├── model_loading_progress.dart # Loading indicators
│   │   ├── model_status_indicator.dart # Status indicators
│   │   ├── session_drawer.dart     # Session management
│   │   └── twinkling_bot.dart      # Animated bot icon
│   └── utils/                       # Utilities
│       └── theme.dart              # App theming
├── android/                         # Android-specific code
│   └── app/
│       └── src/main/
│           ├── java/               # Java/Kotlin code
│           ├── cpp/                # Native C++ code
│           └── assets/             # Model files
├── ios/                            # iOS-specific code
├── assets/                         # App assets
│   ├── models/                     # AI model files
│   └── mlc-app-config.json        # MLC configuration
├── pubspec.yaml                    # Flutter dependencies
└── README.md                      # This file
```

## 🔧 Configuration

### **Model Settings**

The app supports various AI model parameters:

```dart
// Example model configuration
AIModel(
  id: 'llama-3.2-1b',
  name: 'Llama 3.2 1B',
  description: 'Fast and efficient 1B parameter model',
  version: '1.0',
  filePath: 'assets/models/Llama-3.2-1B-Instruct-q4f16_0-MLC',
  parameters: 1000000000,
  format: 'MLC',
  // Model-specific settings
  temperature: 0.7,        // Creativity (0.0 - 2.0)
  maxTokens: 2048,         // Max response length
  topP: 0.9,              // Nucleus sampling
  topK: 40,               // Top-k sampling
  repetitionPenalty: 1.1, // Prevent repetition
)
```

### **Performance Settings**

```dart
// Performance optimization settings
SettingsProvider settings = Provider.of<SettingsProvider>(context);

// Enable GPU acceleration
settings.setUseGPU(true);

// Enable Metal acceleration (iOS/macOS)
settings.setUseMetal(true);

// Background processing
settings.setAllowBackgroundProcessing(true);

// Memory management
settings.setAutoUnloadModels(true);
```

## 🚀 Usage Guide

### **Getting Started**

1. **Launch the App**: Open the app on your device
2. **Select a Model**: Choose from available AI models
3. **Start Chatting**: Begin a conversation with the AI
4. **Customize Settings**: Adjust model parameters as needed

### **Model Selection**

The app supports multiple model formats:

#### **MLC-LLM Models (Recommended)**
- **Llama 3.2 1B**: Fast, efficient 1B parameter model
- **Qwen2.5 0.5B**: Ultra-fast 0.5B parameter model
- **TinyLlama 1.1B**: Balanced performance and quality

#### **GGUF Models (Fallback)**
- **Phi-2**: Microsoft's 2.7B parameter model
- **Mistral 7B**: High-quality 7B parameter model
- **Custom Models**: Any GGUF format model

### **Chat Features**

- **Real-time Responses**: See AI responses as they're generated
- **Session Management**: Organize conversations into sessions
- **Message History**: Persistent chat history
- **Export Functionality**: Backup your conversations
- **Markdown Support**: Rich text formatting in responses

## 🔒 Privacy & Security

### **Data Storage**
- **Local Only**: All data stored on your device
- **No Cloud Sync**: No external data transmission
- **Encrypted Storage**: Sensitive data encrypted at rest
- **Automatic Cleanup**: Old data automatically removed

### **Permissions Required**
- **Storage**: For model files and chat history
- **Notifications**: Optional for AI response alerts
- **No Network**: App doesn't require internet access

## 📱 Platform Support

### **Android** (Primary Target)
- **Minimum Version**: Android 8.0 (API 26)+
- **Target Version**: Android 15 (API 35)
- **Features**: Optimized for Android devices
- **GPU Support**: OpenCL/Vulkan acceleration via MLC-LLM
- **Permissions**: Storage, notifications
- **Architecture**: ARM64-v8a only (optimized for modern devices)

### **Development Environment**
- **macOS**: macOS 10.14+ (for development)
- **Windows**: Windows 10+ (for development)
- **Linux**: Ubuntu 18.04+ (for development)

## 🛠️ Development

### **Adding New Models**

1. **Update Model Definitions**:
```dart
// In lib/models/mlc_model.dart
static const List<MLCModel> _predefinedModels = [
  // Add your new model here
  MLCModel(
    id: 'your-model-id',
    name: 'Your Model Name',
    description: 'Model description',
    version: '1.0',
    filePath: 'assets/models/your-model',
    parameters: 1000000000,
    format: 'MLC',
  ),
];
```

2. **Add Model File**:
   - Place your model file in `assets/models/`
   - Update `pubspec.yaml` if needed

### **Customizing UI**

1. **Theme Configuration**:
```dart
// In lib/utils/theme.dart
class AppTheme {
  static const Color primaryColor = Color(0xFF6366F1);
  // Customize colors and styles
}
```

2. **Adding New Screens**:
   - Create new screen in `lib/screens/`
   - Add to navigation in `lib/screens/home_screen.dart`

### **Building for Production**

```bash
# Android APK (Debug)
flutter build apk --debug

# Android APK (Release)
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# Check build size
ls -lh build/app/outputs/flutter-apk/
```

## 🚀 Performance Optimization

### **Model Selection Tips**
- **Small Models (0.5B-1B)**: Fast responses, lower quality
- **Medium Models (1B-3B)**: Balanced performance and quality
- **Large Models (7B+)**: High quality, slower responses

### **Device Requirements**
- **RAM**: 4GB+ recommended for larger models
- **Storage**: 2GB+ for model files
- **Processor**: Modern multi-core processor
- **GPU**: Optional but recommended for acceleration

### **Optimization Settings**
1. **Enable GPU Acceleration**: Use device GPU for faster inference
2. **Background Processing**: Allow AI processing in background
3. **Memory Management**: Automatic model unloading
4. **Storage Optimization**: Efficient model caching

## 🤝 Contributing

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes**: Follow Flutter best practices
4. **Add tests**: If applicable, add unit or widget tests
5. **Submit a pull request**: With detailed description

### **Development Guidelines**
- Follow Flutter best practices and conventions
- Use meaningful commit messages
- Test on multiple platforms
- Document new features
- Maintain code quality with `flutter analyze`

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **MLC-LLM Team**: For the high-performance inference framework
- **llama.cpp Team**: For the efficient model inference library
- **Flutter Team**: For the amazing cross-platform framework
- **Model Creators**: For providing open-source AI models
- **Community**: For feedback, contributions, and support

## 📞 Support & Community

- **Issues**: Report bugs on [GitHub Issues](https://github.com/your-repo/issues)
- **Discussions**: Join community discussions
- **Documentation**: Check the wiki for detailed guides
- **Contributing**: See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines

## 🔮 Roadmap

### **Upcoming Features**
- [ ] Voice input/output support
- [ ] Image generation capabilities
- [ ] Multi-language support
- [ ] Advanced model fine-tuning
- [ ] Cloud backup (optional)
- [ ] Plugin system for extensions
- [ ] Collaborative chat sessions

### **Performance Improvements**
- [ ] Optimized model loading
- [ ] Better memory management
- [ ] Faster inference algorithms
- [ ] Reduced battery usage
- [ ] Improved GPU utilization

### **Platform Expansion**
- [ ] Web support
- [ ] Linux desktop
- [ ] Windows desktop
- [ ] Wearable device support

---

**Made with ❤️ for privacy-conscious AI users**

*This app ensures your conversations stay private and secure by running entirely on your device without any cloud dependencies.*
