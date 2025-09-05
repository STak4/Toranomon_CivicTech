// Origin script

using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;
using Newtonsoft.Json;

public class NodeStoreModels
{
    public static async Task<Thread> DeserializeThreadJsonFromFile(string filePath)
    {
        if (!File.Exists(filePath))
        {
            Debug.LogError($"File not found: {filePath}");
            return new Thread();
        }
        string json = await File.ReadAllTextAsync(filePath);
        return DeserializeThreadJson(json);
    }
    public static Thread DeserializeThreadJson(string json) => JsonConvert.DeserializeObject<Thread>(json);



    public static async Task SaveThread(Thread thread)
    {
        string folderPath;
#if UNITY_ANDROID
        folderPath = Path.Combine(Application.persistentDataPath);
#elif UNITY_IOS
        folderPath = Path.Combine(Application.persistentDataPath, "Documents");
#else
        folderPath = Path.Combine(Application.persistentDataPath);
#endif
        ResourceUrls resources = new ResourceUrls();
        string threadUuid = thread.Uuid;
        int arLogCount = thread.ARLogSet.ARLogs.Count;

        string logFilePath = Path.Combine(folderPath, "logs", $"{threadUuid}.json");
        string mapFilePath = Path.Combine(folderPath, "maps", $"{threadUuid}.dat");
        List<string> imageFilePaths = new List<string>();
        for (int i = 0; i < arLogCount; i++)
        {
            string imageFilePath = Path.Combine(folderPath, "images", $"{thread.ARLogSet.ARLogs[i].Uuid}.jpg");
            imageFilePaths.Add(imageFilePath);
        }
        resources.LogUrl = logFilePath;
        resources.MapUrl = mapFilePath;
        resources.ImageUrls = imageFilePaths;
        thread.Resources = resources;

        string json = SerializeThreadJson(thread);
        byte[] jsonBytes = Encoding.UTF8.GetBytes(json);
        byte[] mapBytes = thread.Map;

        if (!Directory.Exists(folderPath)) Directory.CreateDirectory(folderPath);
        if (!Directory.Exists(Path.Combine(folderPath, "logs"))) Directory.CreateDirectory(Path.Combine(folderPath, "logs"));
        if (!Directory.Exists(Path.Combine(folderPath, "maps"))) Directory.CreateDirectory(Path.Combine(folderPath, "maps"));
        if (!Directory.Exists(Path.Combine(folderPath, "images"))) Directory.CreateDirectory(Path.Combine(folderPath, "images"));

        try
        {
            await File.WriteAllBytesAsync(logFilePath, jsonBytes);
            await File.WriteAllBytesAsync(mapFilePath, mapBytes);
        }
        catch (Exception ex)
        {
            Debug.LogError($"Failed to save screenshot: {ex.Message}");
        }
    }
    public static string SerializeThreadJson(Thread thread) => JsonConvert.SerializeObject(thread, Formatting.Indented);

    public static string ExportSampleThreadJson(double[] llh = null)
    {
        string staticUuid = Guid.NewGuid().ToString();
        double[] currentLlh = llh;

        ARLogUnit aRLogA = new ARLogUnit();
        aRLogA.Uuid = Guid.NewGuid().ToString();
        aRLogA.ApplyFromTransform(Camera.main.transform);

        ARLogUnit aRLogB = new ARLogUnit();
        aRLogB.Uuid = Guid.NewGuid().ToString();
        aRLogB.ApplyFromTransform(Camera.main.transform);

        Thread thread = new Thread
        {
            Uuid = staticUuid,
            LLH = currentLlh,
            Topic = new MessageUnit
            {
                Uuid = staticUuid,
                UserId = "user001",
                PostedBy = "山田太郎",
                PostedAt = DateTimeOffset.UtcNow.ToUnixTimeSeconds(),
                Category = "街の改善提案",
                Comment = "虎ノ門から新橋までの道について、とても閑散としています。どちらもそれぞれに個性があるいい街なのですが、繋がりが生まれると、もっと良い街になると思います。",
                Opinions = new OpinionScales
                {
                    Agree = new[] { "user002", "user003" },
                    Disagree = new[] { "user004" }
                }
            },
            CommentSet = new CommentSet
            {
                Comments = new List<MessageUnit>
                {
                    new MessageUnit
                    {
                        Uuid = Guid.NewGuid().ToString(),
                        UserId = "user005",
                        PostedBy = "佐藤花子",
                        PostedAt = DateTimeOffset.UtcNow.ToUnixTimeSeconds(),
                        Category = "意見",
                        Comment = "賛成です。 もっと人が集まる場所が増えるといいですね。",
                        Opinions = new OpinionScales { Agree = new[] { "user006" } }
                    },
                    new MessageUnit
                    {
                        Uuid = Guid.NewGuid().ToString(),
                        UserId = "user008",
                        PostedBy = "菊地次郎",
                        PostedAt = DateTimeOffset.UtcNow.ToUnixTimeSeconds(),
                        Category = "意見",
                        Comment = "どうなんでしょうか、もう少し具体的な意見が欲しいですね。",
                        Opinions = new OpinionScales { Neutral = new[] { "user006" } }
                    }

                }
            },
            ARLogSet = new ARLogSet
            {
                ARLogs = new List<ARLogUnit> { aRLogA, aRLogB },
            },
            Resources = new ResourceUrls
            {
                LogUrl = $"https://example.com/logs/{staticUuid}.json",
                ImageUrls = new List<string>
                {
                    $"https://example.com/images/{aRLogA.Uuid}.png",
                    $"https://example.com/images/{aRLogB.Uuid}.png"
                },
                MapUrl = $"https://example.com/maps/{staticUuid}.dat"
            }
        };
        return JsonConvert.SerializeObject(thread, Formatting.Indented);
    }
}

