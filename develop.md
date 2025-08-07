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