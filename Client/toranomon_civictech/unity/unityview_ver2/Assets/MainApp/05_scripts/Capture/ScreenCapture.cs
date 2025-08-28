using System;
using System.IO;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Android;

public class ScreenCapture : MonoBehaviour
{
    public static ScreenCapture Instance { set; get; }

    private static Camera mainCamera;
    private static bool captureExecution;
    public static Texture2D screenShot;
    private static Texture2D localSavePhoto;

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

        captureExecution = false;
    }

    private void CameraCheck()
    {
        if (Camera.main != null)
        {
            mainCamera = Camera.main;
        }
        else
        {
            Debug.Log("You don't have main camera object at hierarchy, we change no-active ScreenCapture script");
            Destroy(this);
        }


    }

    public static void TakeScreenshot()
    {
        // スクショ用の、ARカメラ描画結果を格納するRenderTextureを用意する
        //RenderTexture rt = RenderTexture.GetTemporary(Screen.width * 2, Screen.height * 2, 24, RenderTextureFormat.ARGB32);
        RenderTexture rt = RenderTexture.GetTemporary(Screen.width, Screen.height, 24, RenderTextureFormat.ARGB32);

        // 用意したRenderTextureに書き込む
        //レンダーテクスチャの現状をいったん外す
        RenderTexture prevTarget = mainCamera.targetTexture;
        //カメラのレンダリングを書き込み用のRnderTextureに一時的に移動
        mainCamera.targetTexture = rt;
        //メインカメラを一度レンダリング（≒rtに書き込み）
        mainCamera.Render();
        //カメラのレンダリング先を戻す
        mainCamera.targetTexture = prevTarget;

        // RenderTextureのままでは保存できないので、Textureに変換する
        //アクティブなレンダーテクスチャをいったん外す
        RenderTexture prevActive = RenderTexture.active;
        //アクティブなレンダーテクスチャをrtにする
        RenderTexture.active = rt;
        //ローカル保存するデータを格納するTexture2Dを作成する
        //localSavePhoto = new Texture2D(mainCamera.pixelWidth * 2, mainCamera.pixelHeight * 2, TextureFormat.ARGB32, false);
        //ピクセルデータをアクティブなレンダーテクスチャ情報から読み込む
        //localSavePhoto.ReadPixels(new Rect(0, 0, localSavePhoto.width, localSavePhoto.height), 0, 0, false);
        //スクリーンショットを格納するTexture2Dを作成する
        screenShot = new Texture2D(mainCamera.pixelWidth, mainCamera.pixelHeight, TextureFormat.ARGB32, false);
        //ピクセルデータをアクティブなレンダーテクスチャ情報から読み込む
        screenShot.ReadPixels(new Rect(0, 0, screenShot.width, screenShot.height), 0, 0, false);
        RenderTexture.active = prevActive;
        RenderTexture.ReleaseTemporary(rt);
        // 変更を適用
        //localSavePhoto.Apply();
        screenShot.Apply();
        //◆ローカルへの保存
        //Instance.StartCoroutine(SaveScreenShotAtLocal(localSavePhoto));
        Instance.StartCoroutine(SaveScreenShotAtLocal(screenShot));

    }

    private static IEnumerator SaveScreenShotAtLocal(Texture2D scrSht)
    {
        byte[] originalBytes = scrSht.EncodeToJPG(100);
        string timestamp = DateTime.Now.ToString("yyyyMMddHHmmss");
        string folderPath;
        //string folderPath = Path.Combine(Application.persistentDataPath, "enxross");
#if UNITY_ANDROID
        folderPath = Path.Combine("/storage/emulated/0/Pictures", "enxross");
#elif UNITY_IOS
        folderPath = Path.Combine(Application.persistentDataPath, "Documents", "enxross");
#else
        folderPath = Path.Combine(Application.persistentDataPath, "enxross");
#endif
        string filePath = Path.Combine(folderPath, $"screenshot{timestamp}.jpg");
        if (!Directory.Exists(folderPath))
        {
            Directory.CreateDirectory(folderPath);
        }
        try
        {
            // ファイルを書き込む
            File.WriteAllBytes(filePath, originalBytes);
            ScanMedia(filePath);
            //Debug.Log("check save done."); //■■DEBUG LOG
        }
        catch (Exception ex)
        {
            Debug.LogError($"Failed to save screenshot: {ex.Message}");
        }
        //Debug.Log("check end coroutine."); //■■DEBUG LOG
        yield return null;
    }

    //メディアスキャンを実行してデータが反映されるようにする
    private static void ScanMedia(string fileName)
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

public static bool GetCaptureCondition()
    {
        return captureExecution;
    }

    public static void SetCaptureCondition(bool bl)
    {
        captureExecution = bl;
    }


}
