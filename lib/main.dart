import 'package:flutter/material.dart';

import 'services/api_service.dart';
import 'services/settings_service.dart';
import 'screens/home_screen.dart';
import 'screens/task_screen.dart';
import 'screens/history_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const AiAgentApp());
}

/// Provides [SettingsService] and a single shared [ApiService] to the whole app.
///
/// The ApiService instance is shared so that when the user changes the server
/// URL in Settings, every screen immediately uses the new base URL (we mutate
/// `api.baseUrl`). Nothing is hardcoded to one server.
class AppServices extends InheritedWidget {
  const AppServices({
    super.key,
    required this.settings,
    required this.api,
    required super.child,
  });

  final SettingsService settings;
  final ApiService api;

  static AppServices of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<AppServices>();
    return widget!;
  }

  @override
  bool updateShouldNotify(covariant AppServices old) => true;
}

class AiAgentApp extends StatelessWidget {
  const AiAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppServices(
      settings: SettingsService(),
      api: ApiService(baseUrl: 'https://thed1-aiagent.hf.space'),
      child: const MaterialApp(
        title: 'AI Agent Downloader',
        debugShowCheckedModeBanner: false,
        home: HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late final ApiService _api;
  late final SettingsService _settings;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    final services = AppServices.of(context);
    _settings = services.settings;
    _api = services.api;
    _pages = [
      HomeScreen(api: _api),
      TaskScreen(api: _api),
      HistoryScreen(api: _api),
      const UploadScreen(),
      SettingsScreen(settings: _settings, api: _api),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        animationDuration: const Duration(milliseconds: 300),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.file_download_outlined),
            selectedIcon: Icon(Icons.file_download),
            label: 'Task',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_upload_outlined),
            selectedIcon: Icon(Icons.cloud_upload),
            label: 'Upload',
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
