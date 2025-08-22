// based on: Assets\Samples\OnDevicePersistence\Scripts\Mapper.cs

using System;
using System.Collections;
using System.Threading.Tasks;
using System.IO;
using Niantic.Lightship.AR.Mapping;
using Niantic.Lightship.AR.MapStorageAccess;
using UnityEngine;

/// <summary>
/// このクラスは、端末上にローカルマップ（空間情報）を作成し、ファイルに保存する管理を行います。
/// </summary>
public class MapperTCT : MonoBehaviour
{
    [SerializeField]
    private ARDeviceMappingManager _deviceMappingManager;

    // マッピング完了時に通知されるイベント
    public Action<bool> _onMappingComplete;
   
    void Start()
    {
        // Start(): マッピングマネージャの各種設定を行い、モジュールを再起動します。
        _deviceMappingManager.MappingSplitterMaxDistanceMeters = 10.0f;
        _deviceMappingManager.MappingSplitterMaxDurationSeconds = 1000.0f;
        _deviceMappingManager.DeviceMapAccessController.OutputEdgeType = OutputEdgeType.All;
        
        // マネージャの設定を反映
        StartCoroutine(_deviceMappingManager.RestartModuleAsyncCoroutine());
    }

    private Coroutine currentCo;
    private bool _mappingInProgress = false;

    /// <summary>
    /// RunMappingFor(float seconds): 指定秒数だけマッピングを実行します。完了時にイベント通知します。
    /// </summary>
    public void RunMappingFor(float seconds)
    {
        // DeviceMapFinalized: デフォルトではAsset内はMapperのみしか利用していない。
        _deviceMappingManager.DeviceMapFinalized += OnDeviceMapFinalized;
        _deviceMappingManager.DeviceMapFinalized += async (map) => await SaveMapOnDevice(map);
        currentCo = StartCoroutine(RunMapping(seconds));
    }

    /// <summary>
    /// GetMap(): 現在のマップデータ（ARDeviceMap）を取得します。
    /// </summary>
    public ARDeviceMap GetMap()
    {
        return _deviceMappingManager.ARDeviceMap;
    }

    private void OnDestroy()
    {
        // OnDestroy(): マップ確定イベントの購読を解除します。
        _deviceMappingManager.DeviceMapFinalized -= OnDeviceMapFinalized;
        _deviceMappingManager.DeviceMapFinalized -= async (map) => await SaveMapOnDevice(map);
    }
    
    /// <summary>
    /// RunMapping(float seconds): コルーチン。マッピングを開始し、指定秒数後に停止します。
    /// ◆◆指定秒数制御なので、時間に応じて精度依存が出る様子◆◆
    /// </summary>
    private IEnumerator RunMapping(float seconds)
    {
        // Reset the ARDeviceMappingManager
        _deviceMappingManager.enabled = false;
        yield return null;
        _deviceMappingManager.enabled = true;
        yield return null;
        //start mapping
        _mappingInProgress = true;
        _deviceMappingManager.SetDeviceMap(new ARDeviceMap());
        _deviceMappingManager.StartMapping();
        
        //end mapping after a few seconds
        yield return new WaitForSeconds(seconds);
        _deviceMappingManager.StopMapping();
        _mappingInProgress = false;
    }

    /// <summary>
    /// StopMapping(): マッピングを強制停止します。コルーチンも停止し、イベント購読も解除します。
    /// ◆◆主にフェーズ・シーン遷移時等に活用している。各種リセット時に活用する方針か◆◆
    /// 　→　基本はClearAllState()の補助関数で良さそう。
    /// </summary>
    public void StopMapping()
    {
        if (_mappingInProgress)
        {
            StopCoroutine(currentCo);
            _deviceMappingManager.DeviceMapFinalized -= OnDeviceMapFinalized;
            _deviceMappingManager.DeviceMapFinalized -= async (map) => await SaveMapOnDevice(map);
            _deviceMappingManager.StopMapping();
            _mappingInProgress = false;
        }
    }

    /// <summary>
    /// ClearAllState(): 全状態のクリア。マッピング停止とマップデータのクリアを行います。
    /// ◆◆主にシーン遷移時等に活用している。各種リセット時に活用する方針か◆◆
    /// 　→　基本は、動作を抜ける際に実行する。
    /// </summary>
    public void ClearAllState()
    {
        StopMapping();
        _deviceMappingManager.enabled = false;
        _deviceMappingManager.DeviceMapAccessController.ClearDeviceMap();
    }

    /// <summary>
    /// OnDeviceMapFinalized(ARDeviceMap map): マップ作成完了時の処理。マップが有効ならファイルへ保存し、完了通知を行います。
    /// ◆◆通知およびデータ保存用の処理　→　通知と保存は分ける。◆◆
    /// </summary>
    private void OnDeviceMapFinalized(ARDeviceMap map)
    {
        _deviceMappingManager.DeviceMapFinalized -= OnDeviceMapFinalized;
        _deviceMappingManager.DeviceMapFinalized -= async (map) => await SaveMapOnDevice(map);
        
        bool success = false;
        
        //if a map was created save it to a file
        if (map.HasValidMap()) success = true;
        else Debug.LogWarning("No valid map created.");

        Debug.Log("== Mapping Complete. ==");
        _onMappingComplete?.Invoke(success);
    }

    // OnDeviceMapFinalized()から分離・追加
    private async Task SaveMapOnDevice(ARDeviceMap map)
    {
        if (map.HasValidMap())
        {
            var fileName = "map.dat";
            var serializedDeviceMap = map.Serialize();
            var path = Path.Combine(Application.persistentDataPath, fileName);
            await File.WriteAllBytesAsync(path, serializedDeviceMap);
            Debug.Log($"== Map saved to {path} ==");
        }
    }
}
