using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.UI;
using TMPro;
using UnityEngine.XR.ARFoundation;
using System.Data.Odbc;

public class AppUIMaster : MonoBehaviour
{
    public AppConfig appConfig { get; set; } = new AppConfig();

    [SerializeField] private ARCameraManager _arCameraManager;
    [SerializeField] private ARCameraBackground _arCameraBackground;

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

    [SerializeField] private Button _radarButton;
    [SerializeField] private Button _trackingButton;
    [SerializeField] private Button _arViewButton;
    [SerializeField] private Button _mappingButton;
    [SerializeField] private Button _photoShootButton;
    [SerializeField] private Button _submitButton;

    [SerializeField] private GameObject _photoObject;

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
        _modeView.SetActive(false);
        _statusView.SetActive(false);
        _informationView.SetActive(false);
        _radarView.SetActive(false);

        ModeOnOff(true);
        StatusOnOff(true);

        ARViewOnOff(false);
        InformationOnOff(false);
        RadarOnOff(false);

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
                if(mode == AppMode.Reaction || mode == AppMode.Unspecified) _radarButton.interactable = true;
                else _radarButton.interactable = false;
                _trackingButton.interactable = false;
                _arViewButton.interactable = true;

                if ((mode == AppMode.Proposal || mode == AppMode.Unspecified) && appConfig.IsArView) _mappingButton.interactable = true;
                else _mappingButton.interactable = false;
                _photoShootButton.interactable = false;
                _submitButton.interactable = false;
                break;

            case AppPhase.Radar:
                if(mode == AppMode.Reaction || mode == AppMode.Unspecified) _radarButton.interactable = true;
                else _radarButton.interactable = false;
                _trackingButton.interactable = false;
                _arViewButton.interactable = true;

                _mappingButton.interactable = false;
                _photoShootButton.interactable = false;
                _submitButton.interactable = false;
                break;

            case AppPhase.Mapping:
                _radarButton.interactable = false;
                _trackingButton.interactable = false;
                _arViewButton.interactable = false;

                _mappingButton.interactable = true;
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
                if(mode == AppMode.Reaction || mode == AppMode.Unspecified) _radarButton.interactable = true;
                else _radarButton.interactable = false;
                if (appConfig.IsArView) _trackingButton.interactable = true;
                else _trackingButton.interactable = false;

                _arViewButton.interactable = true;
                if ((mode == AppMode.Proposal || mode == AppMode.Unspecified) && appConfig.IsArView) _mappingButton.interactable = true;
                else _mappingButton.interactable = false;
                _photoShootButton.interactable = false;
                _submitButton.interactable = false;
                break;

            case AppPhase.Searching:
                _radarButton.interactable = false;
                _trackingButton.interactable = true;
                _arViewButton.interactable = false;

                _mappingButton.interactable = false;
                _photoShootButton.interactable = false;
                _submitButton.interactable = false;
                break;

            case AppPhase.OnTracking:
                if(mode == AppMode.Reaction || mode == AppMode.Unspecified) _radarButton.interactable = true;
                else _radarButton.interactable = false;
                if (appConfig.IsArView) _trackingButton.interactable = true;
                else _trackingButton.interactable = false;
                _arViewButton.interactable = true;

                if ((mode == AppMode.Proposal || mode == AppMode.Unspecified) && appConfig.IsArView) _mappingButton.interactable = true;
                else _mappingButton.interactable = false;
                if (!submitted) _photoShootButton.interactable = true;
                else _photoShootButton.interactable = false;
                if (madePhoto && !submitted) _submitButton.interactable = true;
                else _submitButton.interactable = false;
                break;

            default:
                break;
        }
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
                RadarOnOff(true);
                InformationOnOff(false);
                break;

            case AppPhase.Mapping:
                ARViewOnOff(true);
                RadarOnOff(false);
                InformationOnOff(true);
                InformationChange("Please see around for mapping...");
                while(appConfig.GetAppPhase() == AppPhase.Mapping && !appConfig.MadeMap)
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
                while(appConfig.GetAppPhase() == AppPhase.Searching && !appConfig.GotTracking)
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
        // 一瞬待ちを入れる（ネットロードなら不要、ローカルロードのため）
        await Task.Yield();
        _ = _trackerTCT.LoadMapFromLocal();
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

    private async Task TriggerRadarButtonAction()
    {
        bool isActive = _radarView.activeSelf;
        RadarOnOff(!isActive);
        bool willActivate = !isActive;
        if(willActivate) InformationOnOff(false);

        if (appConfig.GetAppPhase() == AppPhase.Standby && willActivate)
        {
            await RadarSearch();
            appConfig.SetAppPhase(AppPhase.Radar);
        }
        else if (appConfig.GetAppPhase() == AppPhase.Radar && !willActivate)
        {
            appConfig.SetAppPhase(AppPhase.Standby);
        }
    }
    private void TriggerARViewButtonAction()
    {
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
            // _ = Tracking();
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
            appConfig.LatestMapBytes = serializedMap;
            _trackerTCT.LoadMap(serializedMap);
        }
        else
        {
            Debug.LogWarning("[WARNING] [AppUIMaster] Map update received but no valid map is loaded.");
        }
    }


    private async Task TriggerTrackingButtonAction()
    {
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
    private async Task TriggerMappingButtonAction()
    {
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
    public async Task PhotoShoot()
    {
        Texture2D screenshot = _screenCapture.TakeScreenshot();

        Transform cameraTransform = Camera.main.transform;
        Vector3 photoMoveVec = cameraTransform.forward * _photoGenerator.DistanceFactor;
        Vector3 photoAnchorPosition = cameraTransform.position + photoMoveVec;
        Vector3 photoAnchorEuler = cameraTransform.eulerAngles;
        (photoAnchorPosition, photoAnchorEuler) = _trackerTCT.GetAnchorRelativeTransformVectors(photoAnchorPosition, photoAnchorEuler);
        Vector3 photoAnchorSize = _photoGenerator.GetPhotoObjectSize(screenshot);

        //ARLog arLog = new ARLog(cameraTransform);
        ARLogUnit arLog = new ARLogUnit(photoAnchorPosition, photoAnchorEuler, photoAnchorSize);
        _ = _shootEffect.PlayShootEffect();
        await Task.Yield();
        // ◆◆AppConfigにデータを代入◆◆
        appConfig.LatestARLog = arLog;
        appConfig.LatestPhotoBytes = screenshot.EncodeToJPG();

        //空間にオブジェクトを生成
        bool isWorldPosition = false;
        _photoGenerator.GeneratePhotoObject(arLog, screenshot, isWorldPosition);
    }

    private async Task TriggerPhotoShootButtonAction()
    {
        AppPhase phase = appConfig.GetAppPhase();
        AppMode mode = appConfig.GetAppMode();
        // AppPhase phase = appConfig.GetAppPhase();
        if (mode == AppMode.Proposal)
        {
            await PhotoShoot();
            appConfig.MadePhoto = true;
            // ボタンの状態を変更のために同フェーズで実行
            ButtonActiveChange(phase);
            Debug.Log("[AppUIMaster] MADE PHOTO!!");
        }
        else if (mode == AppMode.Reaction)
        {
            await PhotoShoot();
            appConfig.MadePhoto = true;
            // ボタンの状態を変更のために同フェーズで実行
            ButtonActiveChange(phase);
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
        AppPhase phase = appConfig.GetAppPhase();
        AppMode mode = appConfig.GetAppMode();
        if (mode == AppMode.Proposal)
        {
            await Submit();
            appConfig.Submitted = true;
            ButtonActiveChange(phase);
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

}
