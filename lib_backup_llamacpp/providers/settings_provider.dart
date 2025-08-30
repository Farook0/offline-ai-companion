import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:offline_ai_companion/models/ai_model.dart';

class SettingsProvider with ChangeNotifier {
  static const String _keyIsDarkMode = 'isDarkMode';
  static const String _keyTemperature = 'temperature';
  static const String _keyMaxTokens = 'maxTokens';
  static const String _keyTopP = 'topP';
  static const String _keyTopK = 'topK';
  static const String _keyRepetitionPenalty = 'repetitionPenalty';
  static const String _keyUseMetal = 'useMetal';
  static const String _keySaveChatHistory = 'saveChatHistory';
  static const String _keyAutoDeleteOldMessages = 'autoDeleteOldMessages';
  static const String _keyAutoDeleteDays = 'autoDeleteDays';
  static const String _keyBackgroundProcessing = 'backgroundProcessing';
  static const String _keyNotifications = 'notifications';
  static const String _keyPrivacyMode = 'privacyMode';
  static const String _keyLanguage = 'language';
  static const String _keyFontSize = 'fontSize';

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Settings
  bool _isDarkMode = false;
  double _temperature = 0.7;
  int _maxTokens = 2048;
  double _topP = 0.9;
  int _topK = 40;
  double _repetitionPenalty = 1.1;
  bool _useMetal = false;
  bool _saveChatHistory = true;
  bool _autoDeleteOldMessages = false;
  int _autoDeleteDays = 30;
  bool _backgroundProcessing = false;
  bool _notifications = true;
  bool _privacyMode = false;
  String _language = 'en';
  double _fontSize = 1.0;

  // Getters
  bool get isDarkMode => _isDarkMode;
  double get temperature => _temperature;
  int get maxTokens => _maxTokens;
  double get topP => _topP;
  int get topK => _topK;
  double get repetitionPenalty => _repetitionPenalty;
  bool get useMetal => _useMetal;
  bool get saveChatHistory => _saveChatHistory;
  bool get autoDeleteOldMessages => _autoDeleteOldMessages;
  int get autoDeleteDays => _autoDeleteDays;
  bool get backgroundProcessing => _backgroundProcessing;
  bool get notifications => _notifications;
  bool get privacyMode => _privacyMode;
  String get language => _language;
  double get fontSize => _fontSize;
  bool get isInitialized => _isInitialized;

