using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine;

public class AppMaster : MonoBehaviour
{
    private AppConfig appConfig;
    [SerializeField] private AppUIMaster _appUIMaster;
    private void Awake()
    {
        appConfig = new AppConfig();
        _appUIMaster.appConfig = appConfig;
    }
    private void Start()
    {
        Initialize();
        _appUIMaster.Initialize();
        appConfig.SetAppPhase(AppPhase.Initialization);
    }
    private void Initialize()
    {
        appConfig.PhaseChangeAction += async (oldPhase, newPhase)
            => await PhaseControlHandler(oldPhase, newPhase);
    }
    private void Update()
    {

    }

    private async Task PhaseControlHandler(AppPhase oldPhase, AppPhase newPhase)
    {
        float timeOut = 0;
        float maxWaitTime = 0;
        switch (newPhase)
        {
            case AppPhase.Initialization:
                appConfig.MadeMap = false;
                appConfig.MadePhoto = false;
                appConfig.GotMapList = false;
                appConfig.GotNearbyMap = false;
                appConfig.GotTracked = false;

                //イニシャライズ用のディレイ
                await Task.Delay(100);
                appConfig.SetAppPhase(AppPhase.Standby);
                break;

            case AppPhase.Standby:
                break;

            case AppPhase.Mapping:
                appConfig.MadeMap = false;
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
                    return;
                }
                // UI側でマッピング開始処理を入れる
                // ウェイトタイムを入れる(UI側でのMapping起動待ち)
                timeOut = 0;
                maxWaitTime = 3f; // 最大待機時間3秒
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
                    return;
                }
                // マッピング終了後、処理を移行する
                appConfig.SetAppPhase(AppPhase.Mapped);
                break;
            case AppPhase.Mapped:
                appConfig.MadePhoto = false;
                // ウェイトタイムを入れる(UI側でのARView起動待ち)
                timeOut = 0;
                maxWaitTime = 60f; // 最大待機時間60秒
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
                    return;
                }
                // フォト撮影後処理を入れる
                appConfig.SetAppPhase(AppPhase.Tracking);
                // 下記はTrackerからの呼び出しが良さそう。
                await _appUIMaster.Tracking();
                break;

            case AppPhase.Radar:
                break;

            case AppPhase.StandbyTracking:
                break;

            case AppPhase.Tracking:
                appConfig.GotTracked = false;
                // ウェイトタイムを入れる(UI側でのARView起動待ち)
                timeOut = 0;
                maxWaitTime = 5f; // 最大待機時間5秒
                while (timeOut < maxWaitTime)
                {
                    await Task.Delay(10);
                    timeOut += 0.01f;
                    if (appConfig.GetAppPhase() != AppPhase.Tracking) return;
                    if (appConfig.IsArView) break;
                }
                if (!appConfig.IsArView)
                {
                    Debug.LogWarning("ARViewが起動していません。");
                    return;
                }
                // UI側でマッピング開始処理を入れる
                // ウェイトタイムを入れる(UI側でのMapping起動待ち)
                timeOut = 0;
                maxWaitTime = 3f; // 最大待機時間3秒
                while (timeOut < maxWaitTime)
                {
                    await Task.Delay(100);
                    timeOut += 0.1f;
                    if (appConfig.GetAppPhase() != AppPhase.Tracking) return;
                    if (appConfig.GotTracked) break;
                }
                if (!appConfig.GotTracked)
                {
                    Debug.LogWarning("タイムアウトの為、マッピングがキャンセルされました。");
                    return;
                }
                // マッピング終了後、処理を移行する
                appConfig.SetAppPhase(AppPhase.Tracked);
                break;
            case AppPhase.Tracked:
                break;
        }
    }


}


