#nullable enable

using System;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.UI;
using Newtonsoft.Json;
using FlutterUnityIntegration;

public class FlutterConnectManager : MonoBehaviour
{
    [SerializeField] private UnityMessageManager _unityMessageManager = null!;
    [SerializeField] private AppUIMaster _appUIMaster = null!;
    public AppConfig appConfig { get; set; } = new AppConfig();

    [SerializeField] private Button _quitButton = null!;

    private bool _isCommandProcessing = false;
    
    private string _keepPathForReWrite = "";

    public void Initialize()
    {
        _unityMessageManager.OnMessage += ReceiveMessageFromFlutter;
        _isCommandProcessing = false;

        _quitButton.onClick.AddListener(async () => await SendFlutterCommand(FlutterMessageName.Quit));

        // AppUIに接続する処理を並べる
        // if (_appUIMaster != null && _appUIMaster._arViewButton != null)
        //     _appUIMaster._arViewButton.onClick.AddListener(() => SendMessageToFlutter(FlutterMessageName.View));

    }
    public void Dispose()
    {
        SendMessageToFlutter(FlutterMessageName.Quit);
        _unityMessageManager.OnMessage -= ReceiveMessageFromFlutter;
        _isCommandProcessing = false;
    }
    public void SendAwake()
    {
        _ = SendFlutterCommand(FlutterMessageName.Awake);
    }
    public void SendPhotoShoot(string path)
    { 
        _keepPathForReWrite = path;
        FlutterMessageData data = new FlutterMessageData
        {
            NameType = FlutterMessageName.Shoot,
            Path = path
        };
        _ = SendFlutterCommand(FlutterMessageName.Shoot, data);
    }
    public void SendPhotoSelect()
    {
        _ = SendFlutterCommand(FlutterMessageName.Openvote);
    }

    private async Task SendFlutterCommand(FlutterMessageName name, FlutterMessageData? data = null)
    {
        if (_isCommandProcessing)
        {
            Debug.LogWarning("◆UNITY◆[FlutterConnectManager] SendFlutterCommand: command is still processing, ignore new command");
            return;
        }

        FlutterMessage msg = new FlutterMessage
        {
            Type = "command",
            Data = data ?? new FlutterMessageData { NameType = name }
        };

        _isCommandProcessing = true;

        switch (name)
        {
            case FlutterMessageName.Unspecified:
                Debug.LogWarning("◆UNITY◆[FlutterConnectManager] FlutterCommand: Unspecified");
                break;

            // ◆下記はUnity起動時にFlutter側へ通知
            case FlutterMessageName.Awake:
                Debug.Log("◆UNITY◆[FlutterConnectManager] FlutterCommand: Awake");
                SendMessageToFlutter(FlutterMessageName.Awake);
                break;

            case FlutterMessageName.Capture:
                Debug.LogWarning("◆UNITY◆[FlutterConnectManager] FlutterCommand: Capture, it should be used from Flutter side.");
                break;
            case FlutterMessageName.View:
                Debug.LogWarning("◆UNITY◆[FlutterConnectManager] FlutterCommand: View, it should be used from Flutter side.");
                break;
            case FlutterMessageName.Quit:
                Debug.Log("◆UNITY◆[FlutterConnectManager] FlutterCommand: Quit, it is used for debug quit phase checking.");
                DebugQuitFunction();
                SendMessageToFlutter(FlutterMessageName.Quit);
                break;

            // ◆下記はUnityからFlutterへ撮影したPathデータ送信
            case FlutterMessageName.Shoot:
                Debug.Log("◆UNITY◆[FlutterConnectManager] FlutterCommand: Shoot");
                // ◆◆◆◆関数実行開発◆◆◆◆
                SendMessageToFlutter(msg);
                break;

            case FlutterMessageName.Recapture:
                Debug.LogWarning("◆UNITY◆[FlutterConnectManager] FlutterCommand: Recapture, it should be used from Flutter side.");
                break;
            case FlutterMessageName.Generated:
                Debug.LogWarning("◆UNITY◆[FlutterConnectManager] FlutterCommand: Generated, it should be used from Flutter side.");
                break;

            // ◆下記は閲覧や撮影モードからFlutterへ戻ることの依頼
            case FlutterMessageName.Back:
                Debug.Log("◆UNITY◆[FlutterConnectManager] FlutterCommand: Back");
                // ◆◆◆◆関数実行開発◆◆◆◆
                SendMessageToFlutter(msg);
                break;
            // ◆下記はUnityからFlutterへVote画面表示依頼
            case FlutterMessageName.Openvote:
                Debug.Log("◆UNITY◆[FlutterConnectManager] FlutterCommand: Openvote");
                // ◆◆◆◆関数実行開発◆◆◆◆
                SendMessageToFlutter(msg);
                break;

            case FlutterMessageName.Vote:
                Debug.LogWarning("◆UNITY◆[FlutterConnectManager] FlutterCommand: Vote, it should be used from Flutter side.");
                break;

            // ◆下記は位置情報送信（未開発／必要に応じて対応）
            case FlutterMessageName.Setlocation:
                // ◆◆◆◆関数実行開発◆◆◆◆
                SendMessageToFlutter(msg);
                Debug.Log("◆UNITY◆[FlutterConnectManager] FlutterCommand: Setlocation");
                break;

            default:
                Debug.LogWarning($"◆UNITY◆[FlutterConnectManager] FlutterCommand: Unhandled command {name}");
                break;
        }
        await Task.Delay(100);  // 少し待つ
        _isCommandProcessing = false;
    }