  // Initialize settings
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
    _isInitialized = true;
    notifyListeners();
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    _isDarkMode = _prefs.getBool(_keyIsDarkMode) ?? false;
    _temperature = _prefs.getDouble(_keyTemperature) ?? 0.7;
    _maxTokens = _prefs.getInt(_keyMaxTokens) ?? 2048;
    _topP = _prefs.getDouble(_keyTopP) ?? 0.9;
    _topK = _prefs.getInt(_keyTopK) ?? 40;
    _repetitionPenalty = _prefs.getDouble(_keyRepetitionPenalty) ?? 1.1;
    _useMetal = _prefs.getBool(_keyUseMetal) ?? false;
    _saveChatHistory = _prefs.getBool(_keySaveChatHistory) ?? true;
    _autoDeleteOldMessages = _prefs.getBool(_keyAutoDeleteOldMessages) ?? false;
    _autoDeleteDays = _prefs.getInt(_keyAutoDeleteDays) ?? 30;
    _backgroundProcessing = _prefs.getBool(_keyBackgroundProcessing) ?? false;
    _notifications = _prefs.getBool(_keyNotifications) ?? true;
    _privacyMode = _prefs.getBool(_keyPrivacyMode) ?? false;
    _language = _prefs.getString(_keyLanguage) ?? 'en';
    _fontSize = _prefs.getDouble(_keyFontSize) ?? 1.0;
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    await _prefs.setBool(_keyIsDarkMode, _isDarkMode);
    await _prefs.setDouble(_keyTemperature, _temperature);
    await _prefs.setInt(_keyMaxTokens, _maxTokens);
    await _prefs.setDouble(_keyTopP, _topP);
    await _prefs.setInt(_keyTopK, _topK);
    await _prefs.setDouble(_keyRepetitionPenalty, _repetitionPenalty);
    await _prefs.setBool(_keyUseMetal, _useMetal);
    await _prefs.setBool(_keySaveChatHistory, _saveChatHistory);
    await _prefs.setBool(_keyAutoDeleteOldMessages, _autoDeleteOldMessages);
    await _prefs.setInt(_keyAutoDeleteDays, _autoDeleteDays);
    await _prefs.setBool(_keyBackgroundProcessing, _backgroundProcessing);
    await _prefs.setBool(_keyNotifications, _notifications);
    await _prefs.setBool(_keyPrivacyMode, _privacyMode);
    await _prefs.setString(_keyLanguage, _language);
    await _prefs.setDouble(_keyFontSize, _fontSize);
  }

  // Update methods
  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setTemperature(double value) async {
    _temperature = value.clamp(0.0, 2.0);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setMaxTokens(int value) async {
    _maxTokens = value.clamp(1, 8192);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setTopP(double value) async {
    _topP = value.clamp(0.0, 1.0);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setTopK(int value) async {
    _topK = value.clamp(1, 100);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setRepetitionPenalty(double value) async {
    _repetitionPenalty = value.clamp(0.0, 2.0);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setUseMetal(bool value) async {
    _useMetal = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setSaveChatHistory(bool value) async {
    _saveChatHistory = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setAutoDeleteOldMessages(bool value) async {
    _autoDeleteOldMessages = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setAutoDeleteDays(int value) async {
    _autoDeleteDays = value.clamp(1, 365);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setBackgroundProcessing(bool value) async {
    _backgroundProcessing = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setNotifications(bool value) async {
    _notifications = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setPrivacyMode(bool value) async {
    _privacyMode = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setFontSize(double value) async {
    _fontSize = value.clamp(0.5, 2.0);
    await _saveSettings();
    notifyListeners();
  }

  // Get model configuration from settings
  ModelConfiguration getModelConfiguration() {
    return ModelConfiguration(
      temperature: _temperature,
      topP: _topP,
      maxTokens: _maxTokens,
    );
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    _isDarkMode = false;
    _temperature = 0.7;
    _maxTokens = 2048;
    _topP = 0.9;
    _topK = 40;
    _repetitionPenalty = 1.1;
    _useMetal = false;
    _saveChatHistory = true;
    _autoDeleteOldMessages = false;
    _autoDeleteDays = 30;
    _backgroundProcessing = false;
    _notifications = true;
    _privacyMode = false;
    _language = 'en';
    _fontSize = 1.0;

    await _saveSettings();
    notifyListeners();
  }

  // Export settings
  Map<String, dynamic> exportSettings() {
    return {
      'isDarkMode': _isDarkMode,
      'temperature': _temperature,
      'maxTokens': _maxTokens,
      'topP': _topP,
      'topK': _topK,
      'repetitionPenalty': _repetitionPenalty,
      'useMetal': _useMetal,
      'saveChatHistory': _saveChatHistory,
      'autoDeleteOldMessages': _autoDeleteOldMessages,
      'autoDeleteDays': _autoDeleteDays,
      'backgroundProcessing': _backgroundProcessing,
      'notifications': _notifications,
      'privacyMode': _privacyMode,
      'language': _language,
      'fontSize': _fontSize,
    };
  }

  // Import settings
  Future<void> importSettings(Map<String, dynamic> settings) async {
    if (settings.containsKey('isDarkMode')) _isDarkMode = settings['isDarkMode'] as bool;
    if (settings.containsKey('temperature')) _temperature = (settings['temperature'] as num).toDouble();
    if (settings.containsKey('maxTokens')) _maxTokens = settings['maxTokens'] as int;
    if (settings.containsKey('topP')) _topP = (settings['topP'] as num).toDouble();
    if (settings.containsKey('topK')) _topK = settings['topK'] as int;
    if (settings.containsKey('repetitionPenalty')) _repetitionPenalty = (settings['repetitionPenalty'] as num).toDouble();
    if (settings.containsKey('useMetal')) _useMetal = settings['useMetal'] as bool;
    if (settings.containsKey('saveChatHistory')) _saveChatHistory = settings['saveChatHistory'] as bool;
    if (settings.containsKey('autoDeleteOldMessages')) _autoDeleteOldMessages = settings['autoDeleteOldMessages'] as bool;
    if (settings.containsKey('autoDeleteDays')) _autoDeleteDays = settings['autoDeleteDays'] as int;
    if (settings.containsKey('backgroundProcessing')) _backgroundProcessing = settings['backgroundProcessing'] as bool;
    if (settings.containsKey('notifications')) _notifications = settings['notifications'] as bool;
    if (settings.containsKey('privacyMode')) _privacyMode = settings['privacyMode'] as bool;
    if (settings.containsKey('language')) _language = settings['language'] as String;
    if (settings.containsKey('fontSize')) _fontSize = (settings['fontSize'] as num).toDouble();

    await _saveSettings();
    notifyListeners();
  }
} 