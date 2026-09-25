import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/backend_scope.dart';
import '../../core/models/app_settings.dart';
import '../auth/auth_gate.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final settings = state.settings;
    final session = BackendScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionLabel('Aspetto'),
            RadioListTile<AppThemeMode>(
              title: const Text('Sistema'),
              value: AppThemeMode.system,
              groupValue: settings.themeMode,
              onChanged: (v) => state.updateSettings((s) => s.copyWith(themeMode: v)),
            ),
            RadioListTile<AppThemeMode>(
              title: const Text('Chiaro'),
              value: AppThemeMode.light,
              groupValue: settings.themeMode,
              onChanged: (v) => state.updateSettings((s) => s.copyWith(themeMode: v)),
            ),
            RadioListTile<AppThemeMode>(
              title: const Text('Scuro'),
              value: AppThemeMode.dark,
              groupValue: settings.themeMode,
              onChanged: (v) => state.updateSettings((s) => s.copyWith(themeMode: v)),
            ),
            const Divider(height: 32),
            const _SectionLabel('Alfabeto'),
            SwitchListTile(
              title: const Text('Alfabeto personalizzato'),
              subtitle: const Text('Quando è OFF il testo viene mostrato normalmente (utile per debug e accessibilità).'),
              value: settings.customAlphabetEnabled,
              onChanged: (v) => state.updateSettings((s) => s.copyWith(customAlphabetEnabled: v)),
            ),
            const Divider(height: 32),
            const _SectionLabel('Info'),
            const ListTile(
              title: Text('Together'),
              subtitle: Text('Il tuo alfabeto, il tuo modo di scrivere.'),
            ),
            if (session.myProfile != null)
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Esci'),
                subtitle: Text('@${session.myProfile!.username}'),
                onTap: () async {
                  await session.auth.signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthGate()),
                    (route) => false,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
