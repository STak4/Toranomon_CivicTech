using UnityEngine;
using UnityEngine.Networking;
using System.IO;
using System.Collections.Generic;
using System.Threading.Tasks;
using Newtonsoft.Json;
using System.Threading;

public class NodeDebugClass : MonoBehaviour
{
    [SerializeField] private CompassWorldPoseTCT _compassWorldPoseTCT;

    private void Start()
    {
        _ = OutputSampleJson();
    }

    // レスポンス用データ構造
    private class ThreadResponse
    {
        public string status;
        public ThreadUrl[] threads;
    }

    private class ThreadUrl
    {
        public string name;
        public string log;
        public string image;
        public string map;
    }

    private async Task OutputSampleJson()
    {
        await Task.Delay(3000);

        double[] llh = new double[3]{
            _compassWorldPoseTCT.CameraHelper.Latitude,
            _compassWorldPoseTCT.CameraHelper.Longitude,
            _compassWorldPoseTCT.CameraHelper.Altitude
        };
        string json = NodeStoreModels.ExportSampleThreadJson(llh);

        Debug.Log(json);

        string imagePathA = Path.Combine(Application.persistentDataPath, "sample1.jpg");
        string imagePathB = Path.Combine(Application.persistentDataPath, "sample2.jpg");
        string imagePathC = Path.Combine(Application.persistentDataPath, "sample3.jpg");
        List<string> imagePaths = new List<string> { imagePathA, imagePathB, imagePathC };
        string mapPath = Path.Combine(Application.persistentDataPath, "map.dat");
        string baseUrl = "http://localhost:3000/toranomon/";
        //string baseUrl = "https://api.kuwa-ya.co.jp/toranomon/";
        string apiCreateUrl = baseUrl + "createThread";
        string apiReadUrl = baseUrl + "readThread";

        string createResponse = await CreateThreadAsync(apiCreateUrl, json, imagePaths, mapPath);
        string readResponse = await ReadThreadAsync(apiReadUrl);

        // JSONフォーマット整形
        string formattedCreate = FormatJsonIfPossible(createResponse);
        string formattedRead = FormatJsonIfPossible(readResponse);

        Debug.Log("Create Response: " + formattedCreate);
        Debug.Log("Read Response: " + formattedRead);

        // logのURL一覧取得
        string[] logUrls = GetLogUrlsFromResponse(readResponse);

        if (logUrls.Length > 0)
        {
            string threadLogString = await DownloadThreadLogAsync(logUrls[0]);
            Thread threadData = JsonConvert.DeserializeObject<Thread>(threadLogString);
            string formattedThreadLog = JsonConvert.SerializeObject(threadData, Formatting.Indented);
            if (threadLogString != null)
                Debug.Log("取得したThreadLog: " + formattedThreadLog);
            else
                Debug.LogWarning("ThreadLogの取得または変換に失敗しました");
        }
    }

    private async Task<string> DownloadThreadLogAsync(string url)
    {
        using (UnityWebRequest www = UnityWebRequest.Get(url))
        {
            var op = www.SendWebRequest();
            while (!op.isDone) await Task.Yield();
            if (www.result == UnityWebRequest.Result.Success)
            {
                try { return www.downloadHandler.text; }
                catch { return www.error; }
            }
            else { return www.error; }
        }
    }

    private string[] GetLogUrlsFromResponse(string json)
    {
        if (string.IsNullOrEmpty(json)) return new string[0];
        try
        {
            var response = JsonConvert.DeserializeObject<ThreadResponse>(json);
            if (response?.threads == null) return new string[0];
            var logUrls = new List<string>();
            foreach (var thread in response.threads)
            {
                if (!string.IsNullOrEmpty(thread.log)) logUrls.Add(thread.log);
            }
            return logUrls.ToArray();
        }
        catch
        {
            return new string[0];
        }
    }

    private string FormatJsonIfPossible(string json)
    {
        if (string.IsNullOrEmpty(json)) return json;
        try
        {
            var parsed = JsonConvert.DeserializeObject(json);
            return JsonConvert.SerializeObject(parsed, Formatting.Indented);
        }
        catch
        {
            return json;
        }
    }

    public async Task<string> CreateThreadAsync(string url, string json, List<string> imagePaths, string mapPath)
    {
        var form = new WWWForm();
        form.AddField("json", json);

        // 複数画像対応
        for (int i = 0; i < imagePaths.Count; i++)
        {
            string imagePath = imagePaths[i];
            if (File.Exists(imagePath))
            {
                form.AddBinaryData("image", File.ReadAllBytes(imagePath), Path.GetFileName(imagePath), "image/jpeg");
            }
        }

        if (File.Exists(mapPath))
            form.AddBinaryData("map", File.ReadAllBytes(mapPath), "map.dat", "application/octet-stream");

        using (UnityWebRequest www = UnityWebRequest.Post(url, form))
        {
            var op = www.SendWebRequest();
            while (!op.isDone) await Task.Yield();
            if (www.result == UnityWebRequest.Result.Success) return www.downloadHandler.text;
            else return www.error;
        }
    }

    public async Task<string> ReadThreadAsync(string url)
    {
        var jsonData = new
        {
            type = new string[] { "all" },
            uuid = new string[] { }
        };
        string json = JsonConvert.SerializeObject(jsonData);

        var request = new UnityWebRequest(url, "POST");
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
