using System;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.UI;
using TMPro;
using UnityEngine.XR.ARFoundation;
using System.IO;
using System.Collections.Generic;
using UnityEngine.EventSystems;

public class AppUIMaster : MonoBehaviour
{
    public AppConfig appConfig { get; set; } = new AppConfig();

    [SerializeField] private ARSession _arSession;
    [SerializeField] private ARCameraManager _arCameraManager;
    [SerializeField] private ARCameraBackground _arCameraBackground;
    [SerializeField] private FlutterConnectManager _flutterConnectManager;

    [SerializeField] private MapperTCT _mapperTCT;
    [SerializeField] private TrackerTCT _trackerTCT;

    [SerializeField] private ShootEffect _shootEffect;
    [SerializeField] private ScreenCaptureManager _screenCapture;
    [SerializeField] private PhotoGenerator _photoGenerator;

    [SerializeField] private GameObject _modeView;
    [SerializeField] private TMP_Text _modeText;
    [SerializeField] private GameObject _statusView;
    [SerializeField] private TMP_Text _statusText;
    [SerializeField] private GameObject _informationView;
    [SerializeField] private TMP_Text _informationText;
    [SerializeField] private GameObject _radarView;

    [SerializeField] public Button _radarButton;
    [SerializeField] public Button _trackingButton;
    [SerializeField] public Button _arViewButton;
    [SerializeField] public Button _mappingButton;
    [SerializeField] public Button _photoShootButton;
    [SerializeField] public Button _submitButton;

    [SerializeField] private GameObject _photoObject;

    [SerializeField] private List<GraphicRaycaster> _graphicRaycasters = null!;

    private GameObject _generatedPhotoObject;
    private string _generatedPhotoId;

    public void Initialize()
    {
        _radarButton.onClick.AddListener(() => _ = TriggerRadarButtonAction());
        _trackingButton.onClick.AddListener(() => _ = TriggerTrackingButtonAction());
        _arViewButton.onClick.AddListener(() => TriggerARViewButtonAction());

        _mappingButton.onClick.AddListener(() => _ = TriggerMappingButtonAction());
        _photoShootButton.onClick.AddListener(() => _ = TriggerPhotoShootButtonAction());
        _submitButton.onClick.AddListener(() => _ = TriggerSubmitButtonAction());

        // 明示的な初期化(関数だと不整合をおこす可能性を考慮)
        _arCameraBackground.enabled = false;
        _arCameraManager.enabled = false;
        _arSession.enabled = true;
        _modeView.SetActive(false);
        _statusView.SetActive(false);
        _informationView.SetActive(false);
        _radarView.SetActive(false);

        ModeOnOff(true);
        StatusOnOff(true);

        ARViewOnOff(false);
        InformationOnOff(false);
        RadarOnOff(false);

        CameraManager.CameraRayAction += (pressVec, origin, direction) =>
        {
            CameraRaySelect(pressVec, origin, direction);
        };

        appConfig.PhaseChangeAction += async (oldPhase, newPhase) =>
        {
            StatusChange(newPhase);
            ButtonActiveChange(newPhase);
            await ViewActiveChange(newPhase);
        };
        appConfig.ModeChangeAction += (oldMode, newMode) =>
        {
            ModeChange(newMode);
        };
        _mapperTCT._onMappingComplete += (success) =>
        {
            MappingCompleteGot(success);
        };
        _mapperTCT._onDeviceMapUpdated += (deviceMap) =>
        {
            MapUpdateGot(deviceMap);
        };
        _trackerTCT._trackingComplete += (success) =>
        {
            TrackingCompleteGot(success);
        };
        _trackerTCT._mapLoadComplete += (success) =>
        {
            MapLoadCompleteGot(success);
        };
    }

    public void Dispose()
    {
        CameraManager.CameraRayAction -= (pressVec, origin, direction) =>
        {
            CameraRaySelect(pressVec, origin, direction);
        };

        appConfig.PhaseChangeAction -= async (oldPhase, newPhase) =>
        {
            StatusChange(newPhase);
            ButtonActiveChange(newPhase);
            await ViewActiveChange(newPhase);
        };
        _mapperTCT._onMappingComplete -= (success) =>
        {
            MappingCompleteGot(success);
        };
        _trackerTCT._trackingComplete -= (success) =>
        {
            TrackingCompleteGot(success);
        };
        _trackerTCT._mapLoadComplete -= (success) =>
        {
            MapLoadCompleteGot(success);
        };

        //明示的に初期化
        _mapperTCT.ClearAllState();
        _trackerTCT.ClearAllState();
    }

