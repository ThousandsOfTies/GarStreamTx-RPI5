# Raspberry Pi 5 Productのコンポジション

このProductは[product.json](../product.json)で、次の3リポジトリをsubmoduleとして固定します。

| 役割 | 配置 | 所有するもの |
| --- | --- | --- |
| アプリ | `sources/gar-stream-tx` | カメラ配信、画面、メニュー、ノブ入力と通信 |
| 共通機構 | `sources/gar-tools` | 構成・配線の検査、Python配布物・起動設定の生成、シミュレータ部品 |
| 基板 | `sources/board-raspberry-pi-5` | OS/ABI、GPIO・SPI・I2C資源、実行環境と起動方式の選択 |

GPIOの用途、液晶とノブの配線、デバウンス、カメラの利用設定、通信上の意味はProductに残します。
基板リポジトリには、接続するカメラの型番・フレームレートやアプリ名を持ち込みません。
GarAdhocAppも同じ基板コミットを利用しますが、実機対応の完成状態はProductごとに管理します。

```text
GarStreamTx-RPI5/
  product.json                     コンポーネント・設定・配布指定
  sources/
    gar-stream-tx/                 共通アプリ
    gar-tools/                     共通機構
    board-raspberry-pi-5/           独立した基板情報
  hardware/
    gpio.csv / spi.csv             実際に渡すGPIO/SPI設定
    simulation-overrides.csv       シミュレータとの差分
    requirements.json              必要な部品と電気的条件
    binding.json                   既存GAR契約への接続
  tools/product.py                 共通compositionへの入口
  scripts/target/package.sh        既存GAR hookへの薄い接続
  panel/studio.js                  Productの操作・メッセージ対応
```

## 確認・ビルド

マージ前に新規取得するときは、変更ブランチを指定します。

```sh
git clone --branch refactor/board-composition --recurse-submodules https://github.com/ThousandsOfTies/GarStreamTx-RPI5.git
cd GarStreamTx-RPI5
python tools/product.py describe
python tools/product.py validate
python tools/product.py environment
python tools/product.py hardware --environment simulation
python tools/product.py build
python tools/product.py package --output artifacts/a-new-release
```

`describe`は選択した基板・OSと、実際のsubmoduleコミット・変更状態を表示します。
`validate`はGPIO/SPIを基板資源と照合します。ビルドはPython構文と選択したソースを検査し、
配布物には同じアプリをコピーします。GI/GStreamerをビルドPCへ読み込む必要はありません。
SDK・ROM・接続先・個人設定は含めません。これらの操作は実機に接続しません。

## 配線と起動パラメーター

GPIOライン、SPI bus/CS/速度、デバウンスはCSVから取得します。
`launch.hardware_environment`はアプリが使う環境変数とCSVの行・列を対応させます。
液晶やノブの設定を起動用のshell scriptに再記述しません。
カメラの利用モードや広告名は`launch.environment`に置きます。
起動時に既存のGAR環境ファイルから渡された値は、従来どおり優先します。

`binding.json`は既存GARの要件検査に使う契約です。CSVがアプリへ渡す値と一致することを
Productの試験で確認します。基板の資源表はこのファイルへ複製しません。
部品一覧と物理配線は`components.csv`・`connections.csv`に残します。

SPI速度のCSVを40MHzから24MHzへ合わせました。これは従来のアプリが実際に指定していた
24MHzを設定の正本に反映する整理であり、アプリの既定速度は変えていません。
アプリはSPI設定を環境変数で受け取れるようにし、従来の既定値も維持します。

シミュレータはCSVのコピーを手で持たず、`.gar/hardware/simulation/`へ生成します。
今回のCSV差分はノブのデバウンス0だけです。生成値はアプリの起動環境に使います。
仮想デバイスの端子配置は従来と同じで、GARの既存ハードウェアCSV経路を維持します。
模擬カメラの入力ポート設定と、アプリ側のキャプチャーモードは別の役割です。

## 導入・起動の境界

物理配布先は従来の`/opt/gar/apps/gar-stream-tx`、サービスは`gar-app@gar-stream-tx`です。
基板プロファイルが`startup.manager=gar-target`を選び、既存GARがサービスアカウント、
導入、起動・停止を管理します。Product配布物にroot管理のserviceを重複して入れません。
`run`はProductが選んだアプリと環境を起動する役割です。

従来の`gar target build`用hookもこの生成処理を呼びます。シミュレータのserviceは
同じ宣言とCSV差分から環境を作り、topologyのEnvironmentFileを後から適用します。
配布先、artifactの構造、TX/RXのtopology所有者は変更しません。

GAR本体のTarget探索とSSH transportの移行は、この整理の対象ではありません。
旧Target Packの情報は互換経路として残ります。この構成での基板データの正本は独立repoです。
今回、実機や稼働中のSim Hostへの再導入・再起動はしていません。
