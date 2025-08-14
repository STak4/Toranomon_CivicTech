// Copyright 2022-2025 Niantic.

using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DrawRectTCT : MonoBehaviour
{
    [SerializeField]
    private GameObject _rectanglePrefab;
    [SerializeField]
    private Transform _parentTransform;

    private List<UIRectObjectTCT> _rectangleObjects = new List<UIRectObjectTCT>();
    private List<int> _openIndices = new List<int>();

    public void CreateRect(Rect rect, Color color, string text)
    {
        if (_openIndices.Count == 0)
        {
            var newRect = Instantiate(_rectanglePrefab, parent: _parentTransform).GetComponent<UIRectObjectTCT>();

            _rectangleObjects.Add(newRect);
            _openIndices.Add(_rectangleObjects.Count - 1);
        }
        
        // Treat the first index as a queue
        int index = _openIndices[0];
        _openIndices.RemoveAt(0);
        if(_parentTransform.gameObject.activeInHierarchy)
        {
            UIRectObjectTCT rectangle = _rectangleObjects[index];
            rectangle.SetRectTransform(rect);
            rectangle.SetColor(color);
            rectangle.SetText(text);
            rectangle.gameObject.SetActive(true);
        }       
    }

    public void ClearRects()
    {
        for (var i = 0; i < _rectangleObjects.Count; i++)
        {
            _rectangleObjects[i].gameObject.SetActive(false);
            _openIndices.Add(i);
        }
    }
}

