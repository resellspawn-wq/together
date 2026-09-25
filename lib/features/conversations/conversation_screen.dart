import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/app_scope.dart';
import '../../core/backend_scope.dart';
import '../../core/models/alphabet.dart';
import '../../core/models/conversation.dart';
import '../../core/models/message.dart';
import '../../core/session_state.dart';
import '../../theme/theme.dart';
import '../keyboard/custom_keyboard.dart';
import 'animated_glyph_text.dart';
import 'live_glyph_preview.dart';

/// A single 1-to-1 conversation. Messages are plain Unicode text in the
/// database and in [TextEditingController] at every point — this screen
/// only ever *renders* them (through [AnimatedGlyphText] /
/// [CustomText]); it never stores or sends glyph data.
class ConversationScreen extends StatefulWidget {
  final Conversation conversation;

  const ConversationScreen({super.key, required this.conversation});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  StreamSubscription<List<Message>>? _sub;
  List<Message> _messages = [];
  final List<Message> _pending = [];
  bool _loading = true;
  bool _offline = false;
  Timer? _retryTimer;
  int _tempIdCounter = 0;
  bool _firstSnapshot = true;

  /// Message ids that have already been shown once — anything in here
  /// renders instantly (history); anything not in here plays the
  /// handwriting-reveal once, then gets added so it never replays (e.g.
  /// when scrolled off-screen and back).
  final Set<String> _revealedIds = {};

