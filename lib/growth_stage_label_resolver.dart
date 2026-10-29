import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'l10n/app_localizations.dart';

/// 育成ステージ(GrowthStage)の表示名を引く。
/// character_definition.dartの`characterLevelLabel`(Lv1〜5)と同じ名称に揃える。
String growthStageLabel(AppLocalizations l10n, GrowthStage stage) {
  switch (stage) {
    case GrowthStage.egg:
      return l10n.growthStageEgg;
    case GrowthStage.baby:
      return l10n.growthStageBaby;
    case GrowthStage.child:
      return l10n.growthStageChild;
    case GrowthStage.adult:
      return l10n.growthStageAdult;
  }
}
