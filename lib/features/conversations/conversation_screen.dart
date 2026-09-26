import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/app_scope.dart';
import '../../core/backend_scope.dart';
import '../../core/models/alphabet.dart';
import '../../core/models/conversation.dart';
import '../../core/models/message.dart';
import '../../core/models/profile.dart';
import '../../core/session_state.dart';
import '../../core/media/image_picker_service.dart';
import '../../core/realtime/typing_channel.dart';
import '../../theme/theme.dart';
import '../keyboard/custom_keyboard.dart';
import 'animated_glyph_text.dart';
import 'attachment_bubble.dart';
import 'conversation_settings_screen.dart';
import 'media_gallery_screen.dart';
import 'live_glyph_preview.dart';
import 'typing_indicator.dart';
import '../../widgets/app_text.dart';

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

  late Profile _otherMember = widget.conversation.otherMember;

  StreamSubscription<List<Message>>? _sub;
  List<Message> _messages = [];
  final List<Message> _pending = [];
  bool _loading = true;
  bool _offline = false;
  Timer? _retryTimer;
  int _tempIdCounter = 0;
  bool _firstSnapshot = true;
  bool _uploadingAttachment = false;

  late final TypingChannel _typingChannel;
  bool _amTyping = false;
  bool _otherTyping = false;
  Timer? _otherTypingTimeout;

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
    _typingChannel = TypingChannel(backend.client);
    _typingChannel.connect(conversationId: widget.conversation.id, onTyping: _onTypingEvent);
    _controller.addListener(_onComposeTextChanged);
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
        _markReceipts(msgs);
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
    _otherTypingTimeout?.cancel();
    _controller.removeListener(_onComposeTextChanged);
    if (_amTyping) _typingChannel.sendTyping(_myId, false);
    _typingChannel.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Broadcasts our own typing state whenever it flips — not on every
  /// keystroke, just the empty<->non-empty transitions (starting to
  /// type, clearing the field, and — since `_send()` clears the
  /// controller — sending, which is exactly when it should disappear for
  /// the other person too).
  void _onComposeTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText == _amTyping) return;
    _amTyping = hasText;
    _typingChannel.sendTyping(_myId, hasText);
  }

  void _onTypingEvent(String userId, bool typing) {
    if (userId == _myId || !mounted) return;
    setState(() => _otherTyping = typing);
    if (typing) _scrollToBottom();
    _otherTypingTimeout?.cancel();
    if (typing) {
      // Guards against a stuck indicator if the other device closes the
      // tab (or loses connection) mid-type without ever sending "false".
      _otherTypingTimeout = Timer(const Duration(seconds: 6), () {
        if (mounted) setState(() => _otherTyping = false);
      });
    }
  }

  /// The recipient (never the sender) stamps delivered/read on the
  /// other person's messages. If this screen is open at all, the message
  /// is both delivered and seen, so both land together — there's no
  /// separate "app open but chat closed" state to model here.
  void _markReceipts(List<Message> msgs) {
    final myId = _myId;
    final toMark = msgs
        .where((m) => m.senderId != myId && (m.deliveredAt == null || m.readAt == null))
        .map((m) => m.id)
        .toList();
    if (toMark.isEmpty) return;
    final backend = BackendScope.readOf(context);
    backend.messages.markDelivered(toMark);
    backend.messages.markRead(toMark);
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
        text: message.text!,
      );
      // Deliberately NOT removing `message` from `_pending` here: the
      // insert succeeding only means the server has it, not that our own
      // realtime stream has caught up yet. Removing it immediately opened
      // a gap — invisible in neither `_pending` nor `_messages` — until
      // the stream listener's own removeWhere (below) caught up moments
      // later, which is exactly the "message disappears for a second"
      // bug. The stream listener is the only place that removes it now.
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

  Future<void> _pickAndSendAttachment({bool useCamera = false}) async {
    final picked = await ImagePickerService.pickMedia(useCamera: useCamera);
    if (picked == null || !mounted) return;

    setState(() => _uploadingAttachment = true);
    final backend = BackendScope.readOf(context);
    try {
      final url = await backend.messages.uploadAttachment(widget.conversation.id, picked.bytes, extension: picked.extension);
      await backend.messages.sendAttachment(
        conversationId: widget.conversation.id,
        senderId: _myId,
        attachmentUrl: url,
        attachmentType: picked.isVideo ? AttachmentType.video : AttachmentType.image,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: AppText('Invio non riuscito. Riprova.')));
      }
    } finally {
      if (mounted) setState(() => _uploadingAttachment = false);
    }
  }

  Future<void> _openSettings() async {
    final result = await Navigator.of(context).push<ConversationSettingsResult>(
      MaterialPageRoute(
        builder: (_) => ConversationSettingsScreen(conversationId: widget.conversation.id, otherMember: _otherMember),
      ),
    );
    if (!mounted || result == null) return;
    switch (result) {
      case ConversationRenamed(:final name):
        setState(() => _otherMember =
            Profile(id: _otherMember.id, username: _otherMember.username, displayName: name, avatarUrl: _otherMember.avatarUrl));
      case ConversationCleared():
        setState(() => _messages = []);
      case ConversationDeleted():
        Navigator.of(context).pop(true);
    }
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
    final other = _otherMember;

    return Container(
      decoration: BoxDecoration(gradient: AppGradients.background),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(AppIcons.arrowLeft),
            onPressed: () => Navigator.of(context).pop(),
          ),
          titleSpacing: 0,
          title: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MediaGalleryScreen(conversationId: widget.conversation.id, otherDisplayName: other.displayName),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.blush,
                  backgroundImage: other.avatarUrl != null ? NetworkImage(other.avatarUrl!) : null,
                  child: other.avatarUrl == null
                      ? AppText(
                          other.displayName.characters.first.toUpperCase(),
                          style: AppTypography.label(color: AppColors.berry),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(other.displayName, style: AppTypography.titleCompact()),
                    AppText('@${other.username}', style: AppTypography.label()),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(AppIcons.gearSix),
              onPressed: _openSettings,
            ),
          ],
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
                        Icon(AppIcons.cloudSlash, size: 14, color: AppColors.berry),
                        const SizedBox(width: AppSpacing.xs),
                        AppText(
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
                              child: AppText(
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
              AnimatedSwitcher(
                duration: AppMotion.fast,
                child: _otherTyping
                    ? Padding(
                        key: const ValueKey('typing'),
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                        child: const TypingIndicator(),
                      )
                    : const SizedBox.shrink(key: ValueKey('not-typing')),
              ),
              _ComposeArea(
                controller: _controller,
                alphabet: appState.alphabet,
                customEnabled: customEnabled,
                onSend: _send,
                onAttach: _uploadingAttachment ? null : _pickAndSendAttachment,
                onCamera: _uploadingAttachment ? null : () => _pickAndSendAttachment(useCamera: true),
                attaching: _uploadingAttachment,
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

String _formatTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

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
              if (message.hasAttachment) ...[
                AttachmentBubble(url: message.attachmentUrl!, type: message.attachmentType!),
                if (message.text != null && message.text!.isNotEmpty) const SizedBox(height: AppSpacing.xs),
              ],
              if (message.text != null && message.text!.isNotEmpty)
                AnimatedGlyphText(
                  message.text!,
                  alphabet: alphabet,
                  enabled: customEnabled,
                  animate: animate,
                  fontSize: 18,
                  color: textColor,
                ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!message.pending)
                    AppText(_formatTime(message.createdAt), style: AppTypography.label(color: textColor.withValues(alpha: 0.7))),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    // Grey single check: not sent yet (still local/pending).
                    // Grey double check: sent, not read yet.
                    // Green double check: read.
                    Icon(
                      message.pending ? AppIcons.check : AppIcons.checks,
                      size: 14,
                      color: message.readAt != null ? AppColors.readGreen : textColor.withValues(alpha: 0.65),
                    ),
                  ],
                ],
              ),
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
  final VoidCallback? onAttach;
  final VoidCallback? onCamera;
  final bool attaching;

  const _ComposeArea({
    required this.controller,
    required this.alphabet,
    required this.customEnabled,
    required this.onSend,
    required this.onAttach,
    required this.onCamera,
    required this.attaching,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      color: AppColors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            onPressed: onAttach,
            icon: attaching
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.fuchsia),
                  )
                : Icon(AppIcons.paperclip, color: AppColors.berry),
          ),
          IconButton(
            onPressed: onCamera,
            icon: Icon(AppIcons.camera, color: AppColors.berry),
          ),
          Expanded(
            child: LiveGlyphPreview(controller: controller, alphabet: alphabet, customEnabled: customEnabled),
          ),
          const SizedBox(width: AppSpacing.sm),
          _SendButton(onPressed: onSend),
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
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Icon(AppIcons.paperPlaneTilt, color: AppColors.white, size: 22),
        ),
      ),
    );
  }
}