  String get _myId => BackendScope.readOf(context).auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    final backend = BackendScope.readOf(context);
    final cached = backend.loadCachedMessages(widget.conversation.id);
    if (cached.isNotEmpty) {
      _messages = cached;
      _loading = false;
      _revealedIds.addAll(cached.map((m) => m.id));
    }
    _sub = backend.messages.watchConversation(widget.conversation.id).listen(
      (msgs) {
        if (_firstSnapshot) {
          _revealedIds.addAll(msgs.map((m) => m.id));
          _firstSnapshot = false;
        }
        setState(() {
          _messages = msgs;
          _loading = false;
          _offline = false;
        });
        backend.cacheMessages(widget.conversation.id, msgs);
        // Anything we optimistically added has now really landed.
        _pending.removeWhere((p) => msgs.any((m) => m.text == p.text && m.senderId == p.senderId));
        _scrollToBottom();
      },
      onError: (Object _) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _offline = true;
        });
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _retryTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppMotion.fast,
        curve: AppMotion.enter,
      );
    });
  }

  void _insert(String char) {
    final selection = _controller.selection;
    final text = _controller.text;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final newText = text.replaceRange(start, end, char);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + char.length),
    );
  }

  void _backspace() {
    final selection = _controller.selection;
    final text = _controller.text;
    if (!selection.isValid || selection.isCollapsed) {
      final cursor = selection.baseOffset >= 0 ? selection.baseOffset : text.length;
      if (cursor <= 0) return;
      final newText = text.replaceRange(cursor - 1, cursor, '');
      _controller.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: cursor - 1));
    } else {
      final newText = text.replaceRange(selection.start, selection.end, '');
      _controller.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: selection.start));
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final myId = _myId;
    final optimistic = Message(
      id: 'pending-${_tempIdCounter++}',
      conversationId: widget.conversation.id,
      senderId: myId,
      text: text,
      createdAt: DateTime.now(),
      pending: true,
    );
    setState(() => _pending.add(optimistic));
    await _attemptSend(optimistic);
  }

  Future<void> _attemptSend(Message message) async {
    final backend = BackendScope.readOf(context);
    try {
      await backend.messages.send(
        conversationId: message.conversationId,
        senderId: message.senderId,
        text: message.text,
      );
      if (!mounted) return;
      setState(() => _pending.removeWhere((p) => p.id == message.id));
    } catch (_) {
      if (!mounted) return;
      setState(() => _offline = true);
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 5), () {
      for (final m in List<Message>.of(_pending)) {
        _attemptSend(m);
      }
    });
  }

  Alphabet _alphabetFor(String senderId, Alphabet myAlphabet, SessionState session) {
    if (senderId == _myId) return myAlphabet;
    final cached = session.cachedAlphabetFor(senderId);
    if (cached == null) {
      session.alphabetFor(senderId);
      return Alphabet.blank(id: senderId);
    }
    return cached;
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final session = BackendScope.of(context);
    final customEnabled = appState.settings.customAlphabetEnabled;
    final allMessages = [..._messages, ..._pending]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final other = widget.conversation.otherMember;

    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.background),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(AppIcons.arrowLeft),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(other.displayName, style: AppTypography.titleCompact()),
              Text('@${other.username}', style: AppTypography.label()),
            ],
          ),
          bottom: _offline
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(32),
                  child: Container(
                    width: double.infinity,
                    color: AppColors.blush,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(AppIcons.cloudSlash, size: 14, color: AppColors.berry),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'offline — invio alla riconnessione',
                          style: AppTypography.label(color: AppColors.berry),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : allMessages.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                              child: Text(
                                'Scrivi il primo messaggio a ${other.displayName}',
                                textAlign: TextAlign.center,
                                style: AppTypography.body(color: AppColors.inkSoft),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            itemCount: allMessages.length,
                            itemBuilder: (context, index) {
                              final message = allMessages[index];
                              final isMine = message.senderId == _myId;
                              final alphabet = _alphabetFor(message.senderId, appState.alphabet, session);
                              final isNew = !_revealedIds.contains(message.id);
                              if (isNew) _revealedIds.add(message.id);
                              return _MessageBubble(
                                key: ValueKey(message.id),
                                message: message,
                                isMine: isMine,
                                alphabet: alphabet,
                                customEnabled: customEnabled,
                                animate: isNew,
                                onRetry: message.pending ? () => _attemptSend(message) : null,
                              );
                            },
                          ),
              ),
              _ComposeArea(
                controller: _controller,
                alphabet: appState.alphabet,
                customEnabled: customEnabled,
                onSend: _send,
              ),
              CustomKeyboard(
                alphabet: appState.alphabet,
                showCustomGlyphs: customEnabled,
                onCharacter: _insert,
                onBackspace: _backspace,
                onEnter: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  final Alphabet alphabet;
  final bool customEnabled;
  final bool animate;
  final VoidCallback? onRetry;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.alphabet,
    required this.customEnabled,
    required this.animate,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isMine ? AppColors.white : AppColors.ink;

    final bubble = Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: onRetry,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isMine ? AppColors.fuchsia : AppColors.white,
            borderRadius: BorderRadius.circular(AppRadii.bubble),
            border: isMine ? null : Border.all(color: AppColors.chromeMid, width: 1),
            boxShadow: isMine ? AppShadows.fuchsiaGlow : AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedGlyphText(
                message.text,
                alphabet: alphabet,
                enabled: customEnabled,
                animate: animate,
                fontSize: 18,
                color: textColor,
              ),
              if (message.pending) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.clock, size: 12, color: textColor.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text('in invio…', style: AppTypography.label(color: textColor.withValues(alpha: 0.7))),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );

    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (!animate || reduceMotion) return bubble;

    // "Il bigliettino sale morbido dalla tastiera nella chat."
    return bubble
        .animate()
        .fadeIn(duration: AppMotion.messageRise, curve: AppMotion.enter)
        .slideY(begin: 0.3, end: 0, duration: AppMotion.messageRise, curve: AppMotion.emphasized);
  }
}

/// Sits above the on-screen keyboard: a live preview of the message being
/// composed, rendered with the user's own custom glyphs as they type,
/// plus the real editable field underneath it. The controller (and thus
/// the plain-text value that gets sent) is the single source of truth;
/// this widget only ever adds a read-only visual layer on top of it.
class _ComposeArea extends StatelessWidget {
  final TextEditingController controller;
  final Alphabet alphabet;
  final bool customEnabled;
  final VoidCallback onSend;

  const _ComposeArea({
    required this.controller,
    required this.alphabet,
    required this.customEnabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LiveGlyphPreview(controller: controller, alphabet: alphabet, customEnabled: customEnabled),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: true,
                  showCursor: true,
                  cursorColor: AppColors.fuchsia,
                  keyboardType: TextInputType.none,
                  maxLines: 3,
                  minLines: 1,
                  style: AppTypography.messageText(),
                  decoration: InputDecoration(
                    hintText: 'Messaggio',
                    hintStyle: AppTypography.body(color: AppColors.inkSoft),
                    isDense: true,
                    fillColor: AppColors.mist,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _SendButton(onPressed: onSend),
            ],
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SendButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fuchsia,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Icon(AppIcons.paperPlaneTilt, color: AppColors.white, size: 22),
        ),
      ),
    );
  }
}
