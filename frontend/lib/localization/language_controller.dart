import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageStorage {
  static const String _localeKey = 'selected_language_code';

  static const List<String> supportedLanguageCodes = [
    'en',
    'hi',
    'bn',
    'te',
    'mr',
    'ta',
    'gu',
  ];

  static Future<Locale> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey) ?? 'en';
    if (!supportedLanguageCodes.contains(code)) {
      return const Locale('en');
    }
    return Locale(code);
  }

  static Future<void> saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }
}

class LanguageController extends InheritedNotifier<ValueNotifier<Locale>> {
  const LanguageController({
    super.key,
    required ValueNotifier<Locale> notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  static ValueNotifier<Locale> notifierOf(BuildContext context) {
    final controller =
        context.dependOnInheritedWidgetOfExactType<LanguageController>();
    assert(controller != null, 'LanguageController not found in widget tree');
    return controller!.notifier!;
  }
}
