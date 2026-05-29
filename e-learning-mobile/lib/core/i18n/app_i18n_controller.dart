import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppI18nState {
  const AppI18nState({required this.locale, required this.messages});

  final Locale locale;
  final Map<String, String> messages;

  String text(String key, {String fallback = ''}) => messages[key] ?? fallback;

  AppI18nState copyWith({Locale? locale, Map<String, String>? messages}) {
    return AppI18nState(
      locale: locale ?? this.locale,
      messages: messages ?? this.messages,
    );
  }
}

class AppI18nController extends StateNotifier<AppI18nState> {
  AppI18nController()
    : super(const AppI18nState(locale: Locale('vi'), messages: {}));

  Future<void> load() async {
    await setLocale(state.locale);
  }

  Future<void> setLocale(Locale locale) async {
    final path = locale.languageCode == 'en'
        ? 'assets/i18n/en.json'
        : 'assets/i18n/vi.json';
    final raw = await rootBundle.loadString(path);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final messages = json.map((k, v) => MapEntry(k, v.toString()));
    state = state.copyWith(locale: locale, messages: messages);
  }
}

final appI18nControllerProvider =
    StateNotifierProvider<AppI18nController, AppI18nState>(
      (_) => AppI18nController(),
    );

extension I18nRefX on WidgetRef {
  String t(String key, {String fallback = ''}) {
    return read(appI18nControllerProvider).text(key, fallback: fallback);
  }
}
