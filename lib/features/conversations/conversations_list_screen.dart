import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/backend_scope.dart';
import '../../core/models/conversation.dart';
import '../../theme/theme.dart';
import 'conversation_screen.dart';
import 'new_conversation_screen.dart';

class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
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
        floatingActionButton: _Fab(onPressed: _newConversation),
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.fuchsia,
            onRefresh: _refresh,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.md),
                  sliver: SliverToBoxAdapter(
                    child: RichText(
                      text: TextSpan(children: [
                        TextSpan(text: 'LE TUE ', style: AppTypography.display()),
                        TextSpan(text: 'chat', style: AppTypography.accent(fontSize: 40)),
                      ]),
                    ).animate().fadeIn(duration: AppMotion.base, curve: AppMotion.enter).slideY(
                          begin: 0.2,
                          end: 0,
                          duration: AppMotion.base,
                          curve: AppMotion.emphasized,
                        ),
                  ),
                ),
                FutureBuilder<List<Conversation>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator(color: AppColors.fuchsia)),
                      );
                    }
                    if (snapshot.hasError) {
                      return SliverFillRemaining(
                        child: _EmptyState(
                          icon: AppIcons.cloudSlash,
                          message: 'Connessione non disponibile.\nRiprova più tardi.',
                        ),
                      );
                    }
                    final conversations = snapshot.data ?? const [];
                    if (conversations.isEmpty) {
                      return SliverFillRemaining(
                        child: _EmptyState(
                          icon: AppIcons.heart,
                          message: 'Nessuna conversazione ancora.\nTocca + per iniziarne una.',
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxxl),
                      sliver: SliverList.separated(
                        itemCount: conversations.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm + 2),
                        itemBuilder: (context, index) {
                          final c = conversations[index];
                          return _ConversationTile(conversation: c, index: index, onChanged: _refresh);
                        },
                      ),
                    );
                  },
                ),
              ],
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
        color: AppColors.white,
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
