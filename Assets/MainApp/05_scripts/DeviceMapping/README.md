# DeviceMapping クラス・データの構成確認

## 開発方針
- Mapper : マッピングの核システム、スクリプト整理して利用
- Tracker : トラッキングの核システム、スクリプト整理して利用
- RoomManager : 同期処理、今回切り捨てる。
- OnDevicePersistence : ローカル保存機能、今回システムを別途構築する。
- CloudPersistence : クラウド保存機能、今回整備Node.jsにて別途構築する。
- DatastoreManager : クラウド連携機能、今回整備Node.jsに合うものを別途構築する。

## 核の確認
データのフローを確認し、必要な範囲と不要な範囲を明確化し再構成する。

## クラス関連性の概要

### Tracker
- ` ARPersistentAnchorManager.TryTrackAnchor(payload, out arPersistentAnchor)`がトラッキングの核部分
    - `ARDeviceMappingManager.SetDeviceMap(deviceMap)`が事前処理として必要な様子
    - `ARPersistentAnchorManager.enabled = false;` `yield return null ` ` = true`が必要な様子
- TrackerはModel的で、ARPAM, ARDMMはService的。
- トラッキング完了後、Tracker自身でAnchor位置の変更制御をしている
- 起動時生成の`Trackables GameObject`は検索にかからないので`Niantic SDK`のdll内実行と思われる
- `_deviceMap`は`Niantic`独自に生成しているマップデータのbyte[]をそのまま扱えばよい

#### 基本処理
- LoadMap()にてマップをロード
- StartTracking()にてトラッキング開始
    - RestartTrackingDataStore()が呼び出されて処理が進む
    - （恐らく）TryTrackAnchor()内部の関数が呼び出され続け、Tracking動作が続く
    - Tracking完了後、Doneとなる（スクリプト追記）
- Update() : 勝手にアンカー位置を調整してくれる
- ClearAllState()にてトラッキング停止・アンカー破棄・イベント購読終了

#### 補助 (ビジュアライズ等)
- GetAnchorRelativePosition() : ワールド座標をアンカー基準座標に変換
- AddObjectToAnchor() : アンカーに子オブジェクトを追加
- OnArPersistentAnchorStateChanged() : トラッキング成功時に利用するイベント

### Mapper
- `ARDeviceMappingManager.StartMapping()`がマッピングの核部分
    - `ARDeviceMappingManager.SetDeviceMap(new ARDeviceMap())`にて初期化している様子
    - `ARDeviceMappingManager.StopMapping()`実行まで動作継続している
    - `ARDeviceMappingManager.ARDeviceMap`にマッピングデータが保存される
- データの直接の確認はなく`ARDeviceMap.HasValidMap()`にてデータの有無確認をしている。
- エクスポ－ト用データは`ARDeviceMap.Serialize()`で取得している。

#### 基本処理
- RunMappingFor()にて時間を指定しマッピングを依頼
    - RunMapping()にて処理を開始
        - StartMapping()でマッピング開始
        - StopMapping()でマッピング終了
        - (サンプルでは _onMappingCompleteイベントを購読しCloudPersistenceからtacking開始に移行)
    - SaveMapOnDevice()にてローカル保存(サンプルのOnDeviceMapFinalized()から分離)
- ClearAllState()にてマッピング停止・イベント購読終了

#### 補助 (ビジュアライズ等)
- GetMap() : マップデータを取得
- OnDeviceMapFinalized() : マッピング終了時に利用する成否確認含むイベント


## 各種フロー (sample > CloudPersistence：要否や構成の確認)

#### A-1. ロード操作時の動作
1. CloudPersistenceTCT._loadMapButton
    - 2を実行
2. CloudPersistenceTCT.SetUp_LocalizeMenu() - インスタンス
    - 3を実行
    - _waitForMap = true : トラッキングのトリガー　→　CloudPersistenceTCT.Update()にて5を実行
3. DatastoreManagerTCT.CreateOrJoinDataStore() - インスタンス
    - RoomManagerTCT.JoinRoomByName()インスタンスを実行　→　同期するルームを指定 →　INetworking.Join()を実行
        - 恐らくリアルタイム通信開始(Socket.IOなのかなど細かなところはdll内で不明)
        - RoomManagementService.GetOrCreateRoomForName()を実行　→　同期開始と思われる
    - RoomManagerTCT.Roomインスタンスの動作を参照
        - DatastoreCallbackインスタンス: Eventに4.DataStoreUpdatedを追加
        - NetworkEventインスタンス: EventにNetworkUpdateを追加 →　接続・切断状態管理
4. DatastoreManagerTCT.DatastoreUpdated()
    - **データストアの更新イベントを受け取りローカルオブジェクトを追加・削除・更新**
        - KeyがMAP:
            - **TrackerTCT.LoadMap()インスタンスを実行**　→　MAPを取得してロードに入る
                - ObjectData._data(byte[])のみを利用　：　必要範囲の確定
                - ロード完了後に_deviceMap != nullとなり5の遷移が始まる
        - KeyがCUBE:
            - TrackerTCT.Anchor.Find()インスタンスを実行　→　取得済みか否かを確認
            - DatastoreManagerTCT.CreateAndPlaceCubeを実行　→　オブジェクトを配置
                - ObjectData._position(Vector3)インスタンス : 位置を参照
                - ObjectData._color(Color)インスタンス : 色を参照
                - **TrackerTCT.AddObjectToAnchor()**インスタンスを実行　→　指定アンカーにオブジェクトをセット
        - TypeがDatastoreOperationType.ServerChangeDeleted:
            - Destroyにより該当する配置データを削除
