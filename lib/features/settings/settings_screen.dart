import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/backend_scope.dart';
import '../../core/config/env.dart';
import '../../core/media/image_picker_service.dart';
import '../../core/push/push_service.dart';
import '../../theme/theme.dart';
import '../alphabet/alphabet_preview_screen.dart';
import '../auth/auth_gate.dart';
import '../editor/editor_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushSupported = false;
  bool _pushEnabled = false;
  bool _pushBusy = true;
  bool _avatarBusy = false;

  @override
  void initState() {
    super.initState();
    _loadPushState();
  }

  Future<void> _loadPushState() async {
    final supported = await PushService.isSupported();
    final enabled = supported && await PushService.isSubscribed();
    if (!mounted) return;
    setState(() {
      _pushSupported = supported;
      _pushEnabled = enabled;
      _pushBusy = false;
    });
  }

  Future<void> _togglePush(bool value) async {
    setState(() => _pushBusy = true);
    final session = BackendScope.readOf(context);
    if (value) {
      final ok = await session.enablePush(Env.vapidPublicKey);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Non è stato possibile attivare le notifiche. Controlla i permessi del browser.')),
        );
      }
      setState(() {
        _pushEnabled = ok;
        _pushBusy = false;
      });
    } else {
      await session.disablePush();
      if (!mounted) return;
      setState(() {
        _pushEnabled = false;
        _pushBusy = false;
      });
    }
  }

  Future<void> _changeAvatar() async {
    final picked = await ImagePickerService.pickImage();
    if (picked == null || !mounted) return;
    setState(() => _avatarBusy = true);
    try {
      await BackendScope.readOf(context).updateMyAvatar(picked.bytes, extension: picked.extension);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Non è stato possibile aggiornare la foto.')));
      }
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _renameMyself(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambia il tuo nome'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTypography.body(),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('ANNULLA')),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('SALVA')),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName.trim().isEmpty || !mounted) return;
    try {
      await BackendScope.readOf(context).updateMyDisplayName(newName.trim());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Non è stato possibile salvare il nome.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final settings = state.settings;
    final session = BackendScope.of(context);
    final profile = session.myProfile;

    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.background),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(AppIcons.arrowLeft),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('Impostazioni', style: AppTypography.titleCompact()),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (profile != null) ...[
                const _SectionLabel('Il tuo profilo'),
                _Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _avatarBusy ? null : _changeAvatar,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: AppColors.blush,
                                backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
                                child: profile.avatarUrl == null
                                    ? Text(
                                        profile.displayName.characters.first.toUpperCase(),
                                        style: AppTypography.titleCompact(color: AppColors.berry),
                                      )
                                    : null,
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: AppColors.fuchsia, shape: BoxShape.circle),
                                child: _avatarBusy
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.white),
                                      )
                                    : const Icon(AppIcons.camera, size: 14, color: AppColors.white),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile.displayName, style: AppTypography.titleCompact()),
                              Text('@${profile.username}', style: AppTypography.bodySmall()),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(AppIcons.pencilSimple, size: 18),
                          onPressed: () => _renameMyself(profile.displayName),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              const _SectionLabel('Alfabeto'),
              _Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(AppIcons.gridFour),
                      title: Text('Visualizza alfabeto', style: AppTypography.body()),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AlphabetPreviewScreen()),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(AppIcons.pencilSimple),
                      title: Text('Modifica alfabeto', style: AppTypography.body()),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EditorScreen(sequential: false)),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(AppIcons.keyboard),
                      title: Text('Prova a scrivere', style: AppTypography.body()),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AlphabetPreviewScreen(focusTryField: true)),
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      activeThumbColor: AppColors.fuchsia,
                      title: Text('Alfabeto personalizzato', style: AppTypography.body()),
                      subtitle: Text(
                        'Quando è OFF il testo viene mostrato normalmente.',
                        style: AppTypography.bodySmall(),
                      ),
                      value: settings.customAlphabetEnabled,
                      onChanged: (v) => state.updateSettings((s) => s.copyWith(customAlphabetEnabled: v)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SectionLabel('Notifiche'),
              _Card(
                child: SwitchListTile(
                  activeThumbColor: AppColors.fuchsia,
                  title: Text('Notifiche push', style: AppTypography.body()),
                  subtitle: Text(
                    _pushSupported
                        ? 'Ricevi una notifica quando arriva un nuovo messaggio, anche ad app chiusa.'
                        : 'Non disponibili su questo browser. Su iPhone: aggiungi Together alla schermata Home, poi apri l\'app da lì.',
                    style: AppTypography.bodySmall(),
                  ),
                  value: _pushEnabled,
                  onChanged: (!_pushSupported || _pushBusy) ? null : _togglePush,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SectionLabel('Info'),
              _Card(
                child: ListTile(
                  title: Text('Together', style: AppTypography.body()),
                  subtitle: Text('Il tuo alfabeto, il tuo modo di scrivere.', style: AppTypography.bodySmall()),
                ),
              ),
              if (profile != null) ...[
                const SizedBox(height: AppSpacing.md),
                _Card(
                  child: ListTile(
                    leading: const Icon(AppIcons.signOut, color: AppColors.berry),
                    title: Text('Esci', style: AppTypography.body(color: AppColors.berry)),
                    subtitle: Text('@${profile.username}', style: AppTypography.bodySmall()),
                    onTap: () async {
                      await session.auth.signOut();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AuthGate()),
                        (route) => false,
                      );
                    },
                  ),
                ),
              ],
            ],
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
      child: Text(text, style: AppTypography.label(color: AppColors.berry)),
    );
  }
}
