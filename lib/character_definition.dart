import 'package:flutter/material.dart';

/// ブラジル算数版のコレクションキャラクター定義。
///
/// 1つのeixo（BNCCの学習軸）に複数キャラがいる場合、[order]順に育成対象が
/// 移る（1体目がLv5まで育つと2体目の育成が始まる、という順送り方式）。
/// 見た目（モチーフ・色・アイコン）・何教科にどのキャラを割り当てるかは
/// このアプリ固有の責務。
class CharacterDefinition {
  const CharacterDefinition({
    required this.id,
    required this.eixoKeyword,
    required this.order,
    required this.name,
    required this.motif,
    required this.icon,
    required this.color,
  });

  /// `CharacterCollectionStore`で使うキャラID。
  final String id;

  /// `Unit.id`に含まれる文字列で、どのeixoに属するキャラかを判定する
  /// （例: `mat_numeros_1` → `numeros`）。
  final String eixoKeyword;

  /// 同じeixo内での育成順（0始まり）。
  final int order;

  final String name;
  final String motif;
  final IconData icon;
  final Color color;
}

/// ブラジル算数版の12体（BNCCのeixoごとに配分、単元数の多いeixoに3体）。
/// `Gogo`/`Ichiko`/`Fukuju`/`Niniko`は日本版キャラを流用したもの
/// （参照元画像: `H:\マイドライブ\images\小学コレ！\JP_日本\算数\
/// 01_キャラクター\算数キャラ`）。
const characterDefinitions = <CharacterDefinition>[
  CharacterDefinition(
    id: 'tucaninho',
    eixoKeyword: 'numeros',
    order: 0,
    name: 'Tucaninho',
    motif: 'Tucano',
    icon: Icons.flutter_dash,
    color: Colors.orange,
  ),
  CharacterDefinition(
    id: 'tamanduinho',
    eixoKeyword: 'numeros',
    order: 1,
    name: 'Tamanduinho',
    motif: 'Tamanduá',
    icon: Icons.pets,
    color: Colors.brown,
  ),
  CharacterDefinition(
    id: 'gogo',
    eixoKeyword: 'numeros',
    order: 2,
    name: 'Gogo',
    motif: 'Coelho azul (日本版「ゴーゴ」流用)',
    icon: Icons.cruelty_free,
    color: Colors.lightBlue,
  ),
  CharacterDefinition(
    id: 'dracotre',
    eixoKeyword: 'algebra',
    order: 0,
    name: 'Dracotrê',
    motif: 'Dragão de três cabeças (日本版「トライ」流用)',
    icon: Icons.whatshot,
    color: Colors.deepPurple,
  ),
  CharacterDefinition(
    id: 'ichiko',
    eixoKeyword: 'algebra',
    order: 1,
    name: 'Ichiko',
    motif: 'Coelho unicórnio (日本版「イチコ」流用)',
    icon: Icons.auto_awesome,
    color: Colors.amber,
  ),
  CharacterDefinition(
    id: 'fukuju',
    eixoKeyword: 'algebra',
    order: 2,
    name: 'Fukuju',
    motif: 'Coruja (日本版「フクジュ」流用)',
    icon: Icons.nightlight_round,
    color: Colors.teal,
  ),
  CharacterDefinition(
    id: 'tatuzinho',
    eixoKeyword: 'geometria',
    order: 0,
    name: 'Tatuzinho',
    motif: 'Tatu-bola',
    icon: Icons.shield,
    color: Colors.teal,
  ),
  CharacterDefinition(
    id: 'jabutizinho',
    eixoKeyword: 'geometria',
    order: 1,
    name: 'Jabutizinho',
    motif: 'Jabuti',
    icon: Icons.shield_outlined,
    color: Colors.green,
  ),
  CharacterDefinition(
    id: 'capivito',
    eixoKeyword: 'grandezas',
    order: 0,
    name: 'Capivito',
    motif: 'Capivara',
    icon: Icons.straighten,
    color: Colors.brown,
  ),
  CharacterDefinition(
    id: 'preguinha',
    eixoKeyword: 'grandezas',
    order: 1,
    name: 'Preguinha',
    motif: 'Bicho-preguiça',
    icon: Icons.schedule,
    color: Colors.grey,
  ),
  CharacterDefinition(
    id: 'araruna',
    eixoKeyword: 'probabilidade',
    order: 0,
    name: 'Araruna',
    motif: 'Arara-azul',
    icon: Icons.bar_chart,
    color: Colors.indigo,
  ),
  CharacterDefinition(
    id: 'niniko',
    eixoKeyword: 'probabilidade',
    order: 1,
    name: 'Niniko',
    motif: 'Dupla de raposas (日本版「ニニコ」流用)',
    icon: Icons.pets,
    color: Colors.pinkAccent,
  ),
];

/// 成長段階（Lv1〜5）の表示名。
const characterLevelLabels = <String>[
  '',
  'Ovo',
  'Filhote',
  'Jovem',
  'Adulto',
  'Lendário',
];