    public void PutDebugObjects()
    {
        if (_photoObject != null)
        {
            // カメラのTransform取得
            var cam = Camera.main;
            if (cam != null)
            {
                Vector3 pos = cam.transform.position + cam.transform.forward * 2.0f;
                Quaternion rot = cam.transform.rotation;
                GameObject obj = Instantiate(_photoObject, pos, rot);
                _trackerTCT.AddObjectToAnchor(obj);
            }
            else
            {
                GameObject obj = Instantiate(_photoObject);
                _trackerTCT.AddObjectToAnchor(obj);
            }
        }
    }

    private void ModeChange(AppMode newMode)
    {
        _modeText.text = $"{newMode.ToString().ToUpper()}";
    }
    private void StatusChange(AppPhase newPhase)
    {
        _statusText.text = $"{newPhase.ToString().ToUpper()}";
    }
    private void InformationChange(string newInformation)
    {
        _informationText.text = $"{newInformation.ToString()}";
    }
    private void ButtonActiveChange(AppPhase newPhase)
    {
        AppMode mode = appConfig.GetAppMode();
        bool madePhoto = appConfig.MadePhoto;
        bool madeMap = appConfig.MadeMap;
        bool submitted = appConfig.Submitted;

        switch (newPhase)
        {
            case AppPhase.Initialization:
                _radarButton.interactable = false;
                _trackingButton.interactable = false;
                _arViewButton.interactable = false;

                _mappingButton.interactable = false;
                _photoShootButton.interactable = false;
                _submitButton.interactable = false;
                break;

            case AppPhase.Standby:
                if (mode == AppMode.Reaction || mode == AppMode.Unspecified) _radarButton.interactable = true;
                else _radarButton.interactable = false;
                _trackingButton.interactable = false;
                _arViewButton.interactable = false;

                if ((mode == AppMode.Proposal || mode == AppMode.Unspecified) && appConfig.IsArView) _mappingButton.interactable = true;
                else _mappingButton.interactable = false;
                _photoShootButton.interactable = false;
                _submitButton.interactable = false;
                break;

            case AppPhase.Radar:
                if (mode == AppMode.Reaction || mode == AppMode.Unspecified) _radarButton.interactable = true;
                else _radarButton.interactable = false;
                _trackingButton.interactable = false;
                _arViewButton.interactable = false;

                _mappingButton.interactable = false;
                _photoShootButton.interactable = false;
                _submitButton.interactable = false;
                break;

            case AppPhase.Mapping:
                _radarButton.interactable = false;
                _trackingButton.interactable = false;
                _arViewButton.interactable = false;

                _mappingButton.interactable = false;
                _photoShootButton.interactable = false;
                _submitButton.interactable = false;
                break;
            /*
            case AppPhase.Mapped:
                _radarButton.interactable = false;
                _trackingButton.interactable = false;
                _arViewButton.interactable = false;
                _mappingButton.interactable = false;
                _photoShootButton.interactable = true;
                _submitButton.interactable = false;
                break;
            case AppPhase.PhotoShot:
                _radarButton.interactable = false;
                _trackingButton.interactable = false;
                _arViewButton.interactable = false;
                _mappingButton.interactable = false;
                _photoShootButton.interactable = false;
                _submitButton.interactable = true;
                break;
                */

            case AppPhase.StandbyTracking:
                if (mode == AppMode.Reaction || mode == AppMode.Unspecified) _radarButton.interactable = false;
                else _radarButton.interactable = false;
                if (appConfig.IsArView) _trackingButton.interactable = true;
                else _trackingButton.interactable = false;

                _arViewButton.interactable = false;
                if ((mode == AppMode.Proposal || mode == AppMode.Unspecified) && appConfig.IsArView) _mappingButton.interactable = false;
                else _mappingButton.interactable = false;
                _photoShootButton.interactable = false;
                _submitButton.interactable = false;
                break;

            case AppPhase.Searching:
                _radarButton.interactable = false;
                _trackingButton.interactable = false;
                _arViewButton.interactable = false;

                _mappingButton.interactable = false;
                _photoShootButton.interactable = false;
                _submitButton.interactable = false;
                break;

            case AppPhase.OnTracking:
                if (mode == AppMode.Reaction || mode == AppMode.Unspecified) _radarButton.interactable = false;
                else _radarButton.interactable = false;
                if (appConfig.IsArView) _trackingButton.interactable = false;
                else _trackingButton.interactable = false;
                _arViewButton.interactable = false;

                if ((mode == AppMode.Proposal || mode == AppMode.Unspecified) && appConfig.IsArView) _mappingButton.interactable = false;
                else _mappingButton.interactable = false;
                if (!madePhoto) _photoShootButton.interactable = true;
                else _photoShootButton.interactable = false;
                if (madePhoto && !submitted) _submitButton.interactable = false;
                else _submitButton.interactable = false;
                break;

            default:
                break;
        }
        SwitchGameObjects();

    }
    private void SwitchGameObjects()
    {
        _radarButton.gameObject.SetActive(_radarButton.interactable);
        _trackingButton.gameObject.SetActive(_trackingButton.interactable);
        _arViewButton.gameObject.SetActive(_arViewButton.interactable);
        _mappingButton.gameObject.SetActive(_mappingButton.interactable);
        _photoShootButton.gameObject.SetActive(_photoShootButton.interactable);
        _submitButton.gameObject.SetActive(_submitButton.interactable);
    }
    private async Task ViewActiveChange(AppPhase newPhase)
    {
        switch (newPhase)
        {
            case AppPhase.Initialization:
                ARViewOnOff(false);
                RadarOnOff(false);
                InformationOnOff(false);
                break;

            case AppPhase.Standby:
                InformationOnOff(true);
                InformationChange("Please select Radar or Mapping.");
                break;

            case AppPhase.Radar:
                ARViewOnOff(false);
                RadarOnOff(true);
                InformationOnOff(false);
                break;

            case AppPhase.Mapping:
                ARViewOnOff(true);
                RadarOnOff(false);
                InformationOnOff(true);
                InformationChange("Please see around for mapping...");
                while (appConfig.GetAppPhase() == AppPhase.Mapping && !appConfig.MadeMap)
                {
                    await Task.Delay(500);
                    if (appConfig.GetAppPhase() != AppPhase.Mapping || appConfig.MadeMap) break;
                    InformationOnOff(false);
                    await Task.Delay(500);
                    if (appConfig.GetAppPhase() != AppPhase.Mapping || appConfig.MadeMap) break;
                    InformationOnOff(true);
                }
                if (appConfig.MadeMap)
                {
                    InformationOnOff(true);
                    InformationChange("Mapping done!");
                }
                else
                {
                    InformationOnOff(true);
                    InformationChange("Mapping failed...");
                }
                break;
            /*
            case AppPhase.Mapped:
                InformationOnOff(true);
                InformationChange("Mapping done!");
                await Task.Delay(500);
                if(appConfig.GetAppPhase() == AppPhase.Mapped)
                    InformationOnOff(false);
                break;
            case AppPhase.PhotoShot:
                InformationOnOff(true);
                InformationChange("Photo shoot done!");
                await Task.Delay(500);
                if(appConfig.GetAppPhase() == AppPhase.PhotoShot)
                    InformationOnOff(false);
                break;
            */

            case AppPhase.StandbyTracking:
                ARViewOnOff(true);
                RadarOnOff(false);
                InformationOnOff(true);
                InformationChange("Please start tracking.");
                break;
            case AppPhase.Searching:
                ARViewOnOff(true);
                RadarOnOff(false);
                InformationOnOff(true);
                InformationChange("Please look around to search for a track...");
                while (appConfig.GetAppPhase() == AppPhase.Searching && !appConfig.GotTracking)
                {
                    await Task.Delay(500);
                    if (appConfig.GetAppPhase() != AppPhase.Searching || appConfig.GotTracking) break;
                    InformationOnOff(false);
                    await Task.Delay(500);
                    if (appConfig.GetAppPhase() != AppPhase.Searching || appConfig.GotTracking) break;
                    InformationOnOff(true);
                }
                if (appConfig.GotTracking)
                {
                    InformationOnOff(true);
                    InformationChange("On Tracking!");
                }
                else
                {
                    InformationOnOff(true);
                    InformationChange("Search failed...");
                }
                InformationOnOff(true);
                break;
            case AppPhase.OnTracking:
                ARViewOnOff(true);
                RadarOnOff(false);
                InformationOnOff(false);
                break;
            default:
                break;
        }
    }
    private void ModeOnOff(bool active)
    {
        bool isActive = _modeView.activeSelf;
        if (!active && isActive)
        {
            _modeView.SetActive(false);
            appConfig.IsModeView = false;
        }
        else if (active && !isActive)
        {
            _modeView.SetActive(true);
            appConfig.IsModeView = true;
        }
    }
    private void StatusOnOff(bool activate)
    {
        bool isActive = _statusView.activeSelf;
        if (!activate && isActive)
        {
            _statusView.SetActive(false);
            appConfig.IsStatusView = false;
        }
        else if (activate && !isActive)
        {
            _statusView.SetActive(true);
            appConfig.IsStatusView = true;
        }
    }
    private void ARViewOnOff(bool activate)
    {
        bool isManagerActive = _arCameraManager.enabled;
        bool isBackgroundActive = _arCameraBackground.enabled;
        bool isActive = isManagerActive && isBackgroundActive;

        if (!activate && isManagerActive)
        {
            _arCameraBackground.enabled = false;
            _arCameraManager.enabled = false;
            appConfig.IsArView = false;
            ButtonActiveChange(appConfig.GetAppPhase());
        }
        else if (activate && !isActive)
        {
            _arCameraBackground.enabled = true;
            _arCameraManager.enabled = true;
            appConfig.IsArView = true;
            ButtonActiveChange(appConfig.GetAppPhase());
        }
    }

