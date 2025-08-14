# DeviceMapping 関連クラス・データの構成確認

## 概要
データのフローを確認し、必要な範囲と不要な範囲を明確化し再構成する。

#### A-1. ロード操作時の動作
1. CloudPersistenceTCT._loadMapButton
    - 2を実行
2. CloudPersistenceTCT.SetUp_LocalizeMenu() - インスタンス
    - 3を実行
3. DatastoreManagerTCT.CreateOrJoinDataStore() - インスタンス
    - RoomManagerTCT.JoinRoomByName()インスタンスを実行　→　同期するルームを指定 →　INetworking.Join()を実行
        - 恐らくリアルタイム通信開始(Socket.IOなのかなど細かなところはdll内で不明)
        - RoomManagementService.GetOrCreateRoomForName()を実行　→　同期開始と思われる
    - RoomManagerTCT.Roomインスタンスの動作を参照
        - DatastoreCallbackインスタンス: Eventに4.DataStoreUpdatedを追加
        - NetworkEventインスタンス: EventにNetworkUpdateを追加 →　接続・切断状態管理
4. DatastoreManagerTCT.DatastoreUpdated()
    - データストアの更新イベントを受け取りローカルオブジェクトを追加・削除・更新
        - KeyがMAP:
            - TrackerTCT.LoadMap()インスタンスを実行　→　MAPを取得してロードに入る
                - ObjectData._data(byte[])のみを利用　：　必要範囲の確定
        - KeyがCUBE:
            - TrackerTCT.Anchor.Find()インスタンスを実行　→　取得済みか否かを確認
            - DatastoreManagerTCT.CreateAndPlaceCubeを実行　→　オブジェクトを配置
                - ObjectData._position(Vector3)インスタンス : 位置を参照
                - ObjectData._color(Color)インスタンス : 色を参照
                - TrackerTCT.AddObjectToAnchor()インスタンスを実行　→　指定アンカーにオブジェクトをセット
        - TypeがDatastoreOperationType.ServerChangeDeleted:
            - Destroyにより該当する配置データを削除

#### A-2. ロード後操作時の動作
1. CloudPersistenceTCT._placeCubeButton
    - 2を実行
2. DatastoreManagerTCT.PlaceCube() - インスタンス
    - mainCameraの状態を確認して配置位置を規程
    - Guidを規程
    - idにより色を規程
    - ローカルオブジェクトを配置
    - ObjectDataに_positionと_colorを格納
    - DatastoreManagerTCT.SetData()インスタンスを実行　→　サーバーに送付していると思われる

#### B-1. 新規作成(スキャン)操作時の動作
1. CloudPersistenceTCT._startScanning
    - 2を実行
2. CloudPersistenceTCT.StartScanning() - インスタンス
    - MapperTCT._onMappingCompleteインスタンスにMappingComplete関数を追加　→　完了トリガー管理
    - MapperTCT.RunMappingFor()インスタンスを実行
        - 引数にてマッピング時間管理、指定時間でマッピングを実行
        - ARDeviceMappingManager.DeviceMapFinalizedインスタンスにOnDeviceMApFinalizeを追加　→　完了トリガー管理
3. MapperTCT.OnDeviceMApFinalize() - インスタンス
    - データがあればローカルに保存を実行

#### B-2. 新規作成後の連続動作
1. CloudPersistenceTCT.MappingComplete() - インスタンス
    - 2を実行
2. DatastoreManagerTCT.CreateOrJoinDataStore() - インスタンス
    - ストアを作成する
    - 3を実行
3. CloudPersistenceTCT.SetUp_LocalizeMenu() - インスタンス
    - DatastoreCallbackインスタンス: Eventに4.DataStoreUpdatedを追加
4. DatastoreManagerTCT.DatastoreUpdated() - インスタンス
    - データストアの更新イベントを受け取りローカルオブジェクトを追加・削除・更新

---

# DeviceMapping 関連クラス・データの関係性

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

## データ・クラス間の関係性

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

## データの流れ（例）

1. ユーザーがマップ作成 → MapperTCTでマップ生成
2. マップデータを DatastoreManagerTCT 経由でネットワーク共有
3. TrackerTCT でマップデータを元にアンカー生成・ローカライズ
4. オブジェクト配置（キューブ等）は TrackerTCT のアンカー基準で行い、DatastoreManagerTCT で同期

---
