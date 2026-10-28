import 'package:flutter/material.dart';

/// 小学コレ！シリーズの他教科/他国アプリ1件分の宣伝情報。
/// `storeUrl`はGoogle Playのアプリ詳細ページ(https://play.google.com/store/apps/details?id=...)
/// を想定する。
class CrossPromoApp {
  const CrossPromoApp({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.storeUrl,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String storeUrl;
}

/// クロスプロモで案内する他アプリの一覧。
///
/// `shoukore_br_matematica`はシリーズ最初のアプリのため、現時点では
/// 案内できる他アプリが存在せず空のままにしている。次の教科アプリ
/// (例: ブラジル版ポルトガル語)がストアに公開されたら、ここに
/// `CrossPromoApp`を追加するだけでホーム画面に案内枠が表示される
/// (`CrossPromoSection`は一覧が空の間は「近日公開」の控えめな
/// ティーザーに切り替わり、誰も誘導先の無いリンクを出さない)。
const List<CrossPromoApp> crossPromoApps = [];
