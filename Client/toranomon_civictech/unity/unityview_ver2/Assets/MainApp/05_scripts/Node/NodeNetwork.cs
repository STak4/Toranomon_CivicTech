using UnityEngine;
using UnityEngine.Networking;
using System.IO;
using System.Collections.Generic;
using System.Threading.Tasks;
using Newtonsoft.Json;
using System;

public class NodeNetwork : MonoBehaviour
{
    [SerializeField] private CompassWorldPoseTCT _compassWorldPoseTCT;

    //private const string READ_THREAD_URL = "http://localhost:3000/toranomon/readThread";
    private const string READ_THREAD_URL = "https://api.kuwa-ya.co.jp/toranomon/readThread";
    //private const string CREATE_THREAD_URL = "http://localhost:3000/toranomon/createThread";
    private const string CREATE_THREAD_URL = "https://api.kuwa-ya.co.jp/toranomon/createThread";

    // レスポンス用データ構造
    private class ThreadResponse
    {
        public string status;
        public ThreadResponseDetails[] threads;
    }

    private class ThreadResponseDetails
    {
        public string name;
        public double[] llh;
        public string posted_at_jst;
        public long posted_at;
        public string log;
        public string[] image;
        public string map;
    }

    private void Start()
    {
        // Thread thread = await ReadThreadAsync();
        // string threadString = JsonConvert.SerializeObject(thread, Formatting.Indented);
        // Debug.Log("Read Thread: " + threadString);
    } 

