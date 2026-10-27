# shoukore_br_matematica

小学コレ！ブラジル版 算数アプリ。

- 対象: ブラジル（`pt_BR`、BNCC準拠カリキュラム）× 算数（`matematica`）
- 共通コア（教科非依存のロジック）は[`shoukore_core_global`](https://github.com/zka32101/shoukore_core_global)をgit依存として利用する。
- 算数固有の問題生成（`ArithmeticQuestionSource`等）・カリキュラムデータ（`curriculum/pt_BR.json`）はこのリポジトリに閉じる。

## 開発方針

展開方針（1国1教科から開始し、流行ったら2教科目を作る、等）は
[`shoukore_core_global`のADR](https://github.com/zka32101/shoukore_core_global/blob/main/docs/decisions/0001-design-overview.md)を参照。
