// based on: Assets\Samples\OnDevicePersistence\Scripts\Tracker.cs

using System;
using System.Collections;
using System.IO;
using System.Threading.Tasks;
using Niantic.Lightship.AR.Mapping;
using Niantic.Lightship.AR.PersistentAnchors;
using UnityEngine;
using UnityEngine.XR.ARSubsystems;

/// <summary>
/// このクラスは、端末上に保存されたマップデータ（アンカー情報）を読み込み、AR空間上でアンカーをローカライズ（位置合わせ）する役割を持ちます。
/// アンカーを基準にオブジェクトの配置や座標変換を行う補助機能も提供します。
/// </summary>
public class TrackerTCT : MonoBehaviour
{
    [SerializeField]
    private ARPersistentAnchorManager _persistentAnchorManager;

    [SerializeField]
    private ARDeviceMappingManager _deviceMappingManager;
    private ARPersistentAnchor _anchor;


    // ファイルからマップデータを読み込むかどうか
    public bool _loadFromFile = true;

    // トラッキング成功時に通知されるイベント：これを参照することで、トラッキング成功を検知できる
    public event Action<bool> _onTracking;

    public event Action<bool> _trackingComplete;
    private bool _isTracking = false;

    // マップデータ
    private ARDeviceMap _deviceMap;

    // ◆◆マップデータ読込に対応したevent◆◆
    public event Action<bool> _mapLoadComplete;

    // ローカライズ前にオブジェクトを一時的に保持するアンカー
    GameObject _tempAnchor;

    /// <summary>
    /// Anchor: ローカライズ済みならアンカー、未完了なら一時アンカーを返します。
    /// </summary>
    public Transform Anchor
    {
        get
        {
            //if we are localised return the anchor
            if (_anchor) return _anchor.transform;
            //if we are not yet localised return a temp root.
            else if (!_tempAnchor) { _tempAnchor = new GameObject("TemporaryAnchor"); }
            return _tempAnchor.transform;
        }
    }

    private void Update()
    {
        if (_anchor && _anchor.trackingState == TrackingState.Tracking) _isTracking = true;
        else _isTracking = false;

        // Update(): ローカライズが完了した場合、一時アンカーに紐付いていたオブジェクトを本アンカーに移動します。
        //cleans up any items that were added before we localised by reparenting them to the proper anchor
        if (_tempAnchor && _anchor && _anchor.trackingState == TrackingState.Tracking)
            for (int i = 0; i < _tempAnchor.transform.childCount; i++)
                _tempAnchor.transform.GetChild(i).SetParent(_anchor.transform, false);
    }

    private void Start()
    {
        // Start(): ARPersistentAnchorManagerの各種設定を行い、サブシステムを再起動します。
        _persistentAnchorManager.DeviceMappingLocalizationEnabled = true;
        _persistentAnchorManager.CloudLocalizationEnabled = false;
        _persistentAnchorManager.ContinuousLocalizationEnabled = true;
        _persistentAnchorManager.TemporalFusionEnabled = true;
        _persistentAnchorManager.TransformUpdateSmoothingEnabled = true;
        _persistentAnchorManager.DeviceMappingLocalizationRequestIntervalSeconds = 0.1f;
        StartCoroutine(_persistentAnchorManager.RestartSubsystemAsyncCoroutine());
    }

    /// <summary>
    /// OnArPersistentAnchorStateChanged(ARPersistentAnchorStateChangedEventArgs args): アンカーのトラッキング状態が「Tracking」になった時、トラッキング成功の通知を行います。
    /// ◆◆トラッキング成功時に利用できるイベント（恐らくelse if増やせばトラッキング状態管理可能）◆◆
    /// </summary>
    private void OnArPersistentAnchorStateChanged(ARPersistentAnchorStateChangedEventArgs args)
    {
        // アセットでの下記アクションへの紐づきはメニュー表示程度で動作に大きな影響なし。
        if (args.arPersistentAnchor.trackingState == TrackingState.Tracking) _onTracking?.Invoke(true);
    }

