import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'equipped_items.dart';
import 'locale_preference_store.dart';
import 'weekly_challenge_repository.dart';

/// 端末内(shared_preferences)に保存するストアの実装。アプリを閉じても、
/// オンボーディングの完了・表示言語・所持キャラ・着せ替え・週のチャレンジが残る。
/// コアが drift(SQLite)で持つ進捗・成長・持ち物・同意とは、別の層。

class PrefsOnboardingCompletionStore implements OnboardingCompletionStore {
  PrefsOnboardingCompletionStore(this._prefs);

  static const _key = 'onboarding_completed';
  final SharedPreferences _prefs;

  @override
  Future<bool> isCompleted() async => _prefs.getBool(_key) ?? false;

  @override
  Future<void> markCompleted() async {
    await _prefs.setBool(_key, true);
  }
}

class PrefsLocalePreferenceStore implements LocalePreferenceStore {
  PrefsLocalePreferenceStore(this._prefs);

  static const _key = 'display_locale';
  final SharedPreferences _prefs;

  @override
  Future<Locale?> getLocale() async {
    final tag = _prefs.getString(_key);
    if (tag == null) return null;
    final parts = tag.split('_');
    return parts.length > 1 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
  }

  @override
  Future<void> setLocale(Locale locale) async {
    final country = locale.countryCode;
    await _prefs.setString(
      _key,
      country == null || country.isEmpty
          ? locale.languageCode
          : '${locale.languageCode}_$country',
    );
  }
}

class PrefsCharacterCollectionStore implements CharacterCollectionStore {
  PrefsCharacterCollectionStore(this._prefs);

  static const _key = 'character_collection';
  final SharedPreferences _prefs;

  @override
  Future<CharacterCollectionSnapshot> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return CharacterCollectionSnapshot.initial;
    try {
      final map = (jsonDecode(raw) as Map<String, dynamic>)
          .map((id, level) => MapEntry(id, level as int));
      return CharacterCollectionSnapshot(levelByCharacterId: map);
    } catch (_) {
      return CharacterCollectionSnapshot.initial;
    }
  }

  @override
  Future<void> save(CharacterCollectionSnapshot snapshot) async {
    await _prefs.setString(_key, jsonEncode(snapshot.levelByCharacterId));
  }

  @override
  Future<void> clearAll() async {
    await _prefs.remove(_key);
  }
}

class PrefsEquippedItemsStore implements EquippedItemsStore {
  PrefsEquippedItemsStore(this._prefs);

  static const _key = 'equipped_items';
  final SharedPreferences _prefs;

  @override
  Future<EquippedItems> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return EquippedItems.initial;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return EquippedItems(
        hatItemId: map['hat'] as String?,
        backgroundItemId: map['background'] as String?,
        frameItemId: map['frame'] as String?,
      );
    } catch (_) {
      return EquippedItems.initial;
    }
  }

  @override
  Future<void> save(EquippedItems items) async {
    await _prefs.setString(
      _key,
      jsonEncode({
        'hat': items.hatItemId,
        'background': items.backgroundItemId,
        'frame': items.frameItemId,
      }),
    );
  }
}

class PrefsWeeklyChallengeStore implements WeeklyChallengeStore {
  PrefsWeeklyChallengeStore(this._prefs);

  static const _key = 'weekly_challenge';
  final SharedPreferences _prefs;

  @override
  Future<WeeklyChallengeSnapshot> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return WeeklyChallengeSnapshot.initial;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final start = map['weekStart'] as String?;
      return WeeklyChallengeSnapshot(
        weekStart: start == null ? null : DateTime.parse(start),
        completedCount: map['completedCount'] as int? ?? 0,
      );
    } catch (_) {
      return WeeklyChallengeSnapshot.initial;
    }
  }

  @override
  Future<void> save(WeeklyChallengeSnapshot snapshot) async {
    await _prefs.setString(
      _key,
      jsonEncode({
        'weekStart': snapshot.weekStart?.toIso8601String(),
        'completedCount': snapshot.completedCount,
      }),
    );
  }
}
