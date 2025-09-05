using System;
using System.IO;
using System.Collections;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.Android;

public class ScreenCaptureManager : MonoBehaviour
{
    public static ScreenCaptureManager Instance { set; get; }

    [SerializeField] private bool _saveToDevice;

    private Camera _mainCamera;
    private Texture2D _screenShot;
    private bool _captureExecution;
    public bool CaptureExecution { get => _captureExecution; private set => _captureExecution = value; }

    private void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
            if (Application.platform == RuntimePlatform.Android)
            {
                if (!Permission.HasUserAuthorizedPermission(Permission.ExternalStorageWrite))
                {
                    Permission.RequestUserPermission(Permission.ExternalStorageWrite);
                }
            }
            Invoke(nameof(CameraCheck), 1.0f);
        }
        else
        {
            Destroy(this);
        }

        _captureExecution = false;
    }

    private void CameraCheck()
    {
        if (Camera.main != null)
        {
            _mainCamera = Camera.main;
        }
        else
        {
            Debug.Log("You don't have main camera object at hierarchy, we change no-active ScreenCapture script");
            Destroy(this);
        }
    }

    public Texture2D TakeScreenshot()
    {
        // 下記がUnity標準のスクショ取得方法らしいが、エラー出すため使わない
        //Texture2D _screenShot = ScreenCapture.CaptureScreenshotAsTexture();

        // スクショ用の、ARカメラ描画結果を格納するRenderTextureを用意する
        RenderTexture rt = RenderTexture.GetTemporary(Screen.width, Screen.height, 24, RenderTextureFormat.ARGB32);

        // 用意したRenderTextureに書き込む
        //レンダーテクスチャの現状をいったん外す
        RenderTexture prevTarget = _mainCamera.targetTexture;
        //カメラのレンダリングを書き込み用のRnderTextureに一時的に移動
        _mainCamera.targetTexture = rt;
        //メインカメラを一度レンダリング（≒rtに書き込み）
        _mainCamera.Render();
        //カメラのレンダリング先を戻す
        _mainCamera.targetTexture = prevTarget;

        // RenderTextureのままでは保存できないので、Textureに変換する
        //アクティブなレンダーテクスチャをいったん外す
        RenderTexture prevActive = RenderTexture.active;
        //アクティブなレンダーテクスチャをrtにする
        RenderTexture.active = rt;
        //スクリーンショットを格納するTexture2Dを作成する
        _screenShot = new Texture2D(_mainCamera.pixelWidth, _mainCamera.pixelHeight, TextureFormat.ARGB32, false);
        //ピクセルデータをアクティブなレンダーテクスチャ情報から読み込む
        _screenShot.ReadPixels(new Rect(0, 0, _screenShot.width, _screenShot.height), 0, 0, false);
        RenderTexture.active = prevActive;
        RenderTexture.ReleaseTemporary(rt);
        // 変更を適用
        _screenShot.Apply();

        return _screenShot;
    }

    public async Task<string> SaveScreenShotAtLocal(Texture2D scrSht, string uuid)
    {
        byte[] originalBytes = scrSht.EncodeToJPG(100);
        string folderPath;
#if UNITY_ANDROID
        folderPath = Path.Combine(Application.persistentDataPath, "images");
        // folderPath = Path.Combine("/storage/emulated/0/Pictures", "enxross");
#elif UNITY_IOS
        folderPath = Path.Combine(Application.persistentDataPath, "Documents", "images");
#else
        folderPath = Path.Combine(Application.persistentDataPath, "images");
#endif
        string filePath = Path.Combine(folderPath, $"{uuid}.jpg");
        if (!Directory.Exists(folderPath))
        {
            Directory.CreateDirectory(folderPath);
        }
        try
        {
            // ファイルを書き込む
            await File.WriteAllBytesAsync(filePath, originalBytes);
            ScanMedia(filePath);
            return filePath;
        }
        catch (Exception ex)
        {
            Debug.LogError($"Failed to save screenshot: {ex.Message}");
            return string.Empty;
        }
    }
    public async Task<Texture2D> LoadScreenShotAtLocal(string fileName)
    {
        string folderPath;
#if UNITY_ANDROID
        folderPath = Path.Combine(Application.persistentDataPath, "images");
        // folderPath = Path.Combine("/storage/emulated/0/Pictures", "enxross");
#elif UNITY_IOS
        folderPath = Path.Combine(Application.persistentDataPath, "Documents", "images");
#else
        folderPath = Path.Combine(Application.persistentDataPath, "images");
#endif
        string filePath = Path.Combine(folderPath, fileName);
        if (!File.Exists(filePath))
        {
            Debug.LogError($"Screenshot not found: {filePath}");
            return null;
        }

        byte[] fileData = await File.ReadAllBytesAsync(filePath);
        Texture2D texture = new Texture2D(2, 2);
        texture.LoadImage(fileData);
        return texture;
    }

    //メディアスキャンを実行してデータが反映されるようにする
    private void ScanMedia(string fileName)
    {
        if (Application.platform != RuntimePlatform.Android) return;
#if UNITY_ANDROID
        using (AndroidJavaClass jcUnityPlayer = new AndroidJavaClass("com.unity3d.player.UnityPlayer"))
        using (AndroidJavaObject joActivity = jcUnityPlayer.GetStatic<AndroidJavaObject>("currentActivity"))
        using (AndroidJavaObject joContext = joActivity.Call<AndroidJavaObject>("getApplicationContext"))
        using (AndroidJavaClass jcMediaScannerConnection = new AndroidJavaClass("android.media.MediaScannerConnection"))
            jcMediaScannerConnection.CallStatic("scanFile", joContext, new string[] { fileName }, new string[] { "image/jpg" }, null);
        Handheld.StopActivityIndicator();
#endif
    }

}
