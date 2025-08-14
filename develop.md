# 開発関係の各種メモ

---

## データ構成定義（たたき台の案）
- サービス実装まで目指すならMySQLやPostgreSQLかと思いますが、スピード重視でストレージに保存で実装してます。
- 投稿内容・位置ログ等の詳細JSONは未定義です。（JSONの構成は本日目途で一旦案をまとめます）
- `{APIベースURL}`には、別途共有するURLを充てれば8/14現在動作します。

### アクセス先
- サーバーAPIベースURL: `{APIベースURL}`
- 参考: [アクセス確認用画像]({APIベースURL}/toranomon/data/images/868f2c8a-918b-48c0-89e2-61ace6398bbc.png)

### ディレクトリ構成
```
data/
  ├─ images/   ... 画像ファイル（{uuid}.jpg / {uuid}.png）
  ├─ maps/     ... マップファイル（{uuid}.dat）
  └─ logs/     ... JSONデータ（{uuid}.json）
```

### ファイル仕様
- 画像: `images/{uuid}.jpg` または `.png`
- マップ: `maps/{uuid}.dat`
- JSON: `logs/{uuid}.json`（uuidは必須、なければサーバー側で発行）

### API仕様

#### createThread
- エンドポイント: `/toranomon/createThread`
- メソッド: `POST`
- 内容: json, image, mapをmultipart/form-dataで同時受信・保存
  - 必須: json（uuidフィールド必須。なければサーバー側で発行）
  - image: jpg/pngのみ許可
  - map: .datまたは拡張子なしのみ許可
- 保存後レスポンス例:
  ```json
  {
    "message": "POST request received and saved",
    "uuid": "{uuid}",
    "newUuid": true // サーバー発行時のみtrue
  }
  ```
- GET `/toranomon/createThread` : 動作確認用（`{ message: 'GET request received' }`返却）

#### readThread
- エンドポイント: `/toranomon/readThread`
- メソッド: `POST`
- 内容: type, uuidを指定してデータ取得
  - type: ['logs', 'images', 'maps', 'all']（複数可）
  - uuid: ['uuid_hogehoge_hogehoge', 'uuid_hogegehogege_hogegehogege', ...] または空指定(id指定なし)
- レスポンス例:
  ```json
  {
    "status": "success",
    "threads": [
      {
        "name": "{uuid}",
        "log": "{APIベースURL}/toranomon/data/logs/{uuid}.json",
        "image": "{APIベースURL}/toranomon/data/images/{uuid}.png",
        "map": "{APIベースURL}/toranomon/data/maps/{uuid}.dat"
      }
    ]
  }
  ```
- GET `/toranomon/readThread` : 動作確認用（`{ message: 'GET request received' }`返却）

### createThreadクライアントPOST例（node-fetch, form-data利用）

```js
// createThread: 新規スレッド作成（json, image, map同時送信）
import fetch from 'node-fetch';
import fs from 'fs';
import FormData from 'form-data';

const url = '{APIベースURL}/toranomon/createThread';
const jsonData = { sample: 'test', value: 123 /*, uuid: '任意指定可' */ };
const imageFilePath = './images/sample.png';
const mapFilePath = './maps/ADHocMapFile';

const formData = new FormData();
formData.append('json', JSON.stringify(jsonData));
formData.append('image', fs.createReadStream(imageFilePath));
formData.append('map', fs.createReadStream(mapFilePath));

fetch(url, {
    method: 'POST',
    body: formData,
    headers: formData.getHeaders()
})
.then(res => res.json())
.then(json => console.log('Response:', json));
```

### readThreadクライアントPOST例（node-fetch, application/json利用）

```js
// readThread: データ取得（type, uuid指定）
import fetch from 'node-fetch';

const url = '{APIベースURL}/toranomon/readThread';
const jsonData = {
    type: ['logs', 'images', 'maps'], // 例: ['all']も可
    uuid: ['uuid_hogehoge_hogehoge', 'uuid_hogegehogege_hogegehogege'] // 空配列で全件
};

fetch(url, {
    method: 'POST',
    body: JSON.stringify(jsonData),
    headers: { 'Content-Type': 'application/json' }
})
.then(res => res.json())
.then(json => console.log('Response:', JSON.stringify(json, null, 2)));
```

- type: ['logs', 'images', 'maps', 'all'] から選択
- uuid: ['uuid_hogehoge_hogehoge', ...] または空指定（全件取得）
- レスポンスは threads 配列

### 備考
- サーバー起動時にディレクトリ自動作成
- uuidはjson内必須（なければサーバー発行し返却）
- 画像はpng/jpgのみ許可、mapは.datまたは拡張子なしのみ許可

---

# niantic sdkの各種メモ

---