5. Tracker.StartTracking() - インスタンス
    - スクリプトに_loadFlomFileがあるがCloudでは非利用なため、false
    - TrackerTCT.RestartTrackingDataStore()インスタンスを実行
        - ARDeviceMappingManager.SetDeviceMap()インスタンスにてマップをセット
        - **ARPersistentAnchorManager.TryTrackAnchor()**インスタンスにてトラッキングを実行　→　詳細は秘匿
            - out _anchorにてトラッキング結果を_anchorに代入
            - TrackerTCT.Anchorの値が、if分岐により_tempAnchorから_anchorに変わる
    - TrackerTCT.Update()の分岐変化にてtransformの置き換えと移動が行われる

#### A-2. ロード後操作時の動作
1. CloudPersistenceTCT._placeCubeButton
    - 2を実行
2. DatastoreManagerTCT.PlaceCube() - インスタンス
    - mainCameraの状態を確認して配置位置を規程
    - Guidを規程
    - idにより色を規程
    - ローカルオブジェクトを配置
    - ObjectDataに_positionと_colorを格納
    - **DatastoreManagerTCT.SetData()インスタンスを実行**　→　サーバーに送付していると思われる

#### B-1. 新規作成(スキャン)操作時の動作
1. CloudPersistenceTCT._startScanning
    - 2を実行
2. CloudPersistenceTCT.StartScanning() - インスタンス
    - MapperTCT._onMappingCompleteインスタンスにMappingComplete関数を追加　→　完了トリガー管理
    - **MapperTCT.RunMappingFor()**インスタンスを実行
        - 引数にてマッピング時間管理、指定時間でマッピングを実行
        - ARDeviceMappingManager.DeviceMapFinalizedインスタンスにOnDeviceMapFinalizeを追加　→　完了トリガー管理
3. MapperTCT.OnDeviceMspFinalize() - インスタンス
    - **データがあればローカルに保存を実行**

#### B-2. 新規作成後の連続動作
1. CloudPersistenceTCT.MappingComplete() - インスタンス
    - 2を実行
    - _waitForMap = true : トラッキングのトリガー　→　CloudPersistenceTCT.Update()にて5を実行
2. DatastoreManagerTCT.CreateOrJoinDataStore() - インスタンス
    - ストアを作成する
    - 3を実行
3. CloudPersistenceTCT.SetUp_LocalizeMenu() - インスタンス
    - DatastoreCallbackインスタンス: Eventに4.DataStoreUpdatedを追加
4. DatastoreManagerTCT.DatastoreUpdated() - インスタンス
    - データストアの更新イベントを受け取りローカルオブジェクトを追加・削除・更新
5. Tracker.StartTracking() - インスタンス
    - トラッキングを行い、成功時にAnchorをセットしtransformの親の置き換えが実行される

---

# DeviceMapping 関連クラスの関係性(LLM解析)

## 概要
このフォルダ内の主要スクリプトは、AR空間マッピング・ローカライズ・オブジェクト配置・ネットワーク同期を実現するために連携しています。

## クラス構成と役割

- **CloudPersistenceTCT**
  - UI制御・状態遷移の管理
  - MapperTCT, TrackerTCT, DatastoreManagerTCT などを統括

- **OnDevicePersistenceTCT**
  - ローカル保存型のマップ・オブジェクト管理
  - MapperTCT, TrackerTCT を利用

- **MapperTCT**
  - AR空間のマッピング（マップ作成）
  - マップデータの取得・保存

- **TrackerTCT**
  - マップデータを元にアンカーをローカライズ
  - オブジェクトの配置補助

- **DatastoreManagerTCT**
  - ネットワーク経由でマップ・オブジェクトを共有・同期
  - RoomManagerTCT, MapperTCT, TrackerTCT を利用

- **RoomManagerTCT**
  - ルーム（部屋）の作成・参加・退出・削除
  - DatastoreManagerTCT から呼び出される

---

## データ・クラス間の関係性(LLM解析)

- **CloudPersistenceTCT**  
  ↳ MapperTCT, TrackerTCT, DatastoreManagerTCT を制御  
  ↳ UIイベントに応じて状態遷移

- **DatastoreManagerTCT**  
  ↳ RoomManagerTCT でルーム管理  
  ↳ MapperTCT からマップデータ取得  
  ↳ TrackerTCT でオブジェクト配置  
  ↳ ネットワーク経由でデータ同期

- **MapperTCT**  
  ↳ ARDeviceMappingManager を使いマップ作成  
  ↳ マップデータをファイル保存 or DatastoreManagerTCTへ提供

- **TrackerTCT**  
  ↳ マップデータを元にアンカー生成  
  ↳ オブジェクトの配置・座標変換を補助

- **RoomManagerTCT**  
  ↳ ルームの作成・参加・削除  
  ↳ DatastoreManagerTCT から利用される

- **OnDevicePersistenceTCT**  
  ↳ MapperTCT, TrackerTCT を利用しローカル保存型の動作

---
