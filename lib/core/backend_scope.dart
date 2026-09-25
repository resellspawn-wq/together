import 'package:flutter/widgets.dart';

import 'session_state.dart';

/// Same pattern as [AppScope], for [SessionState] (auth/cloud sync).
/// Kept separate from AppScope so the local-only editor/keyboard code
/// never needs to know the backend exists.
class BackendScope extends InheritedNotifier<SessionState> {
  const BackendScope({
    super.key,
    required SessionState state,
    required super.child,
  }) : super(notifier: state);

  static SessionState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<BackendScope>();
    assert(scope != null, 'BackendScope.of() called with no BackendScope in the tree');
    return scope!.notifier!;
  }

  static SessionState readOf(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<BackendScope>();
    assert(scope != null, 'BackendScope.readOf() called with no BackendScope in the tree');
    return scope!.notifier!;
  }
}