## Playback
[Guides](https://lightship.dev/docs/ja/ardk/how-to/unity/setting_up_playback/)

### Playbackデータ
- Playbackでは下記データは保存し呼出し出来る様子。
  - カメラローカルポジション："pose"にて保管されている。ローカル座標管理。　カメラオブジェクトにてデータ参照可能。
  - カメラローカルロテーション："pose"にて保管されている。ローカル座標管理。　カメラオブジェクトにてデータ参照可能。
  - 現在時刻："timestamp"にて保管されている。　UNIX時間。取得方法は無さそう。
  - 緯度経度座標記録時刻："positionTimestamp"にて保管されている。Input.location.lastData.timestampで取得可能(`using Input = Niantic.Lightship.AR.Input`の記載必要)。凡そ1sec/1logで時刻確認は概ね可能。UNIX時間。日本時間は+9h。

### Using Location Services with Playback
Wherever you would use the UnityEngine.Input API normally, instead use Lightship’s implementation by adding using Input = Niantic.Lightship.AR.Input; to the top of your C# file. Lightship’s implementation has the exact same API as Unity’s; and when not running in Playback mode, it is a simple passthrough to Unity’s APIs. When in Playback mode, it’ll supply the location data from the active dataset.

通常 、UnityEngine.Input API を使用する場合は、C# ファイルの先頭に using Input = Niantic.Lightship.AR.Input; を追加して、Lightshipの実装を使用します。 Lightshipの実装は、UnityのAPIとまったく同じであり、プレイバックモードで動作していないときは、UnityのAPIへのシンプルなパススルーです。 プレイバックモードでは、アクティブなデータセットから位置データを指定します。

- PlaybackにてWPSも動作することを確認（Sample > CompassSceneにて）
- 下記は開発者側で動作確認をしたPlayback時のUnity.Input一般情報取得スクリプト(上述usingによりInputを置き換えしている。)

``` C# unity
using System;
using UnityEngine;
using Input = Niantic.Lightship.AR.Input;

public class GPSCheckerFromNiantic : MonoBehaviour
{
    private void Update()
    {
        if (Input.location.status == LocationServiceStatus.Running)
        {
            double latitude = Input.location.lastData.latitude;
            double longitude = Input.location.lastData.longitude;
            double timestamp = Input.location.lastData.timestamp;

            DateTimeOffset gpsTime = DateTimeOffset.FromUnixTimeSeconds((long)timestamp);
            DateTimeOffset gpsTimeJST = gpsTime.ToOffset(TimeSpan.FromHours(9));

            Debug.Log(
                $"GPS is enabled: Latitude = {latitude}, " +
                $"Longitude = {longitude}, Timestamp = {gpsTimeJST} (JST)");
        }
    }
}
```

---

## Occlusion
[Guides](https://lightship.dev/docs/ja/ardk/features/occlusion/)

### Occlusion Stabilization
Occlusion Stabilization has the advantages of both modes. It combines the fast response time of instant occlusion with the stable averaging effect of meshing.
A depth map is produced from the ARMeshManager environment mesh, rendered to a texture, and combined with the AROcclusionManager instant depth features in a way that avoids flicker and Z-fighting.
To use this mode, add a Lightship Occlusion Extension to your scene and enable Occlusion Stabilization.

オクルージョン安定化 は、両方のモードの利点を兼ね備えています。 この手法では、インスタント・オクルージョンの高速な応答時間と、メッシュによる安定した平均化効果が組み合わされています。
ARMeshManager の環境メッシュから生成された深度マップがテクスチャにレンダリングされ、AROcclusionManager のインスタント深度機能と組み合わされることで、ちらつきやZファイティングが回避されます。
このモードを使用するには、 Lightship Occlusion Extension をシーンに追加し、 オクルージョン安定化 を有効にしてください。

### Occlusion Suppression
Occlusion Suppression enables a user to reserve depth values to the far depth plane for specific semantic channels. This is useful for preventing noisy depth outputs from incorrectly occluding your model, such as occlusion flickering when objects are moving around on the ground. Enabling this option reveals three more options:
Semantic Segmentation Manager
To use Occlusion Suppression, attach a Semantic Segmentation Manager here. See How to Setup Real World Occlusion for details.
Suppression Channels
The set of channels in the semantic buffer to use for suppression. Add the name of each channel as a separate name in the list. We recommend adding ground and sky as a useful catch-all for many occlusion issues.

Occlusion Suppression: 特定のセマンティック・チャンネルのために、ユーザーが遠距離深度平面に深度値を予約することができます。 これは、オブジェクトが地面を動き回っているときにオクルージョンがちらつくなど、ノイズの多いデプス出力がモデルを誤ってオクルージョンするのを防ぐのに便利です。 このオプションを有効にすると、さらに3つのオプションが表示されます：
セマンティック セグメンテーション・マネージャー
オクルージョン・サプレッションを使用するには、ここにSemantic Segmentation Managerをアタッチします。 詳しくは How to Setup Real World Occlusion をご覧ください。
Suppression Channels（サプレッションチャンネル）
サプレッションに使用するセマンティック・バッファ内のチャンネルのセット。 各チャンネルの名称を個別の名称としてリストに追加します。 多くのオクルージョンの問題に対する有効な総合的な解決策として、 ground と sky を追加することをお勧めします。


---

# Windows環境での設定

## OSのパスの上限変更

- `OS のパスの上限を越えています。完全修飾のファイル名は 260 文字以下にする必要があります。`への対応

- レジストリで有効化
  - Windows + R → regedit を入力して実行
  - 以下のキーを開く
  - `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem`
  - `LongPathsEnabled (DWORD)`を探す
  - 無ければ右クリック → 新規 → DWORD値 (32bit) で作成
  - 値を 1 に設定
  - PC を再起動
  
## Playback利用時のアラート

- Playback利用時に下記アラートが出る
- `d3d11: Creating a default shader resource view with dxgi-fmt=0 for a texture that uses dxgi-fmt=29`
- Playback時以外は出ないので、無視する