using System;
using System.Collections.Generic;
using UnityEngine;

public enum AppMode
{
    Unspecified,

    Proposal,
    Reaction,
}

public enum AppPhase
{
    Unspecified,

    Initialization,
    Standby,

    Mapping,
    Mapped,
    PhotoShot,

    Radar,

    StandbyTracking,
    Searching,
    OnTracking,
}

public class AppConfig
{
    private AppMode _appMode = AppMode.Unspecified;
    private AppPhase _currentPhase = AppPhase.Unspecified;

    private bool _madeMap = false; // mapperTCT.GetMap().HasValidMap()
    private bool _madePhoto = false;
    private bool _submitted = false;
    private bool _gotMapList = false;
    // 下記が_deviceMapの状態と連動を想定しているが、実情は異なる。動作には概ね問題なし。
    private bool _gotMap = false; // trackerTCT.GetDeviceMapCondition()
    private bool _gotTracking = false; // trackerTCT.GetTrackingState()

    private bool _isInformationView = false;
    private bool _isArView = false;
    private bool _isStatusView = false;
    private bool _isModeView = false;
    private bool _isRadarView = false;

    private Thread _currentThread = null;

    private byte[] _latestMapBytes = null;
    private byte[] _latestPhotoBytes = null;
    private ARLogUnit _latestARLog = null;

    public event Action<AppPhase, AppPhase> PhaseChangeAction;
    public event Action<AppMode, AppMode> ModeChangeAction;

    public AppPhase GetAppPhase()
    {
        return _currentPhase;
    }
    public void SetAppPhase(AppPhase newPhase)
    {
        if (_currentPhase != newPhase)
        {
            AppPhase oldPhase = _currentPhase;
            _currentPhase = newPhase;
            TriggerPhaseChange(oldPhase, newPhase);
        }
    }
    public AppMode GetAppMode()
    {
        return _appMode;
    }
    public void SetAppMode(AppMode newMode)
    {
        if (_appMode != newMode)
        {
            AppMode oldMode = _appMode;
            _appMode = newMode;
            TriggerModeChange(oldMode, newMode);
        }
    }
    public bool MadeMap
    {
        get { return _madeMap; }
        set { _madeMap = value; }
    }
    public bool MadePhoto
    {
        get { return _madePhoto; }
        set { _madePhoto = value; }
    }
    public bool Submitted
    {
        get { return _submitted; }
        set { _submitted = value; }
    }
    public bool GotMapList
    {
        get { return _gotMapList; }
        set { _gotMapList = value; }
    }
    public bool GotMap
    {
        get { return _gotMap; }
        set { _gotMap = value; }
    }
    public bool GotTracking
    {
        get { return _gotTracking; }
        set { _gotTracking = value; }
    }


    public bool IsArView
    {
        get { return _isArView; }
        set { _isArView = value; }
    }
    public bool IsModeView
    {
        get { return _isModeView; }
        set { _isModeView = value; }
    }
    public bool IsStatusView
    {
        get { return _isStatusView; }
        set { _isStatusView = value; }
    }
    public bool IsRadarView
    {
        get { return _isRadarView; }
        set { _isRadarView = value; }
    }
    public bool IsInformationView
    {
        get { return _isInformationView; }
        set { _isInformationView = value; }
    }

    public byte[] LatestMapBytes
    {
        get { return _latestMapBytes; }
        set { _latestMapBytes = value; }
    }
    public byte[] LatestPhotoBytes
    {
        get { return _latestPhotoBytes; }
        set { _latestPhotoBytes = value; }
    }

    public Texture2D LatestPhotoTexture
    {
        get
        {
            if (_latestPhotoBytes != null)
            {
                Texture2D texture = new Texture2D(2, 2);
                if (texture.LoadImage(_latestPhotoBytes)) return texture;
            }
            return null;
        }
    }
    public ARLogUnit LatestARLog
    {
        get { return _latestARLog; }
        set { _latestARLog = value; }
    }

    public void CreateThread(double[] llh)
    {
        _currentThread = new Thread();
        _currentThread.Uuid = Guid.NewGuid().ToString();
        _currentThread.LLH = llh;
    }

    public void LoadThread(Thread thread)
    {
        _currentThread = thread;
    }
    public string AddARLog(ARLogUnit log)
    {
        if (_currentThread != null)
        {
            log.Uuid = $"{_currentThread.Uuid}_{_currentThread.ARLogSet.ARLogs.Count.ToString("D4")}";
            _currentThread.ARLogSet.ARLogs.Add(log);
            return log.Uuid;
        }
        else
        {
            Debug.LogError("CurrentThread is null. Cannot add ARLog.");
            return string.Empty;
        }
    }
    public void RemoveARLog(string uuid)
    {
        if (_currentThread != null)
        {
            ARLogUnit logToRemove = _currentThread.ARLogSet.ARLogs.Find(log => log.Uuid == uuid);
            if (logToRemove != null)
            {
                _currentThread.ARLogSet.ARLogs.Remove(logToRemove);
            }
            else
            {
                Debug.LogWarning($"ARLog with UUID {uuid} not found in the current thread.");
            }
        }
        else
        {
            Debug.LogError("CurrentThread is null. Cannot remove ARLog.");
        }
    }
    public void SetMap(byte[] mapBytes)
    {
        if (_currentThread != null)
        {
            _currentThread.Map = mapBytes;
        }
        else
        {
            Debug.LogError("CurrentThread is null. Cannot add Map.");
        }
    }

    public void ClearThread()
    {
        if (_currentThread != null) _currentThread = null;
    }
    public Thread GetThread()
    {
        return _currentThread;
    }


    private void TriggerPhaseChange(AppPhase oldPhase, AppPhase newPhase)
    {
        Debug.Log($"Phase changed from {oldPhase} to {newPhase}");
        PhaseChangeAction?.Invoke(oldPhase, newPhase);
    }
    private void TriggerModeChange(AppMode oldMode, AppMode newMode)
    {
        Debug.Log($"Mode changed from {oldMode} to {newMode}");
        ModeChangeAction?.Invoke(oldMode, newMode);
    }
}


