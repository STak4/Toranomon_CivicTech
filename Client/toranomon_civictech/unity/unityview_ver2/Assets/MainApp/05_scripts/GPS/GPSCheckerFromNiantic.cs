using System;
using UnityEngine;
using Input = Niantic.Lightship.AR.Input;

public class GPSCheckerFromNiantic : MonoBehaviour
{
    private void Update()
    {
        if (Input.location.status == LocationServiceStatus.Running)
        {
            double latitude = Input.location.lastData.latitude;
            double longitude = Input.location.lastData.longitude;
            double timestamp = Input.location.lastData.timestamp;

            DateTimeOffset gpsTime = DateTimeOffset.FromUnixTimeSeconds((long)timestamp);
            DateTimeOffset gpsTimeJST = gpsTime.ToOffset(TimeSpan.FromHours(9));

            Debug.Log($"GPS is enabled: Latitude = {latitude}, Longitude = {longitude}, Timestamp = {gpsTimeJST} (JST)");
        }
    }
}
