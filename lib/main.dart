import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dot/app/app.dart';

void main() {
  // WidgetsBinding.ensureInitialized(); // Useful for future initialization
  runApp(const ProviderScope(child: DotApp()));
}