    private void RadarOnOff(bool activate)
    {
        bool isActive = _radarView.activeSelf;
        if (!activate && isActive)
        {
            _radarView.SetActive(false);
            appConfig.IsRadarView = false;
        }
        else if (activate && !isActive)
        {
            _radarView.SetActive(true);
            appConfig.IsRadarView = true;
        }
    }

    private void InformationOnOff(bool activate)
    {
        bool isActive = _informationView.activeSelf;
        if (!activate && isActive)
        {
            _informationView.SetActive(false);
            appConfig.IsInformationView = false;
        }
        else if (activate && !isActive)
        {
            _informationView.SetActive(true);
            appConfig.IsInformationView = true;
        }
    }


    // ◆◆◆◆レーダーサーチの本実行関数◆◆◆◆
    private async Task RadarSearch()
    {
        Debug.Log("[AppUIMaster] RadarSearch start.");
        string mapFolder = "maps";
        string logFolder = "logs";
        string imageFolder = "images";
        string folderPath = Application.persistentDataPath;
        string uuid = "";

        string mapFolderPath = Path.Combine(folderPath, mapFolder);
        if (Directory.Exists(mapFolderPath))
        {
            string[] files = Directory.GetFiles(mapFolderPath, "*.dat");
            if (files.Length > 0)
            {
                string latestFile = "";
                DateTime latestTime = DateTime.MinValue;
                foreach (var file in files)
                {
                    DateTime fileTime = File.GetLastWriteTime(file);
                    if (fileTime > latestTime)
                    {
                        latestTime = fileTime;
                        latestFile = file;
                    }
                }
                uuid = Path.GetFileNameWithoutExtension(latestFile);
            }
            else
            {
                Debug.LogWarning("[AppUIMaster] No map files found in the maps directory.");
                appConfig.GotMap = false;
                return;
            }
            Debug.Log($"[AppUIMaster] Set uuid: {uuid} for this thread.");
        }
        else
        {
            Debug.LogWarning("[AppUIMaster] Maps directory does not exist.");
            appConfig.GotMap = false;
            return;
        }

        string mapFileName = $"{uuid}.dat";
        string logFileName = $"{uuid}.json";

        string mapPath = Path.Combine(mapFolderPath, mapFileName);
        await _trackerTCT.LoadMapFromLocal(mapPath);

        string logFolderPath = Path.Combine(folderPath, logFolder);
        string logPath = Path.Combine(logFolderPath, logFileName);
        Thread threadData = await NodeStoreModels.DeserializeThreadJsonFromFile(logPath);

        List<string> imageFileNames = new List<string>();
        string imageFolderPath = Path.Combine(folderPath, imageFolder);
        if (Directory.Exists(imageFolderPath))
        {
            var files = Directory.GetFiles(imageFolderPath, "*.jpg");
            foreach (var file in files)
            {
                if (Path.GetFileName(file).Contains(uuid))
                {
                    imageFileNames.Add(Path.GetFileName(file));
                }
            }
        }
        if (!string.IsNullOrEmpty(threadData.Uuid))
        {
            appConfig.LoadThread(threadData);
            appConfig.GotMap = true;
        }
        else
        {
            appConfig.GotMap = false;
        }
    }
    private void MapLoadCompleteGot(bool success)
    {
        if (success)
        {
            appConfig.GotMap = true;
            Debug.Log("[AppUIMaster] Map load complete.");
        }
        else
        {
            appConfig.GotMap = false;
            Debug.LogWarning("[AppUIMaster] Map load complete but no valid mapping data was created.");
        }
    }

