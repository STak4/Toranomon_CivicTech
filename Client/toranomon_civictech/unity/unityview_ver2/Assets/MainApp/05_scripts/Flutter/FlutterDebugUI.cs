#nullable enable

using System;
using System.Threading.Tasks;
using UnityEngine;
using Newtonsoft.Json;
using FlutterUnityIntegration;
using UnityEngine.UI;

public class FlutterDebugUI : MonoBehaviour
{
    [SerializeField] private UnityMessageManager _unityMessageManager = null!;

    [SerializeField] private GameObject _startView = null!;
    [SerializeField] private GameObject _blankView = null!;
    [SerializeField] private GameObject _postView = null!;
    [SerializeField] private GameObject _voteView = null!;

    [SerializeField] private Button _captureButton = null!;
    [SerializeField] private Button _viewButton = null!;
    [SerializeField] private Button _setLocationButton = null!;

    [SerializeField] private Image _photoImage = null!;
    [SerializeField] private Button _recaptureButton = null!;
    [SerializeField] private Button _generatedButton = null!;


    [SerializeField] private Button _voteButtonA = null!;
    [SerializeField] private Button _voteButtonB = null!;
    [SerializeField] private Button _voteButtonC = null!;
    [SerializeField] private Button _voteButtonD = null!;
    [SerializeField] private Button _voteButtonE = null!;

    bool gotAwake = false;
    string pathData = "";
    double latitude = 35.666924;
    double longitude = 139.747533;
    private void Awake()
    {
        _unityMessageManager.OnSendMessageForDebug += ReceiveMessageFromUnity;

        _captureButton.onClick.AddListener(async () => await CaptureButton());
        _viewButton.onClick.AddListener(async () => await ViewButton());
        _setLocationButton.onClick.AddListener(() => SetLocationButton(latitude, longitude));

        _recaptureButton.onClick.AddListener(() => RecaptureButton());
        _generatedButton.onClick.AddListener(() => GeneratedButton(pathData));

        _voteButtonA.onClick.AddListener(() => VoteButton(0));
        _voteButtonB.onClick.AddListener(() => VoteButton(1));
        _voteButtonC.onClick.AddListener(() => VoteButton(2));
        _voteButtonD.onClick.AddListener(() => VoteButton(3));
        _voteButtonE.onClick.AddListener(() => VoteButton(4));
    }
    private void Start()
    {
        _startView.SetActive(true);
        _blankView.SetActive(false);
        _postView.SetActive(false);
        _voteView.SetActive(false);
    }
    private void OnApplicationQuit()
    {
        _unityMessageManager.OnSendMessageForDebug -= ReceiveMessageFromUnity;
        _captureButton.onClick.RemoveListener(async () => await CaptureButton());
        _viewButton.onClick.RemoveListener(async () => await ViewButton());
        _setLocationButton.onClick.RemoveListener(() => SetLocationButton(latitude, longitude));

        _recaptureButton.onClick.RemoveListener(() => RecaptureButton());
        _generatedButton.onClick.RemoveListener(() => GeneratedButton(pathData));

        _voteButtonA.onClick.RemoveListener(() => VoteButton(0));
        _voteButtonB.onClick.RemoveListener(() => VoteButton(1));
        _voteButtonC.onClick.RemoveListener(() => VoteButton(2));
        _voteButtonD.onClick.RemoveListener(() => VoteButton(3));
        _voteButtonE.onClick.RemoveListener(() => VoteButton(4));
    }

    private async Task CaptureButton()
    {
        gotAwake = false;
        _startView.SetActive(false);
        _blankView.SetActive(true);
        SendMessageToUnity(FlutterMessageName.Awake);
        float maxWait = 5f;
        float waitCount = 0f;
        while (!gotAwake && waitCount < maxWait)
        {
            await Task.Delay(100);
            waitCount += 0.1f;
        }
        _blankView.SetActive(false);
        SendMessageToUnity(FlutterMessageName.Capture);
        gotAwake = false;
    }