    /// <summary>
    /// StartTracking(): トラッキング開始。必要ならファイルからマップデータを読み込み、トラッキング用コルーチンを開始します。
    /// ◆◆◆実行動作の核のRestartTrackingDataStore()を呼び出すFunction◆◆◆
    /// 下記のStartCoroutineを
    /// </summary>
    public void StartTracking()
    {
        _persistentAnchorManager.arPersistentAnchorStateChanged += OnArPersistentAnchorStateChanged;
        // ■■■■　下記動作に待ちを入れたので、必要に応じてクリアをしたほうが良い。　■■■■
        StartCoroutine(RestartTrackingDataStore());
    }

    /// <summary>
    /// StopAndDestroyAnchor(): トラッキング停止とアンカーの破棄。イベント購読も解除します。
    /// ◆◆主にシーン遷移時等に活用している。各種リセット時に活用する方針か◆◆
    /// 　→　基本はClearAllState()の補助関数で良さそう。
    /// </summary>
    public void StopAndDestroyAnchor()
    {
        _persistentAnchorManager.enabled = false;
        if (_anchor) _persistentAnchorManager.DestroyAnchor(_anchor);
        _deviceMap = null;
        _persistentAnchorManager.arPersistentAnchorStateChanged -= OnArPersistentAnchorStateChanged;
    }

    // トラッキング停止動作だが、自前で用意の為意図しない挙動がある可能性あり。
    public void StopTracking()
    {
        _persistentAnchorManager.enabled = false;
        _persistentAnchorManager.arPersistentAnchorStateChanged -= OnArPersistentAnchorStateChanged;
    }

    /// <summary>
    /// ClearAllState(): 全状態のクリア。アンカー破棄とマップデータのクリアを行います。
    /// ◆◆主にシーン遷移時等に活用している。各種リセット時に活用する方針か◆◆
    /// 　→　基本は、動作を抜ける際に実行する。
    /// </summary>
    public void ClearAllState()
    {
        StopAndDestroyAnchor();
        _deviceMappingManager.DeviceMapAccessController.ClearDeviceMap();
    }

    /// <summary>
    /// LoadMap(byte[] serializedDeviceMap): 渡されたバイト配列からマップデータを復元します。
    /// ◆◆引数に入れるバイト配列は.datの一式で良さそう◆◆
    /// </summary>
    public void LoadMap(byte[] serializedDeviceMap)
    {
        _deviceMap = ARDeviceMap.CreateFromSerializedData(serializedDeviceMap);
        if (_deviceMap != null)
        {
            Debug.Log("== Map loaded. ==");
            _mapLoadComplete?.Invoke(true);
        }
        else
        {
            Debug.LogError("== Map load failed. ==");
            _mapLoadComplete?.Invoke(false);
        }
    }

    public async Task LoadMapFromLocal(string filePath)
    {
        Debug.Log($"== Loading map from local: {filePath} ==");
        var serializedDeviceMap = await File.ReadAllBytesAsync(filePath);
        _deviceMap = ARDeviceMap.CreateFromSerializedData(serializedDeviceMap);
        if (_deviceMap != null)
        {
            Debug.Log("== Map loaded from local. ==");
            Debug.Log($"== Map data: {_deviceMap != null} ==");
            _mapLoadComplete?.Invoke(true);
        }
        else
        {
            Debug.LogError("== Map load from local failed. ==");
            _mapLoadComplete?.Invoke(false);
        }
    }