    public async Task TriggerRadarButtonAction()
    {
        // bool radarButtonActive = _radarButton.enabled;
        // if (!radarButtonActive) return;

        bool isActive = _radarView.activeSelf;
        RadarOnOff(!isActive);
        bool willActivate = !isActive;
        if (willActivate) InformationOnOff(false);

        if (appConfig.GetAppPhase() == AppPhase.Standby)
        {
            appConfig.SetAppPhase(AppPhase.Radar);
            await RadarSearch();
        }
        else if (appConfig.GetAppPhase() == AppPhase.Radar)
        {
            appConfig.SetAppPhase(AppPhase.Standby);
        }
    }
    private void TriggerARViewButtonAction()
    {
        bool arViewButtonActive = _arViewButton.enabled;
        if (!arViewButtonActive) return;

        bool isManagerActive = _arCameraManager.enabled;
        bool isBackgroundActive = _arCameraBackground.enabled;
        bool isActive = isManagerActive && isBackgroundActive;
        ARViewOnOff(!isActive);
    }





    // ◆◆◆◆トラッキングの本実行関数◆◆◆◆
    private async Task Tracking()
    {
        //■■■■下記は本来GetAppPhaseの方が無難だが、複数からの呼び出しがあるため■■■■
        if (appConfig.GotMap)
        {
            _trackerTCT.StartTracking();
            float timeout = 5.0f;
            float elapsed = 0.0f;
            // 下記フラグ構築が難しいため、疑似的に_deviceMapの状態で判断する
            await Task.Delay(500);
            while (_trackerTCT.GetDeviceMapCondition() == false && appConfig.GetAppPhase() == AppPhase.Searching)
            {
                if (elapsed > timeout) break;
                elapsed += 0.5f;
                await Task.Delay(500);
            }
            if (_trackerTCT.GetDeviceMapCondition() == true)
            {
                appConfig.MadeMap = true;
            }
        }
        else
        {
            Debug.LogWarning("[AppUIMaster] Tracking cancelled because map is not loaded.");
            await Task.Yield();
            appConfig.SetAppPhase(AppPhase.Standby);
        }
    }
    private async Task TrackingStop()
    {
        _trackerTCT.StopTracking();
        await Task.Yield();
        // トラッキング停止時には上記としているが、動作不安定の場合、下記を試す
        // _mapperTCT.ClearAllState();
        // await Task.Yield();
        // _trackerTCT.ClearAllState();
        // await Task.Yield();
    }
    private void TrackingCompleteGot(bool success)
    {
        if (success)
        {
            if (appConfig.GetAppPhase() == AppPhase.Searching)
            {
                appConfig.GotTracking = true;
            }
            Debug.Log("[AppUIMaster] On tracking and track data saved.");
        }
        else
        {
            appConfig.GotTracking = false;
            Debug.LogWarning("[AppUIMaster] Search Track finished but no valid tracking data was created.");
        }
    }

