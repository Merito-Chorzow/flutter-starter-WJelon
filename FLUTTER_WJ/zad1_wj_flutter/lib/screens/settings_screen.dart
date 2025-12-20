import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeStore = context.watch<ThemeStore>();

    return Scaffold(
      appBar: AppBar(title: const Text("Ustawienia")),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Motyw ciemny"),
            value: themeStore.isDark,
            onChanged: (_) => themeStore.toggle(),
          ),
        ],
      ),
    );
  }
}
