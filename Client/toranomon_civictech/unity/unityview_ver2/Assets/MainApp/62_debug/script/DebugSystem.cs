using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using Unity.VisualScripting;
using Niantic.Lightship.AR.WorldPositioning;


#if UNITY_ANDROID
using UnityEngine.Android;
#endif

public class DebugSystem : MonoBehaviour
{
    public static DebugSystem Instance { get; private set; }

    //◆◆開始時の設定
    [SerializeField] private bool _activeAtStart;
    private static bool activeAtStart => Instance?._activeAtStart ?? true;

    //◆◆テキスト出力先の設定
    [SerializeField] private Text _debug_text;
    private static Text debug_text => Instance?._debug_text;
    [SerializeField] private Text _debug_Action_text;
    private static Text debug_Action_text => Instance?._debug_Action_text;
    [SerializeField] private Text _debug_Console;
    private static Text debug_Console => Instance?._debug_Console;
    
    //◆◆デバッグコンテンツの設定
    [SerializeField] private GameObject _debugLogs;
    public static GameObject debugLogs => Instance?._debugLogs;
    [SerializeField] private GameObject _debugButtons;
    public static GameObject debugButtons => Instance?._debugButtons;
    [SerializeField] private GameObject _debugObjects;
    public static GameObject debugObjects => Instance?._debugObjects;

    //◆◆カメラの設定
    //[SerializeField] private GameObject _mainCamera;
    [SerializeField] private GameObject _debugCamera;

    //◆◆ログ用テキスト
    private static string logText;
    private static string addLogText;
    private static string lastLogText;
    private static string actionLogText;
    private static List<string> logHistory = new List<string>();

    //◆◆時間管理
    private static float lastTime;
    private static float deltaTime;

    //◆◆fps管理
    private static int fpsAverageCheckCount = 100;
    private static int fpsLongAverageCheckCount = 1000;
    private static float fps;
    private static float fpsLong;
    private static float minFpsCurrent;
    private static float minFpsOnApp = 1000;
    private static bool startMinFpsCheck;
    private static List<float> fpsAverage = new List<float>();
    private static List<float> fpsLongAverage = new List<float>();


    // 各種追加参照
    [SerializeField] private  AppMaster _appMaster;
    private static AppConfig appConfig;
    [SerializeField] private TrackerTCT _trackerTCT;
    private static TrackerTCT trackerTCT => Instance ? Instance._trackerTCT : null;
    [SerializeField] private MapperTCT _mapperTCT;
    private static MapperTCT mapperTCT => Instance ? Instance._mapperTCT : null;
    [SerializeField] private ARWorldPositioningManager _wpsManager;
    private static ARWorldPositioningManager wpsManager => Instance ? Instance._wpsManager : null;
    [SerializeField] private CompassWorldPoseTCT _compassWorldPoseTCT;
    private static CompassWorldPoseTCT compassWorldPoseTCT => Instance ? Instance._compassWorldPoseTCT : null;

    private void Awake()
    {
        if (Instance == null) Instance = this;
        else Destroy(this);

        /*
#if UNITY_EDITOR
        //エディタ上でのオンオフ設定
        _mainCamera.gameObject.SetActive(false);
        _debugCamera.gameObject.SetActive(true);
#elif UNITY_ANDROID
        //アンドロイド上でのオンオフ設定
        _mainCamera.gameObject.SetActive(true);
        _debugCamera.gameObject.SetActive(false);
#else

#endif
        */

        if (Camera.main != null)
        {
            _debugCamera.gameObject.SetActive(false);
        }
        else
        {
            _debugCamera.gameObject.tag = "MainCamera";
            Debug.Log("We changed the DebugCamera Tag to MainCamera.");
        }

        // コメントアウトの追加
        Application.logMessageReceived += HandleLog;

        //スタート時の表示非表示設定
        debugLogs.transform.gameObject.SetActive(activeAtStart);

    }
    public void Start()
    {
        appConfig = _appMaster.AppConfig;
    }

    private void Update()
    {
        WriteLog();
        ClearAddLog();
        TapActionCheck();

        //UpdateDebugObject();
    }

    private static void HandleLog(string condition, string stackTrace, LogType type)
    {
        // ログをリストに追加
        logHistory.Add(condition);

        // 最大5つまで表示
        if (logHistory.Count > 3)
        {
            logHistory.RemoveAt(0); // 古いログを削除
        }

        // 複数行でログを表示
        debug_Console.text = string.Join("\n", logHistory);
    }

    private static void TapActionCheck()
    {
        if (Input.touchCount == 3)
        {
            bool taped = false;
            foreach (Touch touch in Input.touches)
            {
                if (touch.phase == TouchPhase.Ended)
                {
                    taped = true;
                }
            }
            if (taped)
            {
                //トリプルタップの処理
                if (debugLogs.gameObject.activeSelf) { debugLogs.gameObject.SetActive(false); }
                else { debugLogs.gameObject.SetActive(true); }
            }
        }
        else if (Input.touchCount == 4)
        {
            bool taped = false;
            foreach (Touch touch in Input.touches)
            {
                if (touch.phase == TouchPhase.Ended)
                {
                    taped = true;
                }
            }
            if (taped)
            {
                //クアドラプルタップの処理
                Debug.Log("quadruple tapped.");
            }
        }
    }