    // ◆◆◆◆マッピングの本実行関数◆◆◆◆
    private async Task Mapping()
    {
        _mapperTCT.RunMappingFor(5.0f);
        await Task.Yield();
        // 動作完了後下記のMappingCompleteGotがいくつか経由して呼ばれる
    }
    private async Task MappingStop()
    {
        // マッピング停止時には下記順序でtracker側の停止もしないと不安定になる
        // 停止しない場合、trackingしつづける状態でマッピングを行う
        // 内部動作としてARDeviceMappingManagerを両者とも使っており、システムで現在の構成は共有している
        // もしかしたら上記まで踏み込めば、複数のtrackingも可能になるのかもしれない
        _mapperTCT.ClearAllState();
        await Task.Yield();
        _trackerTCT.ClearAllState();
        await Task.Yield();
    }

    private void MappingCompleteGot(bool success)
    {
        if (success)
        {
            if (appConfig.GetAppPhase() == AppPhase.Mapping)
            {
                appConfig.MadeMap = true;
                appConfig.GotMap = true;
            }
            Debug.Log("[AppUIMaster] Mapping complete and map saved.");
        }
        else
        {
            appConfig.MadeMap = false;
            appConfig.GotMap = false;
            Debug.LogWarning("[AppUIMaster] Mapping cancelled, no valid map was created.");
        }
    }
    private void MapUpdateGot(byte[] serializedMap)
    {
        if (serializedMap != null)
        {
            // ◆◆AppConfigにデータを代入◆◆
            appConfig.SetMap(serializedMap);
            _trackerTCT.LoadMap(serializedMap);
        }
        else
        {
            Debug.LogWarning("[WARNING] [AppUIMaster] Map update received but no valid map is loaded.");
        }
    }


