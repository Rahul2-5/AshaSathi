import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'language_cubit.dart';

class LanguagePage extends StatelessWidget {
  final String token;
  const LanguagePage({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    final languages = [
      {"name": "English", "code": "en"},
      {"name": "हिंदी", "code": "hi"},
      {"name": "मराठी", "code": "mr"},
      {"name": "தமிழ்", "code": "ta"},
      {"name": "తెలుగు", "code": "te"},
      {"name": "ಕನ್ನಡ", "code": "kn"},
      {"name": "বাংলা", "code": "bn"},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Select Language")),
      body: Column(
        children: languages.map((lang) {
          return RadioListTile(
            title: Text(lang['name']!),
            value: lang['code'],
            groupValue: context.watch<LanguageCubit>().state.languageCode,
            onChanged: (value) {
              context.read<LanguageCubit>().changeLanguage(value!, token);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }
}