    private static void ClearAddLog()
    {
        addLogText = "";
    }

    private static void WriteLog()
    {

#if UNITY_EDITOR

#elif UNITY_ANDROID

#else

#endif
        //◆◆下記が状態確認とログ入れ込み

        AddLog("DebugSystem is running.");

        //◆◆下記がログの書き出し

        //初期化
        logText = "";
        //ログを入れる
        logText += SetDefaultLog();
        logText += SetAddLog();

        //従前とログが異なる場合にアップデート
        if (logText != lastLogText)
        {
            debug_text.text = null;
            debug_text.text = "Debug log : \n" + logText;
            lastLogText = logText;
        }

    }

    private static string SetDefaultLog()
    {
        string returnStr = "";
        deltaTime = Time.time - lastTime;
        lastTime = Time.time;
        float currentFps = 1.0f / deltaTime;
        minFpsCurrent = 10000.0f;
        fpsAverage.Add(currentFps);
        fpsLongAverage.Add(currentFps);
        if (fpsAverage.Count > fpsAverageCheckCount) fpsAverage.RemoveRange(0, fpsAverage.Count - fpsAverageCheckCount);
        if (fpsLongAverage.Count > fpsLongAverageCheckCount) fpsLongAverage.RemoveRange(0, fpsLongAverage.Count - fpsLongAverageCheckCount);
        float fpsAmmount = 0.0f;
        float fpsLongAmmount = 0.0f;

        if (lastTime > 10.0f) startMinFpsCheck = true;

        foreach ( float oneFps in fpsAverage )
        {
            fpsAmmount += oneFps;
            if (oneFps < minFpsCurrent) minFpsCurrent = oneFps;
        }
        fps = fpsAmmount / fpsAverage.Count;
        if (fps < minFpsOnApp && startMinFpsCheck) minFpsOnApp = fps;
        foreach (float oneFps in fpsLongAverage)
        {
            fpsLongAmmount += oneFps;
        }
        fpsLong = fpsLongAmmount / fpsLongAverage.Count;

        returnStr +=
            $"Date and Time : {DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")} \n" +
            $"Touch Count : {Input.touchCount}\n" +
            $"\n" +
            $"config - currentPhase : {appConfig.GetAppPhase()}\n" +
            $"\n" +
            $"Has valid map / cs : {mapperTCT.GetMap().HasValidMap()} / {appConfig.MadeMap}\n" +
            $"config - madePhoto : {appConfig.MadePhoto}\n" +
            $"config - submitted : {appConfig.Submitted}\n" +
            $"config - gotMapList : {appConfig.GotMapList}\n" +
            $"Tracking device map / cs : {trackerTCT.GetDeviceMapCondition()} / {appConfig.GotMap}\n" +
            $"Tracking state / cs : {trackerTCT.GetTrackingState()} / {appConfig.GotTracking}\n" +
            $"\n" +
            $"WPS Status : {wpsManager.Status.ToString()}\n" +
            $"\n" +
            $"Camera local position : {Camera.main.transform.localPosition}\n" +
            $"Camera local euler angles : {Camera.main.transform.localEulerAngles}\n" +
            $"Compass Heading : {compassWorldPoseTCT.CameraHelper.TrueHeading}\n" +
            $"Compass Latitude : {compassWorldPoseTCT.CameraHelper.Latitude}\n" +
            $"Compass Longitude : {compassWorldPoseTCT.CameraHelper.Longitude}\n" +
            // $"CURRENT FPS : {fps:F2} \n" +
            // $"CU.Long FPS : {fpsLong:F2} \n" +
            // $"MIN FPS CU. : {minFpsCurrent:F2} \n" +
            // $"MIN FPS APP : {minFpsOnApp:F2} \n" +
            $"\n" +
            $"Log : \n" +
            $"\n";

        return returnStr;
    }

    private static void AddLog(string str)
    {
        addLogText += str;
    }

    private static string SetAddLog()
    {
        string returnStr = "";

        returnStr = addLogText;

        return returnStr;
    }

    private static void UpdateDebugObject()
    {
        //_directionPrefab.transform.localEulerAngles = GPSChecker.Instance.northDirection;
        //_directionPrefab.transform.rotation = GPSChecker.Instance.northQuaternion;
        //_screenPanelPrefab.transform.rotation = GPSChecker.Instance.northQuaternion * CameraChecker.cameraNSEWQuaternion;
    }

    public static void SetActionLog(string str)
    {
        actionLogText = str;
        debug_Action_text.text = actionLogText;
    }
    public static void ClearActionLog()
    {
        actionLogText = "";
        debug_Action_text.text = actionLogText;
    }

    public static void ClearLog()
    {

        //初期化
        logText = "";
        //ログを入れる
        logText += SetDefaultLog();
        logText += SetAddLog();

        //従前とログが異なる場合にアップデート
        if (logText != lastLogText)
        {
            debug_text.text = null;
            debug_text.text = "Debug log : \n" + logText;
            lastLogText = logText;
        }
    }
}
