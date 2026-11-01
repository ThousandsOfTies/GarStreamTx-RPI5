# GarStreamTx Raspberry Pi 5 target

`package.sh`は既存GAR hookから共通compositionへの薄い接続です。
アプリ・設定・配布先は`product.json`、基板/OS資源は独立した基板submoduleが所有します。
起動scriptとPython payloadはgar-toolsが生成し、OSの準備とサービスの導入・起動管理は
従来のGAR Target Packが担当します。Product artifactへroot管理のserviceを入れません。

詳細は[構成説明](../../docs/COMPOSITION.md)を参照してください。
