import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/backend_scope.dart';
import '../alphabet/alphabet_preview_screen.dart';
import '../conversations/conversations_list_screen.dart';
import '../conversations/new_conversation_screen.dart';
import '../editor/editor_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alphabet = AppScope.of(context).alphabet;
    final profile = BackendScope.of(context).myProfile;

    return Scaffold(
      appBar: AppBar(title: const Text('Together')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NewConversationScreen()),
        ),
        child: const Icon(Icons.add_comment_outlined),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (profile != null) ...[
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    child: Text(profile.displayName.characters.first.toUpperCase()),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.displayName, style: Theme.of(context).textTheme.titleMedium),
                      Text('@${profile.username}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
            Text('Il tuo alfabeto', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              '${alphabet.completedCount} / 26 lettere create',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _HomeCard(
              icon: Icons.grid_view_rounded,
              label: 'Visualizza alfabeto',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AlphabetPreviewScreen()),
              ),
            ),
            _HomeCard(
              icon: Icons.edit_outlined,
              label: 'Modifica alfabeto',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditorScreen(sequential: false)),
              ),
            ),
            _HomeCard(
              icon: Icons.create_outlined,
              label: 'Prova a scrivere',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AlphabetPreviewScreen(focusTryField: true)),
              ),
            ),
            _HomeCard(
              icon: Icons.chat_bubble_outline,
              label: 'Conversazioni',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConversationsListScreen()),
              ),
            ),
            _HomeCard(
              icon: Icons.settings_outlined,
              label: 'Impostazioni',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HomeCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(label, style: Theme.of(context).textTheme.titleMedium),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
