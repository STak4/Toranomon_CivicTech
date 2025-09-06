// based on: Assets/Samples/WPS/Scripts/Compass/CompassworldPose.cs

using Niantic.Lightship.AR.WorldPositioning;

using UnityEngine;
using UnityEngine.XR.ARFoundation;

public class CompassWorldPoseTCT : MonoBehaviour
{
    [SerializeField] private ARCameraManager _arCameraManager;
    [SerializeField] private UnityEngine.UI.Image _compassImage;

    private ARWorldPositioningCameraHelper _cameraHelper;
    public ARWorldPositioningCameraHelper CameraHelper => _cameraHelper;

    public void Start()
    {
        _cameraHelper = _arCameraManager.GetComponent<ARWorldPositioningCameraHelper>();
    }
    private void Update()
    {
        float heading = _cameraHelper.TrueHeading;
        _compassImage.rectTransform.rotation = Quaternion.Euler(0, 0, heading);
    }
    public float GetCurrentHeading()
    {
        return _cameraHelper.TrueHeading;
        /*
        // WPSデータが有効かどうか判定
        bool hasWps = _cameraHelper != null
            && !float.IsNaN(_cameraHelper.TrueHeading)
            && (_cameraHelper.TrueHeading != 0);

        if (hasWps) return _cameraHelper.TrueHeading;
        else return Input.compass.trueHeading;
        */
    }
    public double[] GetCurrentLLH()
    {
        double[] llh = new double[3]{
            _cameraHelper.Latitude,
            _cameraHelper.Longitude,
            _cameraHelper.Altitude
        };
        return llh;
        /*
        // WPSデータが有効かどうか判定
        bool hasWps = _cameraHelper != null
            && !double.IsNaN(_cameraHelper.Latitude)
            && !double.IsNaN(_cameraHelper.Longitude)
            && !double.IsNaN(_cameraHelper.Altitude)
            && (_cameraHelper.Latitude != 0 || _cameraHelper.Longitude != 0);

        if (hasWps)
        {
            double[] llh = new double[3]{
                _cameraHelper.Latitude,
                _cameraHelper.Longitude,
                _cameraHelper.Altitude
            };
            return llh;
        }
        else
        {
            // GPSデータを返す
            var loc = Input.location.lastData;
            double[] llh = new double[3]{
                loc.latitude,
                loc.longitude,
                loc.altitude
            };
            return llh;
        }
        */
    }
}