// ◆◆起案のデータ構造：各種紐づきデータはxxxx_urlにて保存・取得を想定
public class Thread
{
    // ◆メインデータ
    // スレッドの一意な識別子(APIで参照・削除・更新等に利用)
    [JsonProperty("uuid")]
    public string Uuid { get; set; } = string.Empty;
    // 位置座標把握用データ（Latitude - Longitude - Altitude）
    [JsonProperty("llh")]
    public double[] LLH { get; set; } = Array.Empty<double>();
    // トピック本体
    [JsonProperty("topic")]
    public MessageUnit Topic { get; set; } = new MessageUnit();

    // ◆附帯データ
    // トピックに対する返答コメントセット
    [JsonProperty("comment_set")]
    public CommentSet CommentSet { get; set; } = new CommentSet();

    // AR記録データコレクション
    [JsonProperty("arlog_set")]
    public ARLogSet ARLogSet { get; set; } = new ARLogSet();

    // マップのバイナリデータ
    [JsonIgnore] // JSON出力から除外
    public byte[] Map { get; set; } = Array.Empty<byte>();

    // ◆附帯データのリソースURL一覧
    // 各種紐づきデータのリソースURL一覧 (CommentSetのJSON, ARLogのJSON, 画像URL, DeviceMappingデータURLなど)
    [JsonProperty("resources")]
    public ResourceUrls Resources { get; set; } = new ResourceUrls();
}

public class ARLogSet
{
    [JsonProperty("arlogs")]
    public List<ARLogUnit> ARLogs { get; set; } = new List<ARLogUnit>();
}

// ◆◆起案に対するコメントのデータ構造：Threadからはcomment_setにて取得・紐付けを想定
public class CommentSet
{
    [JsonProperty("comments")]
    public List<MessageUnit> Comments { get; set; } = new List<MessageUnit>();
}

// ◆◆AR記録のデータ構造：基本的にUnity-ARのみで利用想定
public class ARLogUnit
{
    [JsonProperty("uuid")]
    public string Uuid { get; set; } = string.Empty;
    [JsonProperty("local_position")]
    public double[] LocalPosition { get; set; } = new double[3];
    [JsonProperty("local_euler_angles")]
    public double[] LocalEulerAngles { get; set; } = new double[3];
    [JsonProperty("local_scale")]
    public double[] LocalScale { get; set; } = new double[3];
    // 画像のバイナリデータ
    [JsonIgnore] // JSON出力から除外
    public byte[] Image { get; set; } = Array.Empty<byte>();

    public ARLogUnit()
    {
        Uuid = string.Empty;
        LocalPosition = new double[3];
        LocalEulerAngles = new double[3];
        LocalScale = new double[3];
    }
    public ARLogUnit(Vector3 position, Vector3 eulerAngles, Vector3 scale)
    {
        Uuid = string.Empty;
        LocalPosition = new double[] { position.x, position.y, position.z };
        LocalEulerAngles = new double[] { eulerAngles.x, eulerAngles.y, eulerAngles.z };
        LocalScale = new double[] { scale.x, scale.y, scale.z };
    }
    // 下記は重くなるので利用を避ける
    // public void SetImage(byte[] image) => Image = image;
    // public void SetImage(Texture2D texture) { if (texture != null) Image = texture.EncodeToJPG(); }