    private async Task ReceiveFlutterCommand(FlutterMessage message)
    {
        if (_isCommandProcessing)
        {
            Debug.LogWarning("◆UNITY◆[FlutterConnectManager] ReceiveFlutterCommand: command is still processing, ignore new command");
            return;
        }
        _isCommandProcessing = true;

        FlutterMessageName name = message.Data?.NameType ?? FlutterMessageName.Unspecified;
        switch (name)
        {
            case FlutterMessageName.Unspecified:
                Debug.LogWarning("◆UNITY◆[FlutterConnectManager] FlutterCommand: Unspecified");
                break;

            case FlutterMessageName.Awake:
                Debug.Log("◆UNITY◆[FlutterConnectManager] FlutterCommand: Awake, it is used for debug awake phase checking.");
                await Task.Delay(1000);
                SendMessageToFlutter(FlutterMessageName.Awake);
                break;

            // ◆下記がメイントリガー１
            case FlutterMessageName.Capture:
                Debug.Log("◆UNITY◆[FlutterConnectManager] FlutterCommand: Capture");
                await _appUIMaster.TriggerMappingButtonAction();
                break;
            // ◆下記がメイントリガー２
            case FlutterMessageName.View:
                Debug.Log("◆UNITY◆[FlutterConnectManager] FlutterCommand: View");
                await _appUIMaster.TriggerRadarButtonAction();
                break;

            case FlutterMessageName.Quit:
                Debug.LogWarning("◆UNITY◆[FlutterConnectManager] FlutterCommand: Quit, it should be used from Unity side.");
                break;

            case FlutterMessageName.Shoot:
                Debug.LogWarning("◆UNITY◆[FlutterConnectManager] FlutterCommand: Shoot, it should be used from Unity side.");
                break;

            // ◆下記は中途動作
            case FlutterMessageName.Recapture:
                Debug.Log("◆UNITY◆[FlutterConnectManager] FlutterCommand: Recapture");
                await _appUIMaster.Recapture(_keepPathForReWrite);
                break;

            // ◆下記はPathデータ受領の上で保存実行（未開発）
            case FlutterMessageName.Generated:
                Debug.Log("◆UNITY◆[FlutterConnectManager] FlutterCommand: Generated");
                string path = message.Data?.Path ?? "";
                if (!string.IsNullOrEmpty(path)) await _appUIMaster.Generated(path, _keepPathForReWrite);
                else { }
                break;

            case FlutterMessageName.Back:
                Debug.LogWarning("◆UNITY◆[FlutterConnectManager] FlutterCommand: Back, it should be used from Unity side.");
                break;
            case FlutterMessageName.Openvote:
                Debug.LogWarning("◆UNITY◆[FlutterConnectManager] FlutterCommand: Openvote, it should be used from Unity side.");
                break;

            // ◆下記はFlutterからのVote結果受領
            case FlutterMessageName.Vote:
                int voteRate = (int)(message.Data?.Rate ?? -1);
                await _appUIMaster.VoteParticles(voteRate);
                Debug.Log("◆UNITY◆[FlutterConnectManager] FlutterCommand: Vote");
                break;

            // ◆下記は位置情報受信（未開発／必要に応じて対応）
            case FlutterMessageName.Setlocation:
                // ◆◆◆◆関数実行開発◆◆◆◆
                await BlankTask();
                Debug.Log("◆UNITY◆[FlutterConnectManager] FlutterCommand: Setlocation");
                break;

            default:
                Debug.LogWarning($"◆UNITY◆[FlutterConnectManager] FlutterCommand: Unhandled command {name}");
                break;
        }
        _isCommandProcessing = false;
    }
    private async Task BlankTask()
    {
        await Task.Yield();
    }
    private void DebugQuitFunction()
    {
        appConfig.SetAppPhase(AppPhase.Initialization);
    }