    private async Task ViewButton()
    {
        gotAwake = false;
        _startView.SetActive(false);
        _blankView.SetActive(true);
        SendMessageToUnity(FlutterMessageName.Awake);
        float maxWait = 5f;
        float waitCount = 0f;
        while (!gotAwake && waitCount < maxWait)
        {
            await Task.Delay(100);
            waitCount += 0.1f;
        }
        _blankView.SetActive(false);
        SendMessageToUnity(FlutterMessageName.View);
        gotAwake = false;
    }
    private void VoteButton(int option)
    {
        FlutterMessageData optionData = new FlutterMessageData
        {
            NameType = FlutterMessageName.Vote,
            Rate = option
        };
        SendMessageToUnity(FlutterMessageName.Vote, optionData);
        _voteView.SetActive(false);
    }

    private void SetLocationButton(double latitude, double longitude)
    {
        FlutterMessageData locationData = new FlutterMessageData
        {
            NameType = FlutterMessageName.Setlocation,
            Lat = latitude,
            Lng = longitude
        };
        SendMessageToUnity(FlutterMessageName.Setlocation, locationData);
    }

    private void RecaptureButton()
    {
        SendMessageToUnity(FlutterMessageName.Recapture);
    }
    private void GeneratedButton(string path)
    {
        FlutterMessageData generateData = new FlutterMessageData
        {
            NameType = FlutterMessageName.Generated,
            Path = path
        };
        SendMessageToUnity(FlutterMessageName.Generated, generateData);
    }


    private async Task ReceiveUnityCommand(FlutterMessage message)
    {
        FlutterMessageName name = message.Data?.NameType ?? FlutterMessageName.Unspecified;
        switch (name)
        {
            case FlutterMessageName.Awake:
                gotAwake = true;
                break;

            case FlutterMessageName.Quit:
                _startView.SetActive(true);
                _blankView.SetActive(false);
                _postView.SetActive(false);
                _voteView.SetActive(false);
                break;

            case FlutterMessageName.Shoot:
                pathData = message.Data?.Path ?? "";
                await ViewPhoto(pathData);
                _postView.SetActive(true);
                break;

            case FlutterMessageName.Back:
                _startView.SetActive(true);
                break;

            case FlutterMessageName.Openvote:
                _voteView.SetActive(true);
                break;

            case FlutterMessageName.Setlocation:
                latitude = message.Data?.Lat ?? latitude;
                longitude = message.Data?.Lng ?? longitude;
                await BlankTask();
                break;

            default:
                break;
        }
    }
    private async Task ViewPhoto(string path)
    {
        if (string.IsNullOrEmpty(path))
        {
            Debug.LogWarning("[FlutterDebugUI] ViewPhoto: pathData is null or empty");
            return;
        }
        byte[] imageBytes;
        try
        {
            imageBytes = System.IO.File.ReadAllBytes(path);
        }
        catch (Exception ex)
        {
            Debug.LogError($"[FlutterDebugUI] ViewPhoto: Failed to read image file at {path}. Exception: {ex.Message}");
            return;
        }

        Texture2D texture = new Texture2D(2, 2);
        if (!texture.LoadImage(imageBytes))
        {
            Debug.LogError("[FlutterDebugUI] ViewPhoto: Failed to load image data into texture");
            return;
        }

        // Create a sprite from the texture
        Sprite photoSprite = Sprite.Create(texture, new Rect(0, 0, texture.width, texture.height), new Vector2(0.5f, 0.5f));
        _photoImage.sprite = photoSprite;

        await Task.Yield();
    }


    private async Task BlankTask()
    {
        await Task.Yield();
    }
    private void SendMessageToUnity(FlutterMessageName name, FlutterMessageData? data = null)
    {
        FlutterMessage msg = new FlutterMessage
        {
            Type = "command",
            Data = data ?? new FlutterMessageData { NameType = name }
        };
        SendMessageToUnity(msg);
    }
    private void SendMessageToUnity(FlutterMessage message)
    {
        string json = JsonConvert.SerializeObject(message);
        _unityMessageManager.onMessageDebug(json);
    }
    private void ReceiveMessageFromUnity(string message)
    {
        FlutterMessage? msg = JsonConvert.DeserializeObject<FlutterMessage>(message);
        if (msg == null)
        {
            Debug.LogWarning("[FlutterDebugUI] ReceiveMessageFromUnity: message is null");
            return;
        }
        _ = ReceiveUnityCommand(msg);
    }

}