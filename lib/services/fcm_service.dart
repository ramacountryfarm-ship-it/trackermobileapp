import 'package:flutter/material.dart';

// FCM is disabled until google-services.json is added.
// Re-enable by uncommenting firebase_core + firebase_messaging in pubspec.yaml
// and restoring this file from git history.

final navigatorKey = GlobalKey<NavigatorState>();

class FcmService {
  static final FcmService _instance = FcmService._();
  factory FcmService() => _instance;
  FcmService._();

  Future<void> init() async {}
  Future<void> unregisterOnLogout() async {}
}
