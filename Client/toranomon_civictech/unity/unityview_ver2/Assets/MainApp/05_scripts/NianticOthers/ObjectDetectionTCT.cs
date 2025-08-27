// Based on: Assets\Samples\ObjectDetection\Scripts\ObjectDetectionSample.cs

using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using Niantic.Lightship.AR.ObjectDetection;
using Niantic.Lightship.AR.Subsystems.ObjectDetection;
using UnityEngine;
using UnityEngine.UI;

public class ObjectDetectionTCT: MonoBehaviour
{
    [SerializeField]
    private float _probabilityThreshold = 0.5f;
    
    [SerializeField]
    private ARObjectDetectionManager _objectDetectionManager;
    
    private Color[] _colors = new Color[]
    {
        Color.red,
        Color.blue,
        Color.green,
        Color.yellow,
        Color.magenta,
        Color.cyan,
        Color.white,
        Color.black
    };
    
    [SerializeField]
    private DrawRectTCT _drawRect;

    [SerializeField]
    private Canvas _canvas;

    [SerializeField] [Tooltip("Categories to display in the dropdown")]
    private List<string> _categoryNames;

    private string _categoryName = string.Empty;

    private void Awake()
    {

    }
    
    private void OnMetadataInitialized(ARObjectDetectionModelEventArgs args)
    {
        _objectDetectionManager.ObjectDetectionsUpdated += ObjectDetectionsUpdated;
    }

    private void ObjectDetectionsUpdated(ARObjectDetectionsUpdatedEventArgs args)
    {
        string resultString = "";
        float _confidence = 0;
        string _name = "";
        var result = args.Results; 
        if (result == null) return;
            
        _drawRect.ClearRects();
        for (int i = 0; i < result.Count; i++)
        {
            var detection = result[i];
            var categorizations = detection.GetConfidentCategorizations(_probabilityThreshold);
            if (categorizations.Count <= 0) break;
            categorizations.Sort((a, b) => b.Confidence.CompareTo(a.Confidence));
            var categoryToDisplay = categorizations[0];
            _confidence = categoryToDisplay.Confidence;
            _name = categoryToDisplay.CategoryName;            
            
            int h = Mathf.FloorToInt(_canvas.GetComponent<RectTransform>().rect.height);
            int w = Mathf.FloorToInt(_canvas.GetComponent<RectTransform>().rect.width);

            var _rect = result[i].CalculateRect(w,h,Screen.orientation);

            resultString = $"{_name}: {_confidence}\n";
            _drawRect.CreateRect(_rect, _colors[i % _colors.Length], resultString);
        }
    }

    public void Start()
    {
        _objectDetectionManager.enabled = true;
        _objectDetectionManager.MetadataInitialized += OnMetadataInitialized;
    }

    private void OnDestroy()
    {
        _objectDetectionManager.MetadataInitialized -= OnMetadataInitialized;
        _objectDetectionManager.ObjectDetectionsUpdated -= ObjectDetectionsUpdated;
    }
}