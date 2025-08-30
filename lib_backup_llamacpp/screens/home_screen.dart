import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:offline_ai_companion/providers/ai_model_provider.dart';
import 'package:offline_ai_companion/providers/chat_provider.dart';
import 'package:offline_ai_companion/providers/settings_provider.dart';
import 'package:offline_ai_companion/screens/chat_screen.dart';
import 'package:offline_ai_companion/screens/models_screen.dart';
import 'package:offline_ai_companion/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ChatScreen(),
    const ModelsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    print('HomeScreen: initState called');
    // Initialize providers after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('HomeScreen: Post frame callback executed');
      _initializeProviders();
    });
  }

  Future<void> _initializeProviders() async {
    print('HomeScreen: Starting provider initialization...');
    final settingsProvider = context.read<SettingsProvider>();
    final aiModelProvider = context.read<AIModelProvider>();
    final chatProvider = context.read<ChatProvider>();

    print('HomeScreen: Calling aiModelProvider.initializeModels()...');
    await Future.wait([
      settingsProvider.initialize(),
      aiModelProvider.initializeModels(),
      chatProvider.initialize(),
    ]);
    print('HomeScreen: Provider initialization completed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.model_training_outlined),
            selectedIcon: Icon(Icons.model_training),
            label: 'Model',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
} 