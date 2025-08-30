import 'package:flutter/foundation.dart';
import 'package:offline_ai_companion/models/chat_message.dart';
import 'package:offline_ai_companion/models/chat_session.dart';
import 'package:offline_ai_companion/services/chat_service.dart';
import 'package:offline_ai_companion/models/ai_model.dart';
import 'package:offline_ai_companion/providers/ai_model_provider.dart';

class ChatProvider with ChangeNotifier {
  ChatSession? _currentSession;
  bool _isGenerating = false;
  String? _errorMessage;
  AIModelProvider? _aiModelProvider;

  ChatProvider() {
    print('ChatProvider: Constructor called');
  }

  // Set the AI model provider reference
  void setAIModelProvider(AIModelProvider aiModelProvider) {
    _aiModelProvider = aiModelProvider;
    print('ChatProvider: AI Model Provider set');
  }

  // Getters
  ChatSession? get currentSession => _currentSession;
  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;
  List<ChatMessage> get messages => _currentSession?.messages ?? [];

  // Initialize chat
  Future<void> initialize() async {
    print('ChatProvider: initialize() called');
    try {
      // Create a new session if none exists
      if (_currentSession == null) {
        _currentSession = ChatSession(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'New Chat',
          messages: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      
      print('ChatProvider: Initialization completed');
    } catch (e) {
      _errorMessage = 'Failed to initialize chat: $e';
      print('ChatProvider: Initialization failed: $e');
    }
  }

  // Send a message
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    print('ChatProvider: Sending message: $content');

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    _addMessage(userMessage);

    // Generate AI response
    await _generateResponse(content);
  }

  // Generate AI response using the AI model provider
  Future<void> _generateResponse(String userMessage) async {
    _setGenerating(true);
    _errorMessage = null;

    try {
      print('ChatProvider: Generating response for: $userMessage');
      
      // Use the AI model provider to generate response
      // This will use real llama.cpp if available, otherwise fallback
      final response = await _generateResponseFromModel(userMessage);

      // Add AI response
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      _addMessage(aiMessage);
      
      print('ChatProvider: Response generated successfully');
    } catch (e) {
      _errorMessage = 'Failed to generate response: $e';
      print('ChatProvider: Error generating response: $e');
    } finally {
      _setGenerating(false);
    }
  }

  // Generate response from model using AI model provider
  Future<String> _generateResponseFromModel(String prompt) async {
    if (_aiModelProvider != null) {
      try {
        print('ChatProvider: Using AI Model Provider for response generation');
        return await _aiModelProvider!.generateResponse(prompt);
      } catch (e) {
        print('ChatProvider: AI Model Provider failed: $e');
        // NO FALLBACK - rethrow to force fixing llama.cpp
        rethrow;
      }
    } else {
      print('ChatProvider: No AI Model Provider available');
      // NO FALLBACK - throw error to force fixing
      throw Exception('No AI Model Provider available. Fallback disabled to force native llama.cpp implementation.');
    }
  }

  // Add message to current session
  void _addMessage(ChatMessage message) {
    if (_currentSession != null) {
      _currentSession!.messages.add(message);
      _currentSession!.updatedAt = DateTime.now();
      
      // Update session title if it's the first message
      if (_currentSession!.messages.length == 1) {
        _currentSession!.title = _generateTitle(message.content);
      }
      
      notifyListeners();
    }
  }

  // Generate a simple title from the first message
  String _generateTitle(String message) {
    final words = message.split(' ');
    if (words.length <= 5) {
      return message;
    }
    return '${words.take(5).join(' ')}...';
  }

  // Create new chat session
  void createNewSession() {
    _currentSession = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Chat',
      messages: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _errorMessage = null;
    notifyListeners();
  }

  // Clear current session
  void clearSession() {
    if (_currentSession != null) {
      _currentSession!.messages.clear();
      _currentSession!.updatedAt = DateTime.now();
      _errorMessage = null;
      notifyListeners();
    }
  }

  // Export chat data
  Future<String> exportChatData() async {
    if (_currentSession == null || _currentSession!.messages.isEmpty) {
      return 'No chat data to export';
    }

    try {
      return await ChatService.exportChatData(_currentSession!.messages);
    } catch (e) {
      _errorMessage = 'Failed to export chat data: $e';
      notifyListeners();
      return 'Error exporting chat data: $e';
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Private helper methods
  void _setGenerating(bool generating) {
    _isGenerating = generating;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
} 