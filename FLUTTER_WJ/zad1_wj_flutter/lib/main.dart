import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/api_service.dart';
import 'state/entries_store.dart';

import 'screens/entries_list_screen.dart';
import 'screens/entry_detail_screen.dart';
import 'screens/add_entry_screen.dart';
import 'screens/settings_screen.dart';

class ThemeStore extends ChangeNotifier {
  bool isDark = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    isDark = prefs.getBool("darkTheme") ?? false;
    notifyListeners();
  }

  Future<void> toggle() async {
    isDark = !isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("darkTheme", isDark);
  }
}

void main() {
  runApp(const AppRoot());
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeStore()..load()),
        Provider(create: (_) => ApiService()),
        ChangeNotifierProvider(
          create: (ctx) => EntriesStore(ctx.read<ApiService>()),
        ),
      ],
      child: const App(),
    );
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final themeStore = context.watch<ThemeStore>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "GeoNotes",
      themeMode: themeStore.isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: const HomeShell(),
      onGenerateRoute: (settings) {
        if (settings.name == "/detail") {
          final id = settings.arguments as int;
          return MaterialPageRoute(builder: (_) => EntryDetailScreen(entryId: id));
        }
        return null;
      },
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _pages = const [
    EntriesListScreen(),
    AddEntryScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<EntriesStore>().loadEntries());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: _pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: "Wpisy",
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: "Dodaj",
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: "Ustawienia",
          ),
        ],
      ),
    );
  }
}
