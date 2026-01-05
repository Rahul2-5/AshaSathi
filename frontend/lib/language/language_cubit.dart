import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LanguageCubit extends Cubit<Locale> {
  LanguageCubit() : super(const Locale('en'));

  Future<void> changeLanguage(String code, String token) async {
    emit(Locale(code));

    await http.put(
      Uri.parse("http://10.0.2.2:8080/api/users/language?lang=$code"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );
  }
}
