import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_scope.dart';
import 'core/app_state.dart';
import 'core/backend_scope.dart';
import 'core/config/env.dart';
import 'core/models/alphabet.dart';
import 'core/session_state.dart';
import 'core/storage/storage_service.dart';
import 'features/auth/auth_gate.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.create();

  if (!Env.isConfigured) {
    runApp(const _MissingConfigApp());
    return;
  }

  await Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabaseAnonKey);
  final sessionState = SessionState(Supabase.instance.client, storage);

  // Local alphabet/settings are namespaced per signed-in user (see
  // StorageService) so two accounts opened on the same device never see
  // each other's local data. Set the namespace for whoever is already
  // signed in (a persisted session, e.g. app reopened) before AppState's
  // first read, then keep it in sync on every login/logout/account switch.
  storage.useNamespace(sessionState.auth.currentUser?.id);
  final appState = AppState(storage);

  String? lastUserId = sessionState.auth.currentUser?.id;
  sessionState.addListener(() {
    final currentUserId = sessionState.auth.currentUser?.id;
    if (currentUserId == lastUserId) return;
    lastUserId = currentUserId;
    storage.useNamespace(currentUserId);
    appState.reload();
    if (currentUserId != null) _pullAlphabetIfLocalIsEmpty(sessionState, appState, currentUserId);
  });
  // Cover the "already signed in when the app opens" case too (the
  // listener above only fires on a *change*).
  final initialUserId = lastUserId;
  if (initialUserId != null) _pullAlphabetIfLocalIsEmpty(sessionState, appState, initialUserId);

  runApp(TogetherApp(appState: appState, sessionState: sessionState));
}

/// The alphabet is local-first (so the editor works instantly and
/// offline), unlike conversations/messages which are always fetched live
/// from Supabase — that's why logging into the same account on a new
/// device used to show conversations immediately but an empty alphabet.
/// This pulls the account's alphabet down from the cloud once, the first
/// time it's needed locally (i.e. only when this device has nothing
/// saved yet — an existing local alphabet is never overwritten).
Future<void> _pullAlphabetIfLocalIsEmpty(SessionState session, AppState appState, String userId) async {
  if (appState.alphabet.completedCount > 0) return;
  try {
    final remote = await session.alphabets.fetchAlphabet(userId);
    for (final letter in kAlphabetLetters) {
      final glyph = remote.glyphFor(letter);
      if (glyph != null && glyph.hasStrokes) {
        await appState.saveGlyph(glyph);
      }
    }
  } catch (_) {
    // Offline or not yet synced anywhere — the editor still works locally
    // and will push up whatever gets drawn on this device from here on.
  }
}

class TogetherApp extends StatefulWidget {
  final AppState appState;
  final SessionState sessionState;

  const TogetherApp({super.key, required this.appState, required this.sessionState});

  @override
  State<TogetherApp> createState() => _TogetherAppState();
}

class _TogetherAppState extends State<TogetherApp> {
  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_onStateChanged);
    widget.sessionState.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onStateChanged);
    widget.sessionState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    // The new "soft glam" look is a single light editorial theme — the
    // Settings dark/light/system choice still persists (unchanged logic),
    // it just doesn't have a distinct dark palette to switch to yet.
    return AppScope(
      state: widget.appState,
      child: BackendScope(
        state: widget.sessionState,
        child: MaterialApp(
          title: 'Together',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const AuthGate(),
        ),
      ),
    );
  }
}

/// Shown instead of crashing if the app was launched without Supabase
/// credentials configured (see supabase.env.example.json).
class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.settings_outlined, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Configurazione Supabase mancante',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Copia supabase.env.example.json in supabase.env.json, '
                    'inserisci URL e anon key del tuo progetto Supabase, poi avvia '
                    'con:\nflutter run --dart-define-from-file=supabase.env.json',
                    textAlign: TextAlign.center,
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
