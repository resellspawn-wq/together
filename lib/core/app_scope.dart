import 'package:flutter/widgets.dart';

import 'app_state.dart';

/// Minimal hand-rolled `InheritedNotifier` so the rest of the app can read
/// and react to [AppState] without pulling in a state-management package.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope.of() called with no AppScope in the tree');
    return scope!.notifier!;
  }

  /// Reads the state without subscribing to rebuilds — for one-off actions.
  static AppState readOf(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope.readOf() called with no AppScope in the tree');
    return scope!.notifier!;
  }
}
