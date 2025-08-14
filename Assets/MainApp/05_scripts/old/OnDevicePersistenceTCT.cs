// based on: Assets\Samples\OnDevicePersistence\Scripts\OnDevicePersistence.cs

using System.Collections;
using UnityEngine;
using UnityEngine.UI;
using System.IO;

/// <summary>
/// OnDevicePersistenceTCT
/// このクラスは、アプリのUI制御・マップ作成/保存/ロード・オブジェクト配置・状態管理などを統括します。
/// ユーザー操作に応じて各種メニューやARマップ・オブジェクトの状態を切り替えます。
/// </summary>
public class OnDevicePersistenceTCT : MonoBehaviour
{
    [Header("Managers")]
    [SerializeField]
    private MapperTCT _mapper;
    
    [SerializeField]
    private TrackerTCT _tracker;
    
    [Header("UX - Status")]
    [SerializeField]
    private Text _statusText;

    [Header("UX - Create/Load")]
    [SerializeField] 
    private GameObject _createLoadPanel;
    
    [SerializeField]
    private Button _createMapButton;
    
    [SerializeField]
    private Button _loadMapButton;
    
    [Header("UX - Scan Map")]
    [SerializeField] 
    private GameObject _scanMapPanel;
    
    [SerializeField]
    private Button _startScanning;
    
    [SerializeField]
    private Button _exitScanMapButton;

    [Header("UX - Scanning Animation")] 
    [SerializeField]
    private GameObject _scanningAnimationPanel;
    
    [Header("UX - In Game")]
    [SerializeField] 
    private GameObject _inGamePanel;
    
    [SerializeField]
    private Button _placeCubeButton;
    
    [SerializeField]
    private Button _deleteCubesButton;
    
    [SerializeField]
    private Button _exitInGameButton;

    //files to save to
    public static string k_mapFileName = "ADHocMapFile";
    public static string k_objectsFileName = "ADHocObjectsFile";
    
    /// <summary>
    /// Start()
    /// アプリ起動時にメインメニューをセットアップする
    /// </summary>
    void Start()
    {
        SetUp_CreateMenu();
    }
    
    /// <summary>
    /// Exit()
    /// メインメニューに戻る処理。全てのメニューを非表示にし、状態をリセットする
    /// </summary>
    private void Exit()
    {
        _statusText.text = "";
        
        //make sure all menu are destroyed
        Teardown_InGameMenu();
        Teardown_LocalizeMenu();
        Teardown_ScanningMenu();
        Teardown_CreateMenu();
        
        //tracking if running needs to be stopped on exit.
        StartCoroutine(ClearTrackingAndMappingState());


        //go back to the main menu
        SetUp_CreateMenu();
        
    }
    
    /// <summary>
    /// ClearTrackingAndMappingState()
    /// マッピングやトラッキングの状態をクリアするコルーチン
    /// </summary>
    private IEnumerator ClearTrackingAndMappingState()
    {
        // Both ARPersistentAnchorManager and 
        // need to be diabled before calling ClearDeviceMap()

        _mapper.ClearAllState();
        yield return null;

        _tracker.ClearAllState();
        yield return null;
    }
    
    /// <summary>
    /// CheckForSavedMap(string MapFileName)
    /// 指定したファイル名の保存済みマップが存在するか確認する
    /// </summary>
    private bool CheckForSavedMap(string MapFileName)
    {
        var path = Path.Combine(Application.persistentDataPath, MapFileName);
        if (System.IO.File.Exists(path))
        {
            return true;
        }
        return false;
    }
    
    /// <summary>
    /// SetUp_CreateMenu()
    /// メインメニュー（マップ作成/読み込み）をセットアップする
    /// </summary>
    private void SetUp_CreateMenu()
    {
        //hide other menus
        Teardown_InGameMenu();
        Teardown_ScanningMenu();
        Teardown_LocalizeMenu();
        
        _createLoadPanel.SetActive(true);
        
        _createMapButton.onClick.AddListener(SetUp_ScanMenu);
        _loadMapButton.onClick.AddListener(SetUp_LocalizeMenu);
        
        _createMapButton.interactable=true;

        //if there is a saved map enable the load button.
        if(CheckForSavedMap(k_mapFileName))
        {
            _loadMapButton.interactable=true;
        }
        else
        {
            _loadMapButton.interactable=false;
        }
    }
    
