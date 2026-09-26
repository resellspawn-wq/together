import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/backend_scope.dart';
import '../../core/models/conversation.dart';
import '../../theme/theme.dart';
import '../../widgets/animated_gradient_background.dart';
import '../conversations/conversation_screen.dart';
import '../conversations/new_conversation_screen.dart';
import '../settings/settings_screen.dart';

/// The app's root screen once signed in and onboarded: a WhatsApp-style
/// chat list, with the user's own avatar (tap -> Settings) up top instead
/// of a separate "home menu" — alphabet tools now live inside Settings.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Conversation>> _future;

  @override
  void initState() {
    super.initState();
    _future = BackendScope.readOf(context).loadConversations();
  }

  Future<void> _refresh() async {
    final future = BackendScope.readOf(context).loadConversations();
    setState(() => _future = future);
    await future;
  }

  Future<void> _newConversation() async {
    final started = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const NewConversationScreen()),
    );
    if (started == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final profile = BackendScope.of(context).myProfile;

    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.white.withValues(alpha: 0.55),
          elevation: 0,
          leadingWidth: 64,
          leading: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md),
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.blush,
                backgroundImage: profile?.avatarUrl != null ? NetworkImage(profile!.avatarUrl!) : null,
                child: profile?.avatarUrl == null
                    ? Text(
                        (profile?.displayName ?? '?').characters.first.toUpperCase(),
                        style: AppTypography.body(color: AppColors.berry).copyWith(fontWeight: FontWeight.w700),
                      )
                    : null,
              ),
            ),
          ),
          title: Text('Together', style: AppTypography.titleCompact()),
        ),
        floatingActionButton: _Fab(onPressed: _newConversation),
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.fuchsia,
            onRefresh: _refresh,
            child: FutureBuilder<List<Conversation>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.fuchsia));
                }
                if (snapshot.hasError) {
                  return _EmptyState(
                    icon: AppIcons.cloudSlash,
                    message: 'Connessione non disponibile.\nRiprova più tardi.',
                  );
                }
                final conversations = snapshot.data ?? const [];
                if (conversations.isEmpty) {
                  return _EmptyState(
                    icon: AppIcons.heart,
                    message: 'Nessuna conversazione ancora.\nTocca + per iniziarne una.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
                  itemCount: conversations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final c = conversations[index];
                    return _ConversationTile(conversation: c, index: index, onChanged: _refresh);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final int index;
  final VoidCallback onChanged;

  const _ConversationTile({required this.conversation, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final other = conversation.otherMember;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.chromeLight, width: 1),
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          onTap: () async {
            final changed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => ConversationScreen(conversation: conversation)),
            );
            if (changed == true) onChanged();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.blush,
                  child: Text(
                    other.displayName.characters.first.toUpperCase(),
                    style: AppTypography.body(color: AppColors.berry).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(other.displayName, style: AppTypography.titleCompact()),
                      Text('@${other.username}', style: AppTypography.bodySmall()),
                    ],
                  ),
                ),
                const Icon(AppIcons.caretRight, size: 18, color: AppColors.inkSoft),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: AppMotion.staggerStep * index)
        .fadeIn(duration: AppMotion.base, curve: AppMotion.enter)
        .slideY(begin: 0.15, end: 0, duration: AppMotion.base, curve: AppMotion.emphasized);
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.mauve),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  final VoidCallback onPressed;

  const _Fab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fuchsia,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Icon(AppIcons.plusCircle, color: AppColors.white, size: 26),
        ),
      ),
    );
  }
}
