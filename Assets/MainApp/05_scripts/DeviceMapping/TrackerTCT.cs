// based on: Assets\Samples\OnDevicePersistence\Scripts\Tracker.cs

using System;
using System.Collections;
using System.IO;
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
    
    // トラッキング成功時に通知されるイベント
    public Action<bool> _tracking;
    
    // マップデータ
    private ARDeviceMap _deviceMap;
    
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
            if(_anchor)
                return _anchor.transform;
            else
            {
                //if we are not yet localised return a temp root.
                if(!_tempAnchor)
                {
                    _tempAnchor = new GameObject("TempAnchor");
                }
            
                return _tempAnchor.transform;
            }
        }
    }
    
    private void Update()
    {
        // Update(): ローカライズが完了した場合、一時アンカーに紐付いていたオブジェクトを本アンカーに移動します。
        //cleans up any items that were added before we localised by reparenting them to the proper anchor
        if (_anchor && _anchor.trackingState == TrackingState.Tracking)
        {
            if (_tempAnchor)
            {
                //move them
                for (int i = 0; i < _tempAnchor.transform.childCount; i++)
                {
                    _tempAnchor.transform.GetChild(i).SetParent(_anchor.transform, false);
                }
            }
        }
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
    /// </summary>
    private void OnArPersistentAnchorStateChanged(ARPersistentAnchorStateChangedEventArgs args)
    {
        if (args.arPersistentAnchor.trackingState == TrackingState.Tracking)
        {
            _tracking?.Invoke(true);
        }
    }
    
    /// <summary>
    /// StartTracking(): トラッキング開始。必要ならファイルからマップデータを読み込み、トラッキング用コルーチンを開始します。
    /// </summary>
    public void StartTracking()
    {
        _persistentAnchorManager.arPersistentAnchorStateChanged += OnArPersistentAnchorStateChanged;

        if (_loadFromFile)
        {
            // Read a new device map from file
            var fileName =  OnDevicePersistenceTCT.k_mapFileName;
            var path = Path.Combine(Application.persistentDataPath, fileName);
            var serializedDeviceMap = File.ReadAllBytes(path);
            _deviceMap = ARDeviceMap.CreateFromSerializedData(serializedDeviceMap);
        }

        StartCoroutine(RestartTrackingDataStore());
    }
    
    /// <summary>
    /// StopAndDestroyAnchor(): トラッキング停止とアンカーの破棄。イベント購読も解除します。
    /// </summary>
    public void StopAndDestroyAnchor()
    {
        _persistentAnchorManager.enabled = false;
        if (_anchor)
        {
            _persistentAnchorManager.DestroyAnchor(_anchor);
        }

        _deviceMap = null;
        _persistentAnchorManager.arPersistentAnchorStateChanged -= OnArPersistentAnchorStateChanged;
    }

    /// <summary>
    /// ClearAllState(): 全状態のクリア。アンカー破棄とマップデータのクリアを行います。
    /// </summary>
    public void ClearAllState()
    {
        StopAndDestroyAnchor();
        _deviceMappingManager.DeviceMapAccessController.ClearDeviceMap();
    }
    
    /// <summary>
    /// LoadMap(byte[] serializedDeviceMap): 渡されたバイト配列からマップデータを復元します。
    /// </summary>
    public void LoadMap(byte [] serializedDeviceMap)
    {
        _deviceMap = ARDeviceMap.CreateFromSerializedData(serializedDeviceMap);
    }

    /// <summary>
    /// RestartTrackingDataStore(): マップデータがセットされるまで待機し、トラッキングを再起動します。新しいアンカーでトラッキングを開始します。
    /// </summary>
    private IEnumerator RestartTrackingDataStore()
    {
        //this needs to be set!
        while (_deviceMap == null)
            yield return new WaitForSeconds(1);

        _persistentAnchorManager.enabled = false;

        // start tracking after stop tracking needs "some" time in between...
        yield return null;

        _persistentAnchorManager.enabled = true;
        
        // Set the device map to mapping manager
        _deviceMappingManager.SetDeviceMap(_deviceMap);

        // Set up a new tracking with a new anchor
        _persistentAnchorManager.TryTrackAnchor(
            new ARPersistentAnchorPayload(_deviceMap.GetAnchorPayload()),
            out _anchor);
    }

    /// <summary>
    /// GetAnchorRelativePosition(Vector3 pos): ワールド座標をアンカー基準の座標に変換します。
    /// </summary>
    public Vector3 GetAnchorRelativePosition(Vector3 pos)
    {
        return _anchor.transform.InverseTransformPoint(pos);
    }

    /// <summary>
    /// AddObjectToAnchor(GameObject go): 指定したGameObjectをアンカーの子オブジェクトとして追加します。
    /// </summary>
    public void AddObjectToAnchor(GameObject go)
    {
        go.transform.SetParent(Anchor.transform);
    }

}
