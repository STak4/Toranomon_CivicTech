using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine;

public class AppMaster : MonoBehaviour
{
    private AppConfig appConfig;
    [SerializeField] private AppUIMaster _appUIMaster;
    [SerializeField] private FlutterConnectManager _flutterConnectManager;
    [SerializeField] private DebugSystem _debugSystem;
    [SerializeField] private CompassWorldPoseTCT _compassWorldPoseTCT;

    public AppConfig AppConfig { get => appConfig; private set => appConfig = value; }

    private void Awake()
    {
        appConfig = new AppConfig();
        _appUIMaster.appConfig = appConfig;
        _flutterConnectManager.appConfig = appConfig;
    }
    private void Start()
    {
        Initialize();
        _appUIMaster.Initialize();
        _flutterConnectManager.Initialize();

        appConfig.SetAppMode(AppMode.Unspecified);
        appConfig.SetAppPhase(AppPhase.Initialization);

        _flutterConnectManager.SendAwake();
    }
    private void Initialize()
    {
        appConfig.PhaseChangeAction += async (oldPhase, newPhase)
            => await PhaseControlHandler(oldPhase, newPhase);
    }
    float timeDelta = 0;
    float intervalTime = 3f;
    private void Update()
    {
        timeDelta += Time.deltaTime;
        if(timeDelta > intervalTime)
        {
            //if(appConfig.GotTracked) _ = _appUIMaster.PhotoShoot();
            // _ = _appUIMaster.PhotoShoot();
            timeDelta = 0;
        }
    }
    private void OnApplicationQuit()
    {
        Dispose();
        _appUIMaster.Dispose();
        _flutterConnectManager.Dispose();
    }
    private void Dispose()
    {
        appConfig.PhaseChangeAction -= async (oldPhase, newPhase)
            => await PhaseControlHandler(oldPhase, newPhase);
    }