    public async Task TriggerTrackingButtonAction()
    {
        bool trackingButtonActive = _trackingButton.enabled;
        if (!trackingButtonActive) return;

        AppPhase phase = appConfig.GetAppPhase();
        if (phase != AppPhase.Searching)
        {
            appConfig.SetAppPhase(AppPhase.Searching);
            await Tracking();
            Debug.Log("[AppUIMaster] Tracking task run.");
        }
        else
        {
            if (appConfig.GotMap) appConfig.SetAppPhase(AppPhase.StandbyTracking);
            else appConfig.SetAppPhase(AppPhase.Standby);
            await TrackingStop();
            Debug.Log("[AppUIMaster] Tracking task stopped.");
        }
    }
    public async Task TriggerMappingButtonAction()
    {
        bool mappingButtonActive = _mappingButton.enabled;
        if (!mappingButtonActive) return;

        Debug.Log("[AppUIMaster] Mapping button pressed.");
        AppPhase phase = appConfig.GetAppPhase();
        if (phase != AppPhase.Mapping)
        {
            appConfig.SetAppPhase(AppPhase.Mapping);
            await TrackingStop();
            await Mapping();
            Debug.Log("[AppUIMaster] Mapping task run.");
        }
        else
        {
            appConfig.SetAppPhase(AppPhase.Standby);
            await MappingStop();
            Debug.Log("[AppUIMaster] Mapping task stopped.");
        }
    }


    // ◆◆◆◆撮影の本実行関数◆◆◆◆

    // デバッグ用にパブリック化、実装はprivateにする
    public async Task<string> PhotoShoot()
    {
        Texture2D screenshot = _screenCapture.TakeScreenshot();
        //Texture2D screenshot = await _screenCapture.LoadScreenShotAtLocal("sample001.jpg");

        Transform cameraTransform = Camera.main.transform;
        Vector3 photoMoveVec = cameraTransform.forward * _photoGenerator.DistanceFactor;
        Vector3 photoAnchorPosition = cameraTransform.position + photoMoveVec;
        Vector3 photoAnchorEuler = cameraTransform.eulerAngles;
        (photoAnchorPosition, photoAnchorEuler) = _trackerTCT.GetAnchorRelativeTransformVectors(photoAnchorPosition, photoAnchorEuler);
        Vector3 photoAnchorSize = _photoGenerator.GetPhotoObjectSize(screenshot);

        ARLogUnit arLog = new ARLogUnit(photoAnchorPosition, photoAnchorEuler, photoAnchorSize);
        string uuidWithIndex = appConfig.AddARLog(arLog);
        string filePath = await _screenCapture.SaveScreenShotAtLocal(screenshot, uuidWithIndex);

        _ = _shootEffect.PlayShootEffect();

        //空間にオブジェクトを生成
        bool isWorldPosition = false;
        _generatedPhotoObject = _photoGenerator.GeneratePhotoObject(arLog, screenshot, isWorldPosition);
        _generatedPhotoId = uuidWithIndex;

        return filePath;
    }

