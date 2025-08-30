import 'dart:io';
import 'package:offline_ai_companion/models/ai_model.dart';
import 'package:offline_ai_companion/models/chat_message.dart';
import 'package:offline_ai_companion/models/chat_session.dart';

class ChatService {
  static const String _dbName = 'chat_sessions.db';
  
  // Generate a response using the AI model provider
  static Future<String> generateResponse(String prompt, {AIModel? model}) async {
    print('ChatService: Generating response for prompt: "$prompt"');
    
    // For now, we'll use the fallback response generation
    // In a real implementation, this would call the AI model provider
    String response = _generateSimpleResponse(prompt);
    
    print('ChatService: Generated response: $response');
    return response;
  }
  
  // Simple response generation (fallback)
  static String _generateSimpleResponse(String prompt) {
    final lowerPrompt = prompt.toLowerCase();
    
    if (lowerPrompt.contains('hello') || lowerPrompt.contains('hi')) {
      return "Hello! I'm TinyLlama, your offline AI companion. How can I help you today?";
    } else if (lowerPrompt.contains('how are you')) {
      return "I'm doing well, thank you for asking! I'm ready to help you with any questions or tasks you might have.";
    } else if (lowerPrompt.contains('what can you do')) {
      return "I can help you with various tasks like answering questions, having conversations, providing information, and assisting with different topics. Since I'm running offline, I work without needing an internet connection!";
    } else if (lowerPrompt.contains('weather')) {
      return "I can't check the current weather since I'm running offline, but I can tell you about weather patterns, climate information, or help you understand weather-related concepts.";
    } else if (lowerPrompt.contains('time') || lowerPrompt.contains('date')) {
      return "I can't tell you the exact current time or date since I'm running offline, but I can help you with time-related calculations or explain concepts about time and dates.";
    } else if (lowerPrompt.contains('help')) {
      return "I'm here to help! You can ask me questions, have conversations, get information on various topics, or just chat. What would you like to know or discuss?";
    } else if (lowerPrompt.contains('thank')) {
      return "You're welcome! I'm happy to help. Is there anything else you'd like to know or discuss?";
    } else if (lowerPrompt.contains('bye') || lowerPrompt.contains('goodbye')) {
      return "Goodbye! It was nice chatting with you. Feel free to come back anytime if you have more questions!";
    } else {
      // Generic helpful response
      return "That's an interesting question! I'm TinyLlama, an offline AI model designed to help with various topics. I can provide information, answer questions, and engage in conversations. What specific aspect would you like to know more about?";
    }
  }

  // Save chat session
  static Future<void> saveSession(ChatSession session) async {
    print('ChatService: Saving session: ${session.id}');
    // Simplified - just log for now
  }

  // Load chat sessions
  static Future<List<ChatSession>> loadSessions() async {
    print('ChatService: Loading sessions...');
    // Return empty list for now
    return [];
  }

  // Delete chat session
  static Future<void> deleteSession(String sessionId) async {
    print('ChatService: Deleting session: $sessionId');
    // Simplified - just log for now
  }

  // Export chat data
  static Future<String> exportChatData(List<ChatMessage> messages) async {
    print('ChatService: Exporting chat data...');
    
    final buffer = StringBuffer();
    buffer.writeln('Chat Export - TinyLlama AI Companion');
    buffer.writeln('Generated on: ${DateTime.now()}');
    buffer.writeln('');
    
    for (final message in messages) {
      buffer.writeln('${message.isUser ? "User" : "TinyLlama"}: ${message.content}');
      buffer.writeln('');
    }
    
    return buffer.toString();
  }
} 