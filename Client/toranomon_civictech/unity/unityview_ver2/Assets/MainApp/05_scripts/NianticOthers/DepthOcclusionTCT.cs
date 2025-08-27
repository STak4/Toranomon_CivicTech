// Copyright 2022-2025 Niantic.
using System;
using System.Collections;
using System.Collections.Generic;
using Niantic.Lightship.AR.Occlusion;
using Niantic.Lightship.AR.Semantics;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.XR.ARFoundation;

public class DepthOcclusionTCT : MonoBehaviour
{
    [SerializeField] private AROcclusionManager _occlusionManager;
    [SerializeField] private ARSemanticSegmentationManager _segmentationManager;
#pragma warning disable 0618 //TCT:アラートがある為挿入
    [SerializeField] private LightshipOcclusionExtension _occlusionExtension;
#pragma warning restore 0618 //TCT:アラートがある為挿入

    private bool _occlusionReady = false;
    private bool _semanticsReady = false;

    private void OnEnable()
    {
        _occlusionManager.frameReceived += OnOcclusionReady;
        _segmentationManager.MetadataInitialized += OnSemanticsReady;
    }
    
    private void OnDisable()
    {
        if (!_occlusionReady)
        {
            _occlusionManager.frameReceived -= OnOcclusionReady;
        }

        if (!_semanticsReady)
        {
            _segmentationManager.MetadataInitialized -= OnSemanticsReady;
        }
    }

    private void OnOcclusionReady(AROcclusionFrameEventArgs frameEventArgs)
    {
        _occlusionReady = true;
        _occlusionManager.frameReceived -= OnOcclusionReady;
    }
    
    private void OnSemanticsReady(ARSemanticSegmentationModelEventArgs modelEventArgs)
    {
        _semanticsReady = true;
        _segmentationManager.MetadataInitialized -= OnSemanticsReady;
    }
}