    public async Task TriggerPhotoShootButtonAction()
    {
        bool photoShootButtonActive = _photoShootButton.enabled;
        if (!photoShootButtonActive) return;

        AppPhase phase = appConfig.GetAppPhase();
        AppMode mode = appConfig.GetAppMode();
        // AppPhase phase = appConfig.GetAppPhase();
        if (mode == AppMode.Proposal)
        {
            string filePath = await PhotoShoot();
            appConfig.MadePhoto = true;
            // ボタンの状態を変更のために同フェーズで実行
            ButtonActiveChange(phase);
            // Flutterへ撮影完了通知
            _flutterConnectManager.SendPhotoShoot(filePath);
            Debug.Log("[AppUIMaster] MADE PHOTO!!");
        }
        else if (mode == AppMode.Reaction)
        {
            string filePath = await PhotoShoot();
            appConfig.MadePhoto = true;
            // ボタンの状態を変更のために同フェーズで実行
            ButtonActiveChange(phase);
            // Flutterへ撮影完了通知　■■■　恐らく今回の趣旨では下記動作は実行しない。　■■■
            _flutterConnectManager.SendPhotoShoot(filePath);
            Debug.Log("[AppUIMaster] ADD PHOTO!!");
        }
        else
        {

        }
    }

    // ◆◆◆◆投稿の本実行関数◆◆◆◆
    private async Task Submit()
    {
        await Task.Yield();
    }

    private async Task TriggerSubmitButtonAction()
    {
        // bool submitButtonActive = _submitButton.enabled;
        // if (!submitButtonActive) return;

        AppPhase phase = appConfig.GetAppPhase();
        AppMode mode = appConfig.GetAppMode();
        if (mode == AppMode.Proposal)
        {
            await Submit();
            appConfig.Submitted = true;
            ButtonActiveChange(phase);
            // ■■■■ ここでデータを保存している／サーバーへの保存も検討 ■■■■
            await NodeStoreModels.SaveThread(appConfig.GetThread());
            Debug.Log("[AppUIMaster] PROPOSAL DONE!!");
        }
        else if (mode == AppMode.Reaction)
        {
            await Submit();
            appConfig.Submitted = true;
            ButtonActiveChange(phase);
            Debug.Log("[AppUIMaster] REACTION DONE!!");
        }
        else
        {

        }
    }

    // ◆◆◆◆再投稿の関数◆◆◆◆
    public async Task Recapture(string reWritePath)
    {
        Debug.Log("[AppUIMaster] Recapture start.");
        await _screenCapture.ClearScreenshotAtLocal(reWritePath);
        if (_generatedPhotoObject != null)
        {
            Destroy(_generatedPhotoObject);
            _generatedPhotoObject = null;
        }
        appConfig.RemoveARLog(_generatedPhotoId);
        appConfig.MadePhoto = false;
        AppPhase phase = appConfig.GetAppPhase();
        ButtonActiveChange(phase);
    }

    // ◆◆◆◆生成完了の関数◆◆◆◆
    public async Task Generated(string path, string reWritePath)
    {
        Debug.Log("[AppUIMaster] Generated start.");
        byte[] imageBytes;
        bool isPathExisting = File.Exists(path);
        bool isRePathExisting = File.Exists(reWritePath);

        if (isPathExisting && isRePathExisting)
        {
            try
            {
                imageBytes = await File.ReadAllBytesAsync(path);
                await File.WriteAllBytesAsync(reWritePath, imageBytes);
                await TriggerSubmitButtonAction();
            }
            catch (Exception ex)
            {
                Debug.LogError($"[FlutterDebugUI] ViewPhoto: Failed to read image file at {path}. Exception: {ex.Message}");
                return;
            }
            Texture2D texture = new Texture2D(2, 2);
            if (!texture.LoadImage(imageBytes))
            {
                Debug.LogError("[FlutterDebugUI] ViewPhoto: Failed to load image data into texture");
                return;
            }
            _photoGenerator.UpdateTexture(texture);
        }
        else if (isRePathExisting)
        {
            Debug.LogWarning($"[FlutterDebugUI] ViewPhoto: pathData is null or empty Path:{path}");
            try
            {
                await TriggerSubmitButtonAction();
            }
            catch (Exception ex)
            {
                Debug.LogError($"[FlutterDebugUI] ViewPhoto: Failed to write image file at {reWritePath}. Exception: {ex.Message}");
            }
        }
    }


