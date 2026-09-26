import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/backend_scope.dart';
import '../../core/models/conversation.dart';
import '../../core/models/profile.dart';
import '../../theme/theme.dart';
import 'conversation_screen.dart';
import '../../widgets/app_text.dart';

class NewConversationScreen extends StatefulWidget {
  const NewConversationScreen({super.key});

  @override
  State<NewConversationScreen> createState() => _NewConversationScreenState();
}

class _NewConversationScreenState extends State<NewConversationScreen> {
  final _username = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final username = _username.text.trim().toLowerCase().replaceFirst('@', '');
    if (username.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final backend = BackendScope.readOf(context);
    try {
      final profile = await backend.profiles.findByUsername(username);
      if (profile == null) {
        setState(() => _error = 'Nessun utente trovato con questo username.');
        return;
      }
      if (!mounted) return;
      final nickname = await _askNickname(profile.displayName);
      if (nickname == null) return; // user cancelled

      final conversationId = await backend.conversations.startConversationWith(username, nickname: nickname);
      if (!mounted) return;
      final named = nickname.trim().isEmpty
          ? profile
          : Profile(id: profile.id, username: profile.username, displayName: nickname.trim());
      final conversation = Conversation(id: conversationId, createdAt: DateTime.now(), otherMember: named);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ConversationScreen(conversation: conversation)),
      );
    } catch (e) {
      setState(() => _error = 'Non è stato possibile avviare la conversazione. Riprova.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Asks what name to give this contact before adding it, prefilled with
  /// their real display name. Returns null if the user cancels.
  Future<String?> _askNickname(String suggested) async {
    final controller = TextEditingController(text: suggested);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppText('Che nome vuoi dargli?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTypography.body(),
          decoration: const InputDecoration(hintText: 'Nome del contatto'),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const AppText('ANNULLA')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const AppText('CONTINUA'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.background),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(AppIcons.arrowLeft),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),
                AppText('NUOVA', style: AppTypography.display())
                    .animate()
                    .fadeIn(duration: AppMotion.base, curve: AppMotion.enter)
                    .slideY(begin: 0.2, end: 0, duration: AppMotion.base, curve: AppMotion.emphasized),
                AppText('conversazione', style: AppTypography.accent(fontSize: 36))
                    .animate(delay: AppMotion.staggerStep)
                    .fadeIn(duration: AppMotion.base, curve: AppMotion.enter)
                    .slideY(begin: 0.2, end: 0, duration: AppMotion.base, curve: AppMotion.emphasized),
                const SizedBox(height: AppSpacing.xxl),
                AppText('Cerca per username', style: AppTypography.label()),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _username,
                  autofocus: true,
                  style: AppTypography.body(),
                  decoration: const InputDecoration(prefixText: '@ ', hintText: 'eliza'),
                  onSubmitted: (_) => _start(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppText(_error!, style: AppTypography.bodySmall(color: AppColors.berry)),
                ],
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: _loading ? null : _start,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.white),
                        )
                      : const AppText('INIZIA CONVERSAZIONE'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