    public (Vector3 position, Vector3 eulerAngles, Vector3 scale) ToUnityVectors()
    {
        Vector3 position = new Vector3((float)LocalPosition[0], (float)LocalPosition[1], (float)LocalPosition[2]);
        Vector3 eulerAngles = new Vector3((float)LocalEulerAngles[0], (float)LocalEulerAngles[1], (float)LocalEulerAngles[2]);
        Vector3 scale = new Vector3((float)LocalScale[0], (float)LocalScale[1], (float)LocalScale[2]);
        return (position, eulerAngles, scale);
    }
    public (double[] position, double[] rotation, double[] scale) ToDoubleArrays(Transform transform)
    {
        double[] localPosition = new double[] { transform.localPosition.x, transform.localPosition.y, transform.localPosition.z };
        double[] localEulerAngles = new double[] { transform.localEulerAngles.x, transform.localEulerAngles.y, transform.localEulerAngles.z };
        double[] localScale = new double[] { transform.localScale.x, transform.localScale.y, transform.localScale.z };
        return (localPosition, localEulerAngles, localScale);
    }
    public void ApplyToTransform(Transform transform)
    {
        var (position, eulerAngles, scale) = ToUnityVectors();
        transform.localPosition = position;
        transform.localEulerAngles = eulerAngles;
        transform.localScale = scale;
    }
    public void ApplyFromTransform(Transform transform)
    {
        var (position, eulerAngles, scale) = ToDoubleArrays(transform);
        LocalPosition = position;
        LocalEulerAngles = eulerAngles;
        LocalScale = scale;
    }
}

// ◆◆起案とコメントの共通データ構造
public class MessageUnit
{
    [JsonProperty("uuid")]
    public string Uuid { get; set; } = string.Empty;
    [JsonProperty("user_id")]
    public string UserId { get; set; } = string.Empty;
    [JsonProperty("posted_by")]
    public string PostedBy { get; set; } = string.Empty;
    [JsonProperty("posted_at")]
    public long PostedAt { get; set; } = 0;
    [JsonProperty("category")]
    public string Category { get; set; } = string.Empty;
    [JsonProperty("comment")]
    public string Comment { get; set; } = string.Empty;
    [JsonProperty("opinions")]
    public OpinionScales Opinions { get; set; } = new OpinionScales();

    // 補助プロパティ: UNIX時間→日本時間(DateTime)
    [JsonIgnore] // JSON出力から除外
    public DateTime PostedAtJST => DateTimeOffset.FromUnixTimeSeconds(PostedAt).UtcDateTime.AddHours(9);
}
// ◆◆賛成・反対の意見一式(string配列内にuser_idを入れる想定　→　重複回避)
public class OpinionScales
{
    [JsonProperty("strongly_disagree")]
    public string[] StronglyDisagree { get; set; } = Array.Empty<string>();
    [JsonProperty("disagree")]
    public string[] Disagree { get; set; } = Array.Empty<string>();
    [JsonProperty("neutral")]
    public string[] Neutral { get; set; } = Array.Empty<string>();
    [JsonProperty("agree")]
    public string[] Agree { get; set; } = Array.Empty<string>();
    [JsonProperty("strongly_agree")]
    public string[] StronglyAgree { get; set; } = Array.Empty<string>();
}


// log_url : 当該データのURLを念のため保持
// image_url : 画像データのURL
// map_url : マップデータのURL
public class ResourceUrls
{
    [JsonProperty("log_url")]
    public string LogUrl { get; set; } = string.Empty;
    [JsonIgnore] 
    public string LogFilePath { get; set; } = string.Empty;
    [JsonProperty("image_url")]
    public List<string> ImageUrls { get; set; } = new List<string>();
    [JsonIgnore] 
    public List<string> ImageFilePaths { get; set; } = new List<string>();
    [JsonProperty("map_url")]
    public string MapUrl { get; set; } = string.Empty;
    [JsonIgnore] 
    public string MapFilePath { get; set; } = string.Empty;
}


// comment_url : コメントデータのURL、CommentSetにパース済み(json構造)で提供するかは検討（対データ量）
// arlog_url : ARログデータのURL、ARLogにパース済み(json構造)で提供するかは検討（対データ量）
/*
    [JsonProperty("comment_url")]
    public string CommentUrl { get; set; } = string.Empty;
    [JsonProperty("arlog_url")]
    public string ArLogUrl { get; set; } = string.Empty;
*/