    /// <summary>
    /// Teardown_CreateMenu()
    /// メインメニューのUIを非表示にし、リスナーを解除する
    /// </summary>
    private void Teardown_CreateMenu()
    {
        _createLoadPanel.gameObject.SetActive(false);   
        _createMapButton.onClick.RemoveAllListeners();
        _loadMapButton.onClick.RemoveAllListeners();
    }
    
    /// <summary>
    /// SetUp_ScanMenu()
    /// マップスキャン用のメニューをセットアップする
    /// </summary>
    private void SetUp_ScanMenu()
    {
        Teardown_CreateMenu();
        _scanMapPanel.SetActive(true);
        _startScanning.onClick.AddListener(StartScanning);
        _exitScanMapButton.onClick.AddListener(Exit);
        
        _startScanning.interactable=true;
        _exitScanMapButton.interactable=true;
    }
    
    /// <summary>
    /// Teardown_ScanningMenu()
    /// マップスキャン用のUIを非表示にし、リスナーを解除する
    /// </summary>
    private void Teardown_ScanningMenu()
    {
        _startScanning.onClick.RemoveAllListeners();
        _exitScanMapButton.onClick.RemoveAllListeners();
        _scanMapPanel.gameObject.SetActive(false);
        _mapper._onMappingComplete -= MappingComplete;
        _mapper.StopMapping();
    }
    
    /// <summary>
    /// StartScanning()
    /// スキャン開始処理。マッピングを開始し、アニメーションを表示する
    /// </summary>
    private void StartScanning()
    {
        _startScanning.interactable = false;
        _statusText.text = "Look Around to create map";
        _mapper._onMappingComplete += MappingComplete;
        float time = 5.0f;
        _mapper.RunMappingFor(time);
        
        _scanningAnimationPanel.SetActive(true);
    }
    
    /// <summary>
    /// MappingComplete(bool success)
    /// マッピング完了時の処理。成功時はローカライズへ、失敗時は再試行を促す
    /// </summary>
    private void MappingComplete(bool success)
    {
        if (success)
        {
            //clear out any cubes
            DeleteCubes();
            _scanningAnimationPanel.SetActive(false);
            
            //jump to localizing.
            SetUp_LocalizeMenu();
        }
        else
        {
            //failed to make a map try again.
            _startScanning.interactable = true;
            _statusText.text = "Map Creation Failed Try Again";
        }
        _mapper._onMappingComplete -= MappingComplete;
    }

    /// <summary>
    /// SetUp_LocalizeMenu()
    /// マップへのローカライズ用メニューをセットアップする
    /// </summary>
    private void SetUp_LocalizeMenu()
    {
        Teardown_CreateMenu();
        Teardown_ScanningMenu();
        //go to tracking and localise to the map.
        _statusText.text = "Move Phone around to localize to map";
        _tracker._tracking += Localized;
        _tracker.StartTracking();
        
        _scanningAnimationPanel.SetActive(true);
    }
    
    /// <summary>
    /// Teardown_LocalizeMenu()
    /// ローカライズ用UIを非表示にし、リスナーを解除する
    /// </summary>
    private void Teardown_LocalizeMenu()
    {
        _tracker._tracking -= Localized;
        _scanningAnimationPanel.SetActive(false);
    }
    
