import 'package:flutter/material.dart';

/// Lets any screen know when it's become visible again after popping back
/// from something pushed on top of it (see HomeScreen, which uses this to
/// refresh the chat list — read counts, deletions, etc. — instead of only
/// ever refreshing on a cold start). Its own file so screens can import it
/// without reaching into main.dart and risking an import cycle.
final routeObserver = RouteObserver<PageRoute<void>>();
