import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/app_shell.dart';
export 'app/app_shell.dart' show MyApp;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Use the Outfit font bundled in assets instead of fetching it over the
  // network on first paint (the runtime fetch was blocking text layout and
  // causing dropped frames at startup).
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const ProviderScope(child: MyApp()));
}