    private void SendMessageToFlutter(FlutterMessageName name)
    {
        FlutterMessage msg = new FlutterMessage
        {
            Type = "command",
            Data = new FlutterMessageData { NameType = name }
        };
        SendMessageToFlutter(msg);
    }
    private void SendMessageToFlutter(FlutterMessage message)
    {
        string json = JsonConvert.SerializeObject(message);
        _unityMessageManager.SendMessageToFlutter(json);
    }
    private void ReceiveMessageFromFlutter(string message)
    {
        FlutterMessage? msg = JsonConvert.DeserializeObject<FlutterMessage>(message);
        if (msg == null)
        {
            Debug.LogWarning("◆UNITY◆[FlutterConnectManager] ReceiveMessageFromFlutter: message is null");
            return;
        }
        _ = ReceiveFlutterCommand(msg);
    }

}

/// <summary>
/// Flutterに送信するメッセージ。typeとdata（lat, lng, rate, path, nameなど）を格納。
/// </summary>
public class FlutterMessage
{
    [JsonProperty("type")]
    public string Type { get; set; } = "command";

    [JsonProperty("data", NullValueHandling = NullValueHandling.Ignore)]
    public FlutterMessageData Data { get; set; } = new FlutterMessageData();
}
/// <summary>
/// Flutterに送信するメッセージのdata部。lat, lng, rate, path, nameなどを格納。未設定値はJSONに含めない。
/// </summary>
public class FlutterMessageData
{
    [JsonIgnore]
    public FlutterMessageName NameType { get; set; } = FlutterMessageName.Unspecified;

    [JsonProperty("name", NullValueHandling = NullValueHandling.Ignore)]
    public string? Name
    {
        get => NameType == FlutterMessageName.Unspecified ? null : NameType.ToString().ToLowerInvariant();
        set
        {
            if (string.IsNullOrEmpty(value))
            {
                NameType = FlutterMessageName.Unspecified;
            }
            else
            {
                // 先頭だけ大文字にしてEnum変換
                var enumStr = !string.IsNullOrEmpty(value)
                    ? char.ToUpper(value![0]) + value.Substring(1).ToLower()
                    : string.Empty;
                if (Enum.TryParse<FlutterMessageName>(enumStr, out var result))
                    NameType = result;
                else
                    NameType = FlutterMessageName.Unspecified;
            }
        }
    }

    [JsonProperty("lat", NullValueHandling = NullValueHandling.Ignore)]
    public double? Lat { get; set; }

    [JsonProperty("lng", NullValueHandling = NullValueHandling.Ignore)]
    public double? Lng { get; set; }

    [JsonProperty("rate", NullValueHandling = NullValueHandling.Ignore)]
    public double? Rate { get; set; }

    [JsonProperty("path", NullValueHandling = NullValueHandling.Ignore)]
    public string? Path { get; set; }

}

/// <summary>
/// Flutterメッセージのname種別（enum）
/// </summary>
public enum FlutterMessageName
{
    Unspecified,
    Awake,
    Capture,
    View,
    Quit,
    Shoot,
    Recapture,
    Generated,
    Back,
    Openvote,
    Vote,
    Setlocation
}
