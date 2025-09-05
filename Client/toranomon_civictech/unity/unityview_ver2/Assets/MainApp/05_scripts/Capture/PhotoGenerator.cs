using System;
using System.IO;
using System.Collections;
using UnityEngine;

public class PhotoGenerator : MonoBehaviour
{
    [SerializeField] private GameObject _photoPrefab;
    [SerializeField] private TrackerTCT _tracker;

    [Range(0.20f, 2.00f)] [SerializeField] private float _scaleFactor = 0.5f;
    [Range(1.00f, 5.00f)] [SerializeField] private float _distanceFactor = 3.0f;
    [Range(0.500f, 0.001f)] [SerializeField] private float _panelThickness = 0.05f;

    public float DistanceFactor { get { return _distanceFactor; } }
 
    public Vector3 GetPhotoObjectSize(Texture2D photoTexture)
    {
        float objectWidth = photoTexture.width / 1000.0f * _scaleFactor;
        float objectHeight = photoTexture.height / 1000.0f * _scaleFactor;
        return new Vector3(objectWidth, objectHeight, _panelThickness);
    }
    public void GeneratePhotoObject(ARLogUnit arLog, Texture2D photoTexture, bool isWorldPosition)
    {
        //Vector3 objectSize = GetPhotoObjectSize(photoTexture);

        if (_photoPrefab != null)
        {
            GameObject photoObject = Instantiate(_photoPrefab);
            arLog.ApplyToTransform(photoObject.transform);
            _tracker.AddObjectToAnchor(photoObject, isWorldPosition);
            ApplyTexture(photoObject, photoTexture);
        }
    }
    public void ApplyTexture(GameObject photoObject, Texture2D photoTexture)
    {
        if (photoObject.transform.childCount > 0)
        {
            Transform child = photoObject.transform.GetChild(0);
            Renderer renderer = child.GetComponent<Renderer>();
            if (renderer != null) renderer.material.mainTexture = photoTexture;
        }
    }
}
