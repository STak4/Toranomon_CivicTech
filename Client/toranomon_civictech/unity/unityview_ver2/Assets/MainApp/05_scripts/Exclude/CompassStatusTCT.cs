// based on: Assets/Samples/WPS/Scripts/Compass/CompassStatus.cs

using Niantic.Lightship.AR.WorldPositioning;

using UnityEngine;

public class CompassStatusTCT : MonoBehaviour
{
    [SerializeField] private ARWorldPositioningManager _wpsManager;
    [SerializeField] private UnityEngine.UI.Text _statusText;

    private void Awake()
    {
        // Prevent the screen from sleeping:
        Screen.sleepTimeout = SleepTimeout.NeverSleep;
    }

    private void Update()
    {
        _statusText.text = "WPS: " + _wpsManager.Status.ToString();
    }
}
