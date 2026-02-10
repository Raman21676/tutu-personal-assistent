import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Models
import 'models/agent_model.dart';

// Services
import 'services/storage_service.dart';
import 'services/local_llm_service.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/agent_list_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/create_agent_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/voice_settings_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/model_manager_screen.dart';

// Utils
import 'utils/constants.dart';
import 'utils/themes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TuTuApp());
}

/// Main App Widget
class TuTuApp extends StatelessWidget {
  const TuTuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
        ChangeNotifierProvider<LocalLLMService>(
          create: (_) => LocalLLMService(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppThemes.lightTheme,
        darkTheme: AppThemes.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: Routes.splash,
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  /// Route generator for navigation
  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );

      case Routes.onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        );

      case Routes.home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );

      case Routes.agentList:
        return MaterialPageRoute(
          builder: (_) => const AgentListScreen(),
        );

      case Routes.chat:
        final agent = settings.arguments as Agent?;
        if (agent == null) {
          return _errorRoute('Agent not specified');
        }
        return MaterialPageRoute(
          builder: (_) => ChatScreen(agent: agent),
        );

      case Routes.createAgent:
        return MaterialPageRoute(
          builder: (_) => const CreateAgentScreen(),
        );

      case Routes.settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
        );

      case Routes.voiceSettings:
        return MaterialPageRoute(
          builder: (_) => const VoiceSettingsScreen(),
        );

      case Routes.camera:
        final agentId = settings.arguments as String?;
        if (agentId == null) {
          return _errorRoute('Agent ID not specified');
        }
        return MaterialPageRoute(
          builder: (_) => CameraScreen(agentId: agentId),
        );

      case Routes.modelManager:
        return MaterialPageRoute(
          builder: (_) => const ModelManagerScreen(),
        );

      default:
        return _errorRoute('Route not found: ${settings.name}');
    }
  }

  /// Error route for invalid navigation
  Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Navigation Error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(message),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, Routes.home);
                },
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
