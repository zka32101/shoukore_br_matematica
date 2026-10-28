import 'l10n/app_localizations.dart';

/// 単元IDから、画面に出す単元名(ポルトガル語)を引く。未登録のIDはそのまま返す
/// (内部IDを画面に出さないための共通ロジック。home_screen/question_screenで共用)。
String resolveUnitName(AppLocalizations l10n, String unitId) {
  switch (unitId) {
    case 'mat_numeros_1':
      return l10n.unitName_mat_numeros_1;
    case 'mat_numeros_2':
      return l10n.unitName_mat_numeros_2;
    case 'mat_numeros_3':
      return l10n.unitName_mat_numeros_3;
    case 'mat_numeros_4':
      return l10n.unitName_mat_numeros_4;
    case 'mat_numeros_5':
      return l10n.unitName_mat_numeros_5;
    case 'mat_algebra_1':
      return l10n.unitName_mat_algebra_1;
    case 'mat_algebra_2':
      return l10n.unitName_mat_algebra_2;
    case 'mat_algebra_3':
      return l10n.unitName_mat_algebra_3;
    case 'mat_algebra_4':
      return l10n.unitName_mat_algebra_4;
    case 'mat_algebra_5':
      return l10n.unitName_mat_algebra_5;
    case 'mat_geometria_1':
      return l10n.unitName_mat_geometria_1;
    case 'mat_geometria_2':
      return l10n.unitName_mat_geometria_2;
    case 'mat_geometria_3':
      return l10n.unitName_mat_geometria_3;
    case 'mat_geometria_4':
      return l10n.unitName_mat_geometria_4;
    case 'mat_geometria_5':
      return l10n.unitName_mat_geometria_5;
    case 'mat_grandezas_1':
      return l10n.unitName_mat_grandezas_1;
    case 'mat_grandezas_2':
      return l10n.unitName_mat_grandezas_2;
    case 'mat_grandezas_3':
      return l10n.unitName_mat_grandezas_3;
    case 'mat_grandezas_4':
      return l10n.unitName_mat_grandezas_4;
    case 'mat_grandezas_5':
      return l10n.unitName_mat_grandezas_5;
    case 'mat_probabilidade_1':
      return l10n.unitName_mat_probabilidade_1;
    case 'mat_probabilidade_2':
      return l10n.unitName_mat_probabilidade_2;
    case 'mat_probabilidade_3':
      return l10n.unitName_mat_probabilidade_3;
    case 'mat_probabilidade_4':
      return l10n.unitName_mat_probabilidade_4;
    case 'mat_probabilidade_5':
      return l10n.unitName_mat_probabilidade_5;
    default:
      return unitId;
  }
}