    // ◆◆◆◆　基本仕様は、AppUIMaster等でボタン同時のフェーズ切り替えと各種動作を実行　◆◆◆◆
    // ◆◆◆◆　AppMasterでは状態管理をし、動作完了後のフェーズ移動とタイムアウトを実施する　◆◆◆◆
    private async Task PhaseControlHandler(AppPhase oldPhase, AppPhase newPhase)
    {
        float timeOut = 0;
        float maxWaitTime = 0;
        switch (newPhase)
        {
            case AppPhase.Initialization:
                appConfig.MadeMap = false;
                appConfig.MadePhoto = false;
                appConfig.Submitted = false;
                appConfig.GotMapList = false;
                appConfig.GotMap = false;
                appConfig.GotTracking = false;

                //イニシャライズ用のディレイ
                await Task.Delay(100);
                appConfig.SetAppPhase(AppPhase.Standby);
                break;

            case AppPhase.Standby:
                break;

            case AppPhase.Radar:
                appConfig.SetAppMode(AppMode.Reaction);
                appConfig.ClearThread();
                appConfig.MadeMap = false;
                appConfig.MadePhoto = false;
                appConfig.Submitted = false;

                appConfig.GotMap = false;
                appConfig.GotTracking = false;
                // ウェイトタイムを入れる(UI側でのARView起動待ち)
                timeOut = 0;
                maxWaitTime = 5.0f; // 最大待機時間5秒
                while (timeOut < maxWaitTime)
                {
                    await Task.Delay(100);
                    timeOut += 0.1f;
                    if (appConfig.GetAppPhase() != AppPhase.Radar) return;
                    if (appConfig.GotMap) break;
                }
                if (!appConfig.GotMap)
                {
                    Debug.LogWarning("タイムアウトの為、近くのマップ取得がキャンセルされました。");
                    if (appConfig.GetAppPhase() == AppPhase.Radar)
                        appConfig.SetAppPhase(AppPhase.Standby);
                    await Task.Delay(1000); // UI側の通知表示時間
                    return;
                }
                // マップデータ読込後の処理を入れる
                // appConfig.SetAppPhase(AppPhase.StandbyTracking);
                appConfig.SetAppPhase(AppPhase.Searching);
                break;

            case AppPhase.Mapping:
                appConfig.SetAppMode(AppMode.Proposal);
                appConfig.CreateThread(_compassWorldPoseTCT.GetCurrentLLH());
                appConfig.MadeMap = false;
                appConfig.MadePhoto = false;
                appConfig.Submitted = false;

                appConfig.GotMap = false;
                appConfig.GotTracking = false;
                // ウェイトタイムを入れる(UI側でのARView起動待ち)
                timeOut = 0;
                maxWaitTime = 5f; // 最大待機時間5秒
                while (timeOut < maxWaitTime)
                {
                    await Task.Delay(100);
                    timeOut += 0.1f;
                    if (appConfig.GetAppPhase() != AppPhase.Mapping) return;
                    if (appConfig.IsArView) break;
                }
                if (!appConfig.IsArView)
                {
                    Debug.LogWarning("ARViewが起動していません。");
                    if (appConfig.GetAppPhase() == AppPhase.Mapping)
                        appConfig.SetAppPhase(AppPhase.Standby);
                    await Task.Delay(1000); // UI側の通知表示時間
                    return;
                }
                // UI側でマッピング開始処理を入れる
                // ウェイトタイムを入れる(UI側でのMapping起動待ち)
                timeOut = 0;
                maxWaitTime = 8f; // 最大待機時間8秒
                while (timeOut < maxWaitTime)
                {
                    await Task.Delay(100);
                    timeOut += 0.1f;
                    if (appConfig.GetAppPhase() != AppPhase.Mapping) return;
                    if (appConfig.MadeMap) break;
                }
                if (!appConfig.MadeMap)
                {
                    Debug.LogWarning("タイムアウトの為、マッピングがキャンセルされました。");
                    if (appConfig.GetAppPhase() == AppPhase.Mapping)
                        appConfig.SetAppPhase(AppPhase.Standby);
                    await Task.Delay(1000); // UI側の通知表示時間
                    return;
                }
                await Task.Delay(1000); // UI側の通知表示時間
                // マッピング終了後、処理を移行する
                // appConfig.SetAppPhase(AppPhase.StandbyTracking);
                appConfig.SetAppPhase(AppPhase.Searching);
                break;
            /*
            case AppPhase.Mapped:
                appConfig.MadePhoto = false;
                // ウェイトタイムを入れる(UI側でのARView起動待ち)
                timeOut = 0;
                maxWaitTime = 180f; // 最大待機時間180秒
                while (timeOut < maxWaitTime)
                {
                    await Task.Delay(100);
                    timeOut += 0.1f;
                    if (appConfig.GetAppPhase() != AppPhase.Mapped) return;
                    if (appConfig.MadePhoto) break;
                }
                if (!appConfig.MadePhoto)
                {
                    Debug.LogWarning("タイムアウトの為、フォト撮影がキャンセルされました。");
                    if (appConfig.GetAppPhase() == AppPhase.Mapped)
                        appConfig.SetAppPhase(AppPhase.Standby);
                    return;
                }
                // フォト撮影後処理を入れる
                appConfig.SetAppPhase(AppPhase.PhotoShot);
                break;
            case AppPhase.PhotoShot:
                appConfig.Submitted = false;
                // ウェイトタイムを入れる(UI側でのARView起動待ち)
                timeOut = 0;
                maxWaitTime = 60f; // 最大待機時間60秒
                while (timeOut < maxWaitTime)
                {
                    await Task.Delay(100);
                    timeOut += 0.1f;
                    if (appConfig.GetAppPhase() != AppPhase.PhotoShot) return;
                    if (appConfig.Submitted) break;
                }
                if (!appConfig.Submitted)
                {
                    Debug.LogWarning("タイムアウトの為、投稿がキャンセルされました。");
                    if (appConfig.GetAppPhase() == AppPhase.PhotoShot)
                        appConfig.SetAppPhase(AppPhase.Standby);
                    return;
                }
                // フォト撮影後処理を入れる
                appConfig.SetAppPhase(AppPhase.StandbyTracking);
                break;
            */

            case AppPhase.StandbyTracking:
                break;

            case AppPhase.Searching:
                appConfig.GotTracking = false;
                // ウェイトタイムを入れる(UI側でのARView起動待ち)
                timeOut = 0;
                maxWaitTime = 5f; // 最大待機時間5秒
                while (timeOut < maxWaitTime)
                {
                    await Task.Delay(10);
                    timeOut += 0.01f;
                    if (appConfig.GetAppPhase() != AppPhase.Searching) return;
                    if (appConfig.IsArView) break;
                }
                if (!appConfig.IsArView)
                {
                    Debug.LogWarning("ARViewが起動していません。");
                    await Task.Delay(1000); // UI側の通知表示時間
                    return;
                }
                // UI側でトラッキング開始処理を入れる
                // ウェイトタイムを入れる(UI側でのTracking起動待ち)
                timeOut = 0;
                maxWaitTime = 5.0f; // 最大待機時間3秒
                while (timeOut < maxWaitTime)
                {
                    await Task.Delay(100);
                    timeOut += 0.1f;
                    if (appConfig.GetAppPhase() != AppPhase.Searching) return;
                    if (appConfig.GotTracking) break;
                }
                if (!appConfig.GotTracking)
                {
                    Debug.LogWarning("タイムアウトの為、トラッキングがキャンセルされました。");
                    if (appConfig.GetAppPhase() == AppPhase.Searching)
                    {
                        if (appConfig.GotMap) appConfig.SetAppPhase(AppPhase.StandbyTracking);
                        else appConfig.SetAppPhase(AppPhase.Standby);
                    }
                    await Task.Delay(1000); // UI側の通知表示時間
                    return;
                }
                await Task.Delay(1000); // UI側の通知表示時間
                // トラッキング終了後、処理を移行する
                appConfig.SetAppPhase(AppPhase.OnTracking);
                break;
            case AppPhase.OnTracking:
                break;
            default:
                break;
        }
    }


}


