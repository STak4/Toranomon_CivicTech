// based on: Assets/Samples/WPS/Scripts/Compass/CompassworldPose.cs

using Niantic.Lightship.AR.WorldPositioning;

using UnityEngine;
using UnityEngine.XR.ARFoundation;

namespace WorldPoseSamples
{
    public class CompassWorldPoseTCT : MonoBehaviour
    {
        [SerializeField] private ARCameraManager _arCameraManager;
        [SerializeField] private UnityEngine.UI.Image _compassImage;

        [SerializeField] private UnityEngine.UI.Text _coordinatesText;

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

            _coordinatesText.text = "Latitude: " + _cameraHelper.Latitude + "\nLongitude: " + _cameraHelper.Longitude;
        }
    }
}