    /// <summary>
    /// Localized(bool localized)
    /// ローカライズ完了時の処理。成功時はゲームメニューへ、失敗時はメインメニューへ戻る
    /// </summary>
    private void Localized(bool localized)
    {
        //once we are localised we can open the main menu.
        if (localized == true)
        {
            _statusText.text = "";
            _tracker._tracking -= Localized;
            SetUp_InGameMenu();
            LoadCubes();
            _scanningAnimationPanel.SetActive(false);
        }
        else
        {
            //failed exit out.
            Exit();
        }
    }
    /// <summary>
    /// SetUp_InGameMenu()
    /// ゲーム内メニューをセットアップする
    /// </summary>
    private void SetUp_InGameMenu()
    {
        Teardown_LocalizeMenu();
        Teardown_ScanningMenu();
        
        _inGamePanel.SetActive(true);
        _placeCubeButton.onClick.AddListener(PlaceCube);
        _deleteCubesButton.onClick.AddListener(DeleteCubes);
        _exitInGameButton.onClick.AddListener(Exit);
        
        _placeCubeButton.interactable=true;
        _exitInGameButton.interactable=true;
    }
    
    /// <summary>
    /// Teardown_InGameMenu()
    /// ゲーム内メニューのUIを非表示にし、リスナーを解除する
    /// </summary>
    private void Teardown_InGameMenu()
    {
        _placeCubeButton.onClick.RemoveAllListeners();
        _exitInGameButton.onClick.RemoveAllListeners();
        _deleteCubesButton.onClick.RemoveAllListeners();
        _inGamePanel.gameObject.SetActive(false);
    }

    /// <summary>
    /// CreateAndPlaceCube(Vector3 localPos)
    /// 指定位置にキューブを生成し、アンカーの子として配置する
    /// </summary>
    private GameObject CreateAndPlaceCube(Vector3 localPos)
    {
        var go = GameObject.CreatePrimitive(PrimitiveType.Cube);
        
        //add it under the anchor on our map.
        _tracker.AddObjectToAnchor(go);
        go.transform.localPosition = localPos;
        //make it smaller.
        go.transform.localScale = new Vector3(0.2f,0.2f,0.2f);
        return go;
    }

    /// <summary>
    /// PlaceCube()
    /// カメラ前方2mにキューブを配置し、その位置をファイルに保存する
    /// </summary>
    private void PlaceCube()
    {
        //place a cube 2m in front of the camera.
        var pos = Camera.main.transform.position + (Camera.main.transform.forward*2.0f);
        var go = CreateAndPlaceCube(_tracker.GetAnchorRelativePosition(pos));
        var fileName = OnDevicePersistenceTCT.k_objectsFileName;
        var path = Path.Combine(Application.persistentDataPath, fileName);
      
        using (StreamWriter sw = File.AppendText(path))
        {
            Debug.Log($"Saving Cube Position: {go.transform.localPosition} at {path}");
            sw.WriteLine(go.transform.localPosition);
        }
    }

    /// <summary>
    /// LoadCubes()
    /// 保存ファイルからキューブの位置を読み込み、再配置する
    /// </summary>
    private void LoadCubes()
    {
        var fileName = OnDevicePersistenceTCT.k_objectsFileName;
        var path = Path.Combine(Application.persistentDataPath, fileName);
        if (File.Exists(path))
        {
            using (StreamReader sr = new StreamReader(path))
            {
                while (sr.Peek() >= 0)
                {
                    var pos = sr.ReadLine();
                    var split1 = pos.Split("(");
                    var split2 = split1[1].Split(")");
                    var parts = split2[0].Split(",");
                    Vector3 localPos = new Vector3(
                        System.Convert.ToSingle(parts[0]),
                        System.Convert.ToSingle(parts[1]),
                        System.Convert.ToSingle(parts[2])
                    );

                    CreateAndPlaceCube(localPos);
                }
            }
        }
    }
    
    /// <summary>
    /// DeleteCubes()
    /// 配置済みキューブを全て削除し、ファイルも削除する
    /// </summary>
    private void DeleteCubes()
    {
        //delete from the file.
        var fileName = OnDevicePersistenceTCT.k_objectsFileName;
        var path = Path.Combine(Application.persistentDataPath, fileName);
        File.Delete(path);
        
        //delete from in game.
        if (_tracker.Anchor)
        {
            for (int i = 0; i < _tracker.Anchor.transform.childCount; i++)
                Destroy(_tracker.Anchor.transform.GetChild(i).gameObject);
        }
    }
}
