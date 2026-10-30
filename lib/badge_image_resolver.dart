import 'package:flutter/material.dart' show Color;

/// 単元ID(BNCCのeixo接頭辞)を、国際汎用のストランドID(バッジ画像ファイル名用)
/// にマッピングする。バッジ画像自体は他国・他教科展開でも流用しやすいよう
/// 汎用名で用意しているため、BNCC固有のID解決はアプリ側(BR)の責務とする。
String? strandIdForUnit(String unitId) {
  if (unitId.startsWith('mat_numeros_')) return 'numbers';
  if (unitId.startsWith('mat_algebra_')) return 'algebra';
  if (unitId.startsWith('mat_geometria_')) return 'geometry';
  if (unitId.startsWith('mat_grandezas_')) return 'measurement';
  if (unitId.startsWith('mat_probabilidade_')) return 'statistics';
  return null;
}

String masteryBadgeAsset(String strandId) =>
    'assets/badges/badge_mastery_$strandId.png';

String testPassBadgeAsset(String strandId) =>
    'assets/badges/badge_test_pass_$strandId.png';

/// ストランドごとに単元バッジをグルーピングする際の見出し色。
/// バッジ画像生成時に決めた差し色と対応させ、見出しとバッジを一目で
/// 紐付けられるようにする。
Color strandAccentColor(String strandId) => switch (strandId) {
      'numbers' => const Color(0xFFE08A3C),
      'algebra' => const Color(0xFF8B5FBF),
      'geometry' => const Color(0xFF2F9E8F),
      'measurement' => const Color(0xFF8A6A4E),
      'statistics' => const Color(0xFF3F51B5),
      _ => const Color(0xFF9E9E9E),
    };
