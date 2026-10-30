import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

// コアの drift(SQLite)版の代わりに、同じインターフェースを shared_preferences(JSON)で
// 実装する。コアの drift 実装は、自動生成ファイル(progress_database.g.dart)が
// リポジトリに無く、git依存のままではコンパイルできないため。
// 起動時に1回読み込み、書き込みのたびに保存する。

DateTime? _parseDate(String? v) => v == null ? null : DateTime.parse(v);

class PrefsProgressStore implements ProgressStore {
  PrefsProgressStore(this._prefs) : _attempts = _load(_prefs);

  static const _key = 'progress_attempts';

  /// 保存する回答記録の上限(新しい順に残す)。際限なく増えて、起動と保存が重くなるのを防ぐ。
  static const maxStoredAttempts = 3000;
  static const _masteryWindow = 20;

  final SharedPreferences _prefs;
  final List<Attempt> _attempts;

  static List<Attempt> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>).map((e) {
        final m = e as Map<String, dynamic>;
        return Attempt(
          questionId: m['q'] as String,
          unitId: m['u'] as String,
          correct: m['c'] as bool,
          chosenId: m['ch'] as String?,
          answeredAt: DateTime.parse(m['t'] as String),
          elapsedMs: (m['e'] as int?) ?? 0,
          mode: (m['m'] as String?) ?? 'practice',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(
      _key,
      jsonEncode([
        for (final a in _attempts)
          {
            'q': a.questionId,
            'u': a.unitId,
            'c': a.correct,
            'ch': a.chosenId,
            't': a.answeredAt.toIso8601String(),
            'e': a.elapsedMs,
            'm': a.mode,
          },
      ]),
    );
  }

  @override
  Future<void> recordAttempt(Attempt attempt) async {
    _attempts.add(attempt);
    if (_attempts.length > maxStoredAttempts) {
      _attempts.removeRange(0, _attempts.length - maxStoredAttempts);
    }
    await _persist();
  }

  @override
  Future<List<Attempt>> getAttempts(String unitId, {int? limit}) async {
    final filtered = _attempts.where((a) => a.unitId == unitId).toList()
      ..sort((a, b) => b.answeredAt.compareTo(a.answeredAt));
    if (limit != null && filtered.length > limit) {
      return filtered.sublist(0, limit);
    }
    return filtered;
  }

  @override
  Future<Mastery> getMastery(String unitId) async {
    final recent = await getAttempts(unitId, limit: _masteryWindow);
    if (recent.isEmpty) {
      return Mastery(unitId: unitId, score: 0, lastPracticedAt: null);
    }
    final correctCount = recent.where((a) => a.correct).length;
    return Mastery(
      unitId: unitId,
      score: correctCount / recent.length,
      lastPracticedAt: recent.first.answeredAt,
    );
  }

  @override
  Future<List<Mastery>> getAllMastery() async {
    final unitIds = _attempts.map((a) => a.unitId).toSet();
    return Future.wait(unitIds.map(getMastery));
  }

  @override
  Future<void> clearAll() async {
    _attempts.clear();
    await _prefs.remove(_key);
  }
}

class PrefsGrowthStore implements GrowthStore {
  PrefsGrowthStore(this._prefs);

  static const _key = 'growth_snapshot';
  final SharedPreferences _prefs;

  @override
  Future<GrowthSnapshot> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return GrowthSnapshot.initial;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return GrowthSnapshot(
        totalCorrectAnswers: (m['total'] as int?) ?? 0,
        coinBalance: (m['coins'] as int?) ?? 0,
        missionDay: _parseDate(m['missionDay'] as String?),
        missionCompletedCount: (m['missionCount'] as int?) ?? 0,
        missionRewardClaimed: (m['missionClaimed'] as bool?) ?? false,
        currentStreakDays: (m['streak'] as int?) ?? 0,
        lastStudiedDay: _parseDate(m['lastStudied'] as String?),
        bonusCoinsEarnedToday: (m['bonusToday'] as int?) ?? 0,
        bonusCoinsDay: _parseDate(m['bonusDay'] as String?),
      );
    } catch (_) {
      return GrowthSnapshot.initial;
    }
  }

  @override
  Future<void> save(GrowthSnapshot snapshot) async {
    await _prefs.setString(
      _key,
      jsonEncode({
        'total': snapshot.totalCorrectAnswers,
        'coins': snapshot.coinBalance,
        'missionDay': snapshot.missionDay?.toIso8601String(),
        'missionCount': snapshot.missionCompletedCount,
        'missionClaimed': snapshot.missionRewardClaimed,
        'streak': snapshot.currentStreakDays,
        'lastStudied': snapshot.lastStudiedDay?.toIso8601String(),
        'bonusToday': snapshot.bonusCoinsEarnedToday,
        'bonusDay': snapshot.bonusCoinsDay?.toIso8601String(),
      }),
    );
  }

  @override
  Future<void> clearAll() async {
    await _prefs.remove(_key);
  }
}

class PrefsInventoryStore implements InventoryStore {
  PrefsInventoryStore(this._prefs);

  static const _key = 'inventory_owned_items';
  final SharedPreferences _prefs;

  @override
  Future<InventorySnapshot> load() async => InventorySnapshot(
    ownedItemIds: (_prefs.getStringList(_key) ?? const <String>[]).toSet(),
  );

  @override
  Future<void> save(InventorySnapshot snapshot) async {
    await _prefs.setStringList(_key, snapshot.ownedItemIds.toList());
  }

  @override
  Future<void> clearAll() async {
    await _prefs.remove(_key);
  }
}

class PrefsConsentStore implements ConsentStore {
  PrefsConsentStore(this._prefs);

  static const _key = 'parental_consent';
  final SharedPreferences _prefs;

  @override
  Future<ConsentRecord?> getConsent() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return ConsentRecord(
        parentalConsentGiven: m['given'] as bool,
        consentedAt: _parseDate(m['at'] as String?),
        policyVersion: (m['v'] as int?) ?? 1,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setConsent(ConsentRecord record) async {
    await _prefs.setString(
      _key,
      jsonEncode({
        'given': record.parentalConsentGiven,
        'at': record.consentedAt?.toIso8601String(),
        'v': record.policyVersion,
      }),
    );
  }

  @override
  Future<void> revokeConsent() async {
    final current = await getConsent();
    await setConsent(
      ConsentRecord(
        parentalConsentGiven: false,
        consentedAt: current?.consentedAt,
        policyVersion: current?.policyVersion ?? 1,
      ),
    );
  }

  @override
  Future<void> eraseAll() async {
    await _prefs.remove(_key);
  }
}

class PrefsScreenTimeStore implements ScreenTimeStore {
  PrefsScreenTimeStore(this._prefs);

  static const _key = 'screen_time';
  final SharedPreferences _prefs;

  @override
  Future<ScreenTimeSnapshot> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return ScreenTimeSnapshot.initial;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return ScreenTimeSnapshot(
        usedTodayMinutes: (m['used'] as int?) ?? 0,
        day: _parseDate(m['day'] as String?),
      );
    } catch (_) {
      return ScreenTimeSnapshot.initial;
    }
  }

  @override
  Future<void> save(ScreenTimeSnapshot snapshot) async {
    await _prefs.setString(
      _key,
      jsonEncode({
        'used': snapshot.usedTodayMinutes,
        'day': snapshot.day?.toIso8601String(),
      }),
    );
  }

  @override
  Future<void> clearAll() async {
    await _prefs.remove(_key);
  }
}
