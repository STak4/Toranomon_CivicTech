# Toranomon_CivicTech
Repository for TNXR Hackathon Unity ver 6000.0.50f1

## 概要
- TNXR Hackathon応募用アプリケーションのプロジェクト

---

## 開発環境

### OS
- Mac OS26beta
- Windows 11

### Unity Version
- Unity 6000.0.50f1

### その他
- .gitignore: Unityデフォルト設定
- GitLFS: 非利用（予定）

---

## プロジェクト設定

### Templates
- [ARDK Samples Unity Project 3.15.0](https://github.com/niantic-lightship/ardk-samples/releases/tag/3.15.0)

### Build Settings
- Android Build
- iOS Build

### Project Settings
- Templatesの設定に依存

### Niantic API
- Niantic spatial platformにて API Keyを取得して設定する

### 画面設定
- 未定。横位置をオススメ。

---

## インストールライブラリ・パッケージ・アセット

### Package Manager
- 今のところなし

### Plugins
- 今のところなし

### TextMeshPro (未実施)
- `Window > TextMeshPro > Import TMP Essential Resources`
    - Importする
---

## Niantic SDK

#### DeviceMapping　：　優先度　高
- [ガイドページ](https://lightship.dev/docs/ja/ardk/features/device_mapping/)
- [API Ref](https://lightship.dev/docs/ja/ardk/apiref/Niantic/Lightship/AR/Mapping/)
- Niantic的に推したいならこれを優先的に活用してみる？
- 一方でデバイス依存がありそうなので、開発方法は慎重にかもですね。
- システム上、記録したものをシェアして呼び出せると広がりを持てそうですが、要技術検証。

#### ObjectDetection　：　優先度　高
- [ガイドページ](https://lightship.dev/docs/ja/ardk/features/object_detection/)
- [API Ref](https://lightship.dev/docs/ja/ardk/apiref/Niantic/Lightship/AR/ObjectDetection/)
- 現実世界のものと、それをコピーする物との関連付けでやりやすそうなのはこちらかもと思いました。
- モックの動き的にも、確認の精度・スピード感はあるので、カジュアルな利用は有力な気がしています。

#### Occlusion　：　優先度　中
- [ガイドページ](https://lightship.dev/docs/ja/ardk/features/occlusion/)
- [API Ref](https://lightship.dev/docs/ja/ardk/apiref/Niantic/Lightship/AR/Occlusion/)
- 入れておきたいですね。
- iOSですと、LiDAR使ったらNiantickのものではなくUnityのデフォルトでもきれいな印象あります。

#### Meshing　：　優先度　中
- [ガイドページ](https://lightship.dev/docs/ja/ardk/features/meshing/)
- [API Ref](https://lightship.dev/docs/ja/ardk/apiref/Niantic/Lightship/AR/Meshing/)
- オブジェクトを取り扱うなら、配置などを考えるのなら必要そうな印象。
- 代替案として、地面は別途固定配置にすれば、プレゼン上は不要だったりします。

#### SharedAR　：　優先度　中
- [ガイドページ](https://lightship.dev/docs/ja/ardk/features/shared_ar/)
- [API Ref](https://lightship.dev/docs/ja/ardk/apiref/Niantic/Lightship/SharedAR/)
- プレゼンテーションとして第三者が体験者の様子を見れると、印象は良い気もします。

#### Lightship VPS　：　優先度　低
- [ガイドページ](https://lightship.dev/docs/ja/ardk/features/lightship_vps/)
- [API Ref](https://lightship.dev/docs/ja/ardk/apiref/Niantic/Lightship/AR/VpsCoverage/)
- DeviceMappingで動かせば、VPSは優先度低い？
- VPSはオブジェクトの登録が煩雑な印象と、今回のコンセプトには合わない印象です。

---

## データ・クレジット

### Developed by
- Toranomon_CivicTech

### UI Fonts
- 利用未定

### lightship terms of services
- [リンク](https://lightship.dev/legal/terms)

---

# Niantic SampleのRead me 情報

# Lightship ARDK Samples
This Unity package provides Sample Scenes with easy-to-understand examples for many of the Lightship ARDK 3 features.

## __Quick links:__
* [ARDK API Reference](https://lightship.dev/docs/ardk/apiref/Niantic/)
* [Documentation](https://lightship.dev/docs/ardk/sample_projects/)
* [Forums](https://community.lightship.dev/)

# Getting Started

Clone this repository or download the source code from the Releases tab and open it as a Unity project.

In the Unity Editor, select the scene that uses the feature you'd like to reference and hit play.
If you find yourself having problems using our samples, please refer to our [documentation page](https://lightship.dev/docs/ardk/sample_projects/) for more information.

To build the samples on a mobile device, follow our [Setup Guide.](https://lightship.dev/docs/ardk/setup/#selecting-your-mobile-platform)

# Recording Datasets for Playback
AR Playback is a new, powerful feature for in-editor testing. The Recording sample will allow you to create your own dataset of an area near you. For more information, see [the Playback documentation](https://lightship.dev/docs/ardk/features/playback/).

You can also try out the feature with a pre-recorded dataset. Two are available as extra assets in our release:

* [Gandhi Statue](https://github.com/niantic-lightship/ardk-samples/releases/download/3.1.0/GandhiStatue_PlaybackDataset.tgz)

* [Relic Statue](https://github.com/niantic-lightship/ardk-samples/releases/download/3.1.0/Relic_PlaybackDataset.tgz)


After downloading a dataset, extract it to a folder of your choice, then open the Unity Editor to configure your Lightship settings:

1. Open Project Settings from the Edit menu, then scroll down to XR Plugin Management and select Niantic Lightship SDK.
2. Enable Editor Playback, then input the absolute path to your dataset in the Dataset Path field.

# Package Dependencies
These packages are included in the sample project:

[ardk-upm](https://github.com/niantic-lightship/ardk-upm)

[sharedar-upm](https://github.com/niantic-lightship/sharedar-upm)

[Vector Graphics](com.unity.vectorgraphics)