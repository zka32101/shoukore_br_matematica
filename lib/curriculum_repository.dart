import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'src/question/curriculum_loader.dart';

/// 算数（BNCC/pt_BR）カリキュラムJSONをアプリ同梱アセット経由で読み込む。
/// regional profileは共通コア（`shoukore_core_global`）のアセットを使う。
class CurriculumRepository {
  const CurriculumRepository();

  String localeKey(Locale locale) {
    if (locale.languageCode == 'pt') return 'pt_BR';
    return locale.languageCode;
  }

  Future<CurriculumData> loadCurriculum(Locale locale) async {
    final content = await rootBundle.loadString('curriculum/${localeKey(locale)}.json');
    return parseCurriculum(content);
  }

  Future<RegionalProfile> loadRegionalProfile(Locale locale) async {
    final content = await rootBundle
        .loadString('packages/shoukore_core_global/regional/${localeKey(locale)}.yaml');
    return parseRegionalProfile(content);
  }
}
