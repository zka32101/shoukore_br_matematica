import 'package:shoukore_core_global/shoukore_core_global.dart';

/// 育成ステージ(GrowthStage)の表示名(ポルトガル語)を引く。
/// home_screen.dartの`_stageVisual`と同じ名称に揃える。
String growthStageLabel(GrowthStage stage) {
  switch (stage) {
    case GrowthStage.egg:
      return 'Ovo';
    case GrowthStage.baby:
      return 'Filhote';
    case GrowthStage.child:
      return 'Jovem';
    case GrowthStage.adult:
      return 'Adulto';
  }
}