    public async Task<string> CreateThreadAsync(Thread thread)
    {
        Debug.Log("CreateThreadAsync");
        var form = new WWWForm();

        // 位置情報の処理
        double[] llh = new double[3];
        if (thread.LLH != null && thread.LLH.Length == 3) llh = thread.LLH;
        if (llh == null || llh.Length == 0 || (llh.Length == 3 && llh[0] == 0 && llh[1] == 0 && llh[2] == 0))
        {
            // ■■■■　位置情報記録が事前に取得できていない場合、正確な記録が出来ない可能性がある。　■■■■
            Debug.LogWarning("位置情報が未設定のため、現在地を取得します。ログと位置情報が異なる記録となる場合があります。");
            float maxWaitTime = 2.0f;
            float elapsedTime = 0.0f;
            while (elapsedTime < maxWaitTime)
            {
                thread.LLH = _compassWorldPoseTCT.GetCurrentLLH();
                llh = thread.LLH;
                if (llh != null && llh.Length == 3 && (llh[0] != 0 || llh[1] != 0)) break;
                await Task.Delay(500);
                elapsedTime += Time.deltaTime;
            }
            if (llh == null || llh.Length == 0 || (llh.Length == 3 && llh[0] == 0 && llh[1] == 0 && llh[2] == 0))
            {
                Debug.LogWarning("位置情報が取得出来ないため、正確なログが記録できません。");
                llh = new double[3] { 0, 0, 0 };
            }
        }
        // トピックの処理
        // ■■■■　非実装・今後拡張　■■■■

        thread.Topic.Uuid = thread.Uuid;
        thread.Topic.PostedAt = ((DateTimeOffset)DateTime.UtcNow).ToUnixTimeSeconds();

        // コメントセットの処理
        // ■■■■　非実装・今後拡張　■■■■

        // Jsonのシリアライズ・セット
        string json = JsonConvert.SerializeObject(thread);
        form.AddField("json", json);

        // マップの処理
        byte[] mapBytes = thread.Map;
        if (mapBytes != null && mapBytes.Length > 0)
        {
            // ファイル名はサーバー側では無視している。
            form.AddBinaryData("map", mapBytes, "map.dat", "application/octet-stream");
        }

        // 複数画像の処理
        for (int i = 0; i < thread.ARLogSet.ARLogs.Count; i++)
        {
            byte[] imageBytes = thread.ARLogSet.ARLogs[i].Image;
            if (imageBytes != null && imageBytes.Length > 0)
            {
                // ファイル名はサーバー側では無視している。
                form.AddBinaryData("image", imageBytes, "image" + i + ".jpeg", "image/jpeg");
            }
        }

        using (UnityWebRequest www = UnityWebRequest.Post(CREATE_THREAD_URL, form))
        {
            var op = www.SendWebRequest();
            while (!op.isDone) await Task.Yield();
            Debug.Log("CreateThreadAsync End");
            if (www.result == UnityWebRequest.Result.Success)
            {
                return www.downloadHandler.text;
            }
            else
            {
                return www.error;
            }
        }
    }
    public async Task<Thread> ReadThreadAsync()
    {
        string response = await ReadThreadStringAsync();
        ThreadResponse threadResponse = JsonConvert.DeserializeObject<ThreadResponse>(response);
        if (threadResponse == null || threadResponse.status != "success" || threadResponse.threads == null || threadResponse.threads.Length == 0)
        {
            Debug.LogWarning("ReadThreadAsync: No valid thread data.");
            return new Thread();
        }
        string logUrl = threadResponse.threads[0].log;

        // logUrlからJSONデータをダウンロードしてパース
        using (UnityWebRequest logRequest = UnityWebRequest.Get(logUrl))
        {
            var logOp = logRequest.SendWebRequest();
            while (!logOp.isDone) await Task.Yield();

            if (logRequest.result == UnityWebRequest.Result.Success)
            {
                string logJson = logRequest.downloadHandler.text;
                Thread logData = JsonConvert.DeserializeObject<Thread>(logJson);
                return logData;
            }
            else
            {
                Debug.LogWarning("Failed to download log JSON: " + logRequest.error);
                return new Thread();
            }
        }
    }
    public async Task<byte[]> ReadThreadMapAsync(string mapUrl)
    {
        if (string.IsNullOrEmpty(mapUrl))
        {
            Debug.LogWarning("ReadThreadMapAsync: mapUrl is null or empty.");
            return null;
        }

        using (UnityWebRequest mapRequest = UnityWebRequest.Get(mapUrl))
        {
            var mapOp = mapRequest.SendWebRequest();
            while (!mapOp.isDone) await Task.Yield();

            if (mapRequest.result == UnityWebRequest.Result.Success)
            {
                return mapRequest.downloadHandler.data;
            }
            else
            {
                Debug.LogWarning("Failed to download map data: " + mapRequest.error);
                return null;
            }
        }
    }
    public async Task<List<byte[]>> ReadThreadImagesAsync(List<string> imageUrls)
    {
        List<byte[]> images = new List<byte[]>();
        if (imageUrls == null || imageUrls.Count == 0)
        {
            Debug.LogWarning("ReadThreadImagesAsync: imageUrls is null or empty.");
            return images;
        }

        foreach (var imageUrl in imageUrls)
        {
            byte[] imageData = await ReadThreadImageAsync(imageUrl);
            if (imageData != null)
            {
                images.Add(imageData);
            }
            else
            {
                images.Add(null);
            }
        }
        return images;
    }
    public async Task<byte[]> ReadThreadImageAsync(string imageUrl)
    {
        if (string.IsNullOrEmpty(imageUrl))
        {
            Debug.LogWarning("ReadThreadImageAsync: imageUrl is null or empty.");
            return null;
        }

        using (UnityWebRequest imageRequest = UnityWebRequest.Get(imageUrl))
        {
            var imageOp = imageRequest.SendWebRequest();
            while (!imageOp.isDone) await Task.Yield();

            if (imageRequest.result == UnityWebRequest.Result.Success)
            {
                return imageRequest.downloadHandler.data;
            }
            else
            {
                Debug.LogWarning("Failed to download image data: " + imageRequest.error);
                return null;
            }
        }
    }

    public async Task<string> ReadThreadStringAsync()
    {
        var jsonData = new
        {
            type = new string[] { "all" },
            latest = true,
            news = new float[] { 35.70f, 139.60f, 139.56f, 35.66f },
        };
        string json = JsonConvert.SerializeObject(jsonData);

        var request = new UnityWebRequest(READ_THREAD_URL, "POST");
        byte[] bodyRaw = System.Text.Encoding.UTF8.GetBytes(json);
        request.uploadHandler = new UploadHandlerRaw(bodyRaw);
        request.downloadHandler = new DownloadHandlerBuffer();
        request.SetRequestHeader("Content-Type", "application/json");

        var op = request.SendWebRequest();
        while (!op.isDone) await Task.Yield();

        Debug.Log($"status: {request.responseCode}, content-type: {request.GetResponseHeader("Content-Type")}");
        if (request.result == UnityWebRequest.Result.Success)
        {
            string contentType = request.GetResponseHeader("Content-Type");
            if (contentType != null && contentType.Contains("application/json")) return request.downloadHandler.text;
            else return request.downloadHandler.text;
        }
        else
        {
            return request.error;
        }
    }


}