    /// <summary>
    /// RestartTrackingDataStore(): マップデータがセットされるまで待機し、トラッキングを再起動します。新しいアンカーでトラッキングを開始します。
    /// ◆◆◆実行動作の核となっているFunction、ただし付随がある為別のpublic関数で実行◆◆◆
    /// </summary>
    private IEnumerator RestartTrackingDataStore()
    {
        float timeout;
        float elapsed;

        Debug.Log("== Restart tracking data store. ==");
        timeout = 5.0f;
        elapsed = 0.0f;
        //this needs to be set!
        while (_deviceMap == null)
        {
            Debug.Log("== Waiting for device map set... ==");
            if (elapsed > timeout) yield break;
            elapsed += 1.0f;
            yield return new WaitForSeconds(1);
        }

        _persistentAnchorManager.enabled = false;

        // start tracking after stop tracking needs "some" time in between...
        yield return null;
        yield return new WaitForSeconds(0.5f);

        _persistentAnchorManager.enabled = true;

        Debug.Log("== Setting device map. ==");
        // Set the device map to mapping manager
        // ◆◆ここがMapperから呼び出せるmapperTCT.GetMap().HasValidMap()にも連動していると思われる
        _deviceMappingManager.SetDeviceMap(_deviceMap);

        Debug.Log("== Start tracking.... ==");
        // Set up a new tracking with a new anchor
        // ◆◆恐らく下記のTrayTrackAnchorの内部で継続的に_anchorの位置補正をかけ続けている。
        _persistentAnchorManager.TryTrackAnchor(
            new ARPersistentAnchorPayload(_deviceMap.GetAnchorPayload()),
            out _anchor);
        // ◆◆下記以降はトラッキング完了まで待つ処理を追加しており、タイムアウトも入れてみている◆◆
        timeout = 5.0f;
        elapsed = 0.0f;
        while (!_anchor || _anchor.trackingState != TrackingState.Tracking)
        {
            if (elapsed > timeout) yield break;
            elapsed += 0.1f;
            yield return new WaitForSeconds(0.1f);
        }
        if (!_anchor && _anchor.trackingState != TrackingState.Tracking)
        {
            // ◆◆下記は自前で追加◆◆
            StopTracking();
            _trackingComplete?.Invoke(false);
            Debug.LogError("== Tracking failed. ==");
            yield break;
        }

        yield return new WaitForSeconds(0.1f); // 少し待つ
        if (_isTracking == true) _trackingComplete?.Invoke(true);

        if (_deviceMap != null)
        {
            Debug.Log("== Map loaded from tracking. ==");
            _mapLoadComplete?.Invoke(true);
        }
        else
        {
            Debug.LogError("== Map load from tracking failed. ==");
            _mapLoadComplete?.Invoke(false);
        }
        Debug.Log("== Tracking Done. ==");
    }

    /// <summary>
    /// GetAnchorRelativePosition(Vector3 pos): ワールド座標をアンカー基準の座標に変換します。
    /// ◆補助関数◆
    /// </summary>
    public Vector3 GetAnchorRelativePosition(Vector3 pos)
    {
        return _anchor.transform.InverseTransformPoint(pos);
    }

    /// <summary>
    /// AddObjectToAnchor(GameObject go): 指定したGameObjectをアンカーの子オブジェクトとして追加します。
    /// ◆補助関数◆
    /// </summary>
    public void AddObjectToAnchor(GameObject go, bool world = true)
    {
        go.transform.SetParent(Anchor.transform, world);
        //SetParent(parent) → ワールド座標を維持
        //SetParent(parent, false) → ローカル座標を維持（親に対して固定配置） 
    }


    public Transform GetAnchorRelativeTransform(Transform target)
    {
        // 一時GameObjectを生成し、アンカー基準のTransform情報をセット
        GameObject temp = new GameObject("AnchorRelativeTransformTemp");
        temp.transform.position = _anchor.transform.InverseTransformPoint(target.position);
        temp.transform.rotation = Quaternion.Inverse(_anchor.transform.rotation) * target.rotation;
        temp.transform.localScale = target.localScale; // スケールはそのまま

        Transform result = temp.transform;
        // 必要なら一時オブジェクトを削除する（呼び出し側で管理推奨）
        // GameObject.Destroy(temp);

        return result;
    }

    /// <summary>
    /// アンカー基準でposition, rotation(euler), scaleを返す
    /// </summary>
    public (Vector3 relativePosition, Vector3 relativeEulerAngles) GetAnchorRelativeTransformVectors(
        Vector3 position, Vector3 eulerAngles)
    {
        Vector3 relativePosition = _anchor.transform.InverseTransformPoint(position);

        Quaternion worldRot = Quaternion.Euler(eulerAngles);
        Quaternion anchorRotInv = Quaternion.Inverse(_anchor.transform.rotation);
        Quaternion relativeRot = anchorRotInv * worldRot;
        Vector3 relativeEulerAngles = relativeRot.eulerAngles;

        return (relativePosition, relativeEulerAngles);
    }

    public TrackingState GetTrackingState()
    {
        return _anchor ? _anchor.trackingState : TrackingState.None;
    }
    public bool GetDeviceMapCondition()
    {
        return _deviceMap != null;
    }

}
