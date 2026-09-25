import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/backend_scope.dart';
import '../../theme/theme.dart';
import '../auth/auth_gate.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final settings = state.settings;
    final session = BackendScope.of(context);

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
              const _SectionLabel('Alfabeto'),
              _Card(
                child: SwitchListTile(
                  activeThumbColor: AppColors.fuchsia,
                  title: Text('Alfabeto personalizzato', style: AppTypography.body()),
                  subtitle: Text(
                    'Quando è OFF il testo viene mostrato normalmente (utile per debug e accessibilità).',
                    style: AppTypography.bodySmall(),
                  ),
                  value: settings.customAlphabetEnabled,
                  onChanged: (v) => state.updateSettings((s) => s.copyWith(customAlphabetEnabled: v)),
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
              if (session.myProfile != null) ...[
                const SizedBox(height: AppSpacing.md),
                _Card(
                  child: ListTile(
                    leading: const Icon(AppIcons.signOut, color: AppColors.berry),
                    title: Text('Esci', style: AppTypography.body(color: AppColors.berry)),
                    subtitle: Text('@${session.myProfile!.username}', style: AppTypography.bodySmall()),
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
