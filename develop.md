# niantic sdkの各種メモ

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

### Playback
- Playbackでは下記データは保存し呼出し出来る様子。
  - カメラローカルポジション："pose"にて保管されている。ローカル座標管理。　カメラオブジェクトにてデータ参照可能。
  - カメラローカルロテーション："pose"にて保管されている。ローカル座標管理。　カメラオブジェクトにてデータ参照可能。
  - 現在時刻："timestamp"にて保管されている。　UNIX時間。取得方法は無さそう。
  - 緯度経度座標記録時刻："positionTimestamp"にて保管されている。Input.location.lastData.timestampで取得可能。凡そ1sec/1logで時刻確認は概ね可能。UNIX時間。日本時間は+9h。

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

            Debug.Log($"GPS is enabled: Latitude = {latitude}, Longitude = {longitude}, Timestamp = {gpsTimeJST} (JST)");
        }
    }
}
```