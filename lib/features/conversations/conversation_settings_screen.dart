import 'package:flutter/material.dart';

import '../../core/backend_scope.dart';
import '../../core/models/profile.dart';
import '../../theme/theme.dart';
import '../../widgets/app_text.dart';

/// What happened on this screen, so [ConversationScreen] can react
/// without this screen needing to know anything about the chat itself.
sealed class ConversationSettingsResult {
  const ConversationSettingsResult();
}

class ConversationRenamed extends ConversationSettingsResult {
  final String name;
  const ConversationRenamed(this.name);
}

class ConversationCleared extends ConversationSettingsResult {
  const ConversationCleared();
}

class ConversationDeleted extends ConversationSettingsResult {
  const ConversationDeleted();
}

/// A dedicated page for a single contact's chat options (rename, clear,
/// delete) — reached via a settings icon in the chat's app bar, instead
/// of a popup menu.
class ConversationSettingsScreen extends StatefulWidget {
  final String conversationId;
  final Profile otherMember;

  const ConversationSettingsScreen({super.key, required this.conversationId, required this.otherMember});

  @override
  State<ConversationSettingsScreen> createState() => _ConversationSettingsScreenState();
}

class _ConversationSettingsScreenState extends State<ConversationSettingsScreen> {
  late String _displayName = widget.otherMember.displayName;
  bool _busy = false;

  Future<void> _rename() async {
    final controller = TextEditingController(text: _displayName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppText('Cambia nome contatto'),
        content: TextField(controller: controller, autofocus: true, onSubmitted: (v) => Navigator.of(context).pop(v)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const AppText('ANNULLA')),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const AppText('SALVA')),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName.trim().isEmpty || !mounted) return;
    final trimmed = newName.trim();
    setState(() {
      _busy = true;
      _displayName = trimmed;
    });
    try {
      await BackendScope.readOf(context).renameConversation(widget.conversationId, trimmed);
    } catch (_) {
      // Best-effort — the name still shows locally.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm({required String title, required String message, required String confirmLabel}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText(title),
        content: AppText(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const AppText('ANNULLA')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: AppText(confirmLabel)),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _clearChat() async {
    final ok = await _confirm(
      title: 'Svuotare la chat?',
      message: 'Tutti i messaggi con $_displayName verranno eliminati per entrambi.',
      confirmLabel: 'SVUOTA',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await BackendScope.readOf(context).clearChat(widget.conversationId);
      if (mounted) Navigator.of(context).pop(const ConversationCleared());
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: AppText('Non è stato possibile svuotare la chat.')));
      }
    }
  }

  Future<void> _deleteContact() async {
    final ok = await _confirm(
      title: 'Eliminare il contatto?',
      message: 'La conversazione con $_displayName verrà eliminata per entrambi.',
      confirmLabel: 'ELIMINA',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await BackendScope.readOf(context).deleteConversation(widget.conversationId);
      if (mounted) Navigator.of(context).pop(const ConversationDeleted());
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: AppText('Non è stato possibile eliminare il contatto.')));
      }
    }
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
            onPressed: () => Navigator.of(context).pop(
              _displayName != widget.otherMember.displayName ? ConversationRenamed(_displayName) : null,
            ),
          ),
          title: AppText('Opzioni chat', style: AppTypography.titleCompact()),
        ),
        body: SafeArea(
          child: AbsorbPointer(
            absorbing: _busy,
            child: Opacity(
              opacity: _busy ? 0.6 : 1,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _Card(
                    child: ListTile(
                      leading: const Icon(AppIcons.pencilSimple),
                      title: AppText('Cambia nome', style: AppTypography.body()),
                      subtitle: AppText(_displayName, style: AppTypography.bodySmall()),
                      onTap: _rename,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _Card(
                    child: ListTile(
                      leading: const Icon(AppIcons.trash),
                      title: AppText('Svuota chat', style: AppTypography.body()),
                      onTap: _clearChat,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _Card(
                    child: ListTile(
                      leading: const Icon(AppIcons.trash, color: AppColors.berry),
                      title: AppText('Elimina contatto', style: AppTypography.body(color: AppColors.berry)),
                      onTap: _deleteContact,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.chromeLight, width: 1),
        boxShadow: AppShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
