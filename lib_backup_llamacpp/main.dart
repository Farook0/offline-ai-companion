import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:offline_ai_companion/providers/ai_model_provider.dart';
import 'package:offline_ai_companion/providers/chat_provider.dart';
import 'package:offline_ai_companion/providers/settings_provider.dart';
import 'package:offline_ai_companion/screens/home_screen.dart';
import 'package:offline_ai_companion/utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('MAIN: Starting Offline AI Companion...');
  
  try {
    // Simple initialization
    print('MAIN: Initializing app...');
    
    runApp(const OfflineAICompanionApp());
  } catch (e) {
    print('MAIN: Error during initialization: $e');
    runApp(const OfflineAICompanionApp());
  }
}

class OfflineAICompanionApp extends StatelessWidget {
  const OfflineAICompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AIModelProvider()),
        ChangeNotifierProxyProvider<AIModelProvider, ChatProvider>(
          create: (_) => ChatProvider(),
          update: (_, aiModelProvider, chatProvider) {
            chatProvider?.setAIModelProvider(aiModelProvider);
            return chatProvider ?? ChatProvider();
          },
        ),
      ],
      child: MaterialApp(
        title: 'Offline AI Companion',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
