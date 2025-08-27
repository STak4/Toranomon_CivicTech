using System;
using System.Collections.Generic;
using UnityEngine;

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
    Tracking,
    Tracked,
}

public class AppConfig
{
    private AppPhase _currentPhase = AppPhase.Unspecified;

    private bool _madeMap = false;
    private bool _madePhoto = false;
    private bool _submitted = false;
    private bool _gotMapList = false;
    private bool _gotNearbyMap = false;
    private bool _gotTracked = false;

    private bool _isInformationView = false;
    private bool _isArView = false;
    private bool _isStatusView = false;
    private bool _isRadarView = false;

    private byte[] _latestMapBytes = null;

    public event Action<AppPhase, AppPhase> PhaseChangeAction;

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
    public bool GotNearbyMap
    {
        get { return _gotNearbyMap; }
        set { _gotNearbyMap = value; }
    }
    public bool GotTracked
    {
        get { return _gotTracked; }
        set { _gotTracked = value; }
    }


    public bool IsArView
    {
        get { return _isArView; }
        set { _isArView = value; }
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

    private void TriggerPhaseChange(AppPhase oldPhase, AppPhase newPhase)
    {
        Debug.Log($"Phase changed from {oldPhase} to {newPhase}");
        PhaseChangeAction?.Invoke(oldPhase, newPhase);
    }

}