    // ◆◆◆◆Rayの関数◆◆◆◆

    //■■■■　乱雑なので混乱を招く可能性あり　■■■■
    private VoteController _voteController = null;
    // ボタンセレクト以外の挙動 ： 3Dオブジェクトセレクト時
    private void CameraRaySelect(Vector2 pressVec, Vector3 origin, Vector3 direction)
    {
        //Log.Write($"Press vector: {pressVec}, Camera Ray Origin: {origin}, Direction: {direction}");
        // Log.Write($"[AppMaster] CameraRaySelect called with pressVec: {pressVec}, origin: {origin}, direction: {direction}");

        var eventData = new PointerEventData(EventSystem.current) { position = pressVec };
        bool isUIHit = false;
        bool is3DHit = false;
        foreach (var raycaster in _graphicRaycasters)
        {
            var results = new List<RaycastResult>();
            raycaster.Raycast(eventData, results);
            if (results.Count > 0) { isUIHit = true; break; }
            // Log.Write($"[AppMaster] Raycaster checked, results count: {results.Count}");
        }
        if (isUIHit)
        {
            // Log.Write($"[AppMaster] UI Hit");
            return;
        }
        // Log.Write($"[AppMaster] No UI Hit");

        // 3Dオブジェクトセレクト分岐処理
        Ray ray = new Ray(origin, direction);
        RaycastHit hit;
        if (Physics.Raycast(ray, out hit))
        {
            is3DHit = true;
        }
        if (!is3DHit)
        {
            // 3Dオブジェクト非セレクト時の処理
            return;
        }

        // 3Dオブジェクトがヒットした場合の処理
        if (is3DHit)
        {
            // Debug.Log($"3D Object Hit: {hit.collider.name}");
            var hitTransform = hit.collider.transform;
            if (hitTransform == null) return;
            string nodeName = hitTransform.name;
            // Debug.Log($"3D Object Hit: {nodeName}");

            // ある場合にUI表示を実行する
            if (nodeName == "Photo")
            {
                _flutterConnectManager.SendPhotoSelect();
                var parent = hitTransform.parent;
                if (parent != null)
                {
                    _voteController = parent.GetComponent<VoteController>();
                    if (_voteController == null)
                    {
                        Debug.LogWarning("[AppUIMaster] VoteController not found on parent.");
                    }
                }
                else
                {
                    Debug.LogWarning("[AppUIMaster] Hit object has no parent for VoteController.");
                }
                // Debug.Log("[AppUIMaster] Photo object selected.");
            }
            else
            {
                // Debug.Log("[AppUIMaster] Other object selected.");
            }
        }
    }

    public async Task VoteParticles(int voteRate)
    {
        if (_voteController != null) {
            float[] rateSet = new float[] { 0.2f, 0.2f, 0.2f, 0.2f, 0.2f };
            switch (voteRate)
            {
                case 0:
                    rateSet[0] = 1.0f;
                    break;
                case 1:
                    rateSet[1] = 1.0f;
                    break;
                case 2:
                    rateSet[2] = 1.0f;
                    break;
                case 3:
                    rateSet[3] = 1.0f;
                    break;
                case 4:
                    rateSet[4] = 1.0f;
                    break;
                case -1:
                    rateSet = new float[] { 0.2f, 0.2f, 0.2f, 0.2f, 0.2f };
                    break;
                default:
                    break;
            }
            _voteController.SetParticlesRate(rateSet);
            _voteController.PlayParticles();
            await Task.Yield();
        }
    }


}
