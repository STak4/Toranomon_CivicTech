// Origin script

using System;
using System.Collections.Generic;
using UnityEngine;
using Newtonsoft.Json;

public class NodeStoreModels
{
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
        // AR記録データ
        [JsonProperty("arlog")]
        public ARLog ARLog { get; set; } = new ARLog();
        // 画像のバイナリデータ
        [JsonIgnore] // JSON出力から除外
        public byte[] Image { get; set; } = Array.Empty<byte>();
        // マップのバイナリデータ
        [JsonIgnore] // JSON出力から除外
        public byte[] Map { get; set; } = Array.Empty<byte>();

        // ◆附帯データのリソースURL一覧
        // 各種紐づきデータのリソースURL一覧 (CommentSetのJSON, ARLogのJSON, 画像URL, DeviceMappingデータURLなど)
        [JsonProperty("resources")]
        public ResourceUrls Resources { get; set; } = new ResourceUrls();
    }

    // ◆◆起案に対するコメントのデータ構造：Threadからはcomment_setにて取得・紐付けを想定
    public class CommentSet
    {
        [JsonProperty("uuid")]
        public string Uuid { get; set; } = string.Empty;
        [JsonProperty("comments")]
        public List<MessageUnit> Comments { get; set; } = new List<MessageUnit>();
    }

    // ◆◆AR記録のデータ構造：基本的にUnity-ARのみで利用想定
    public class ARLog
    {
        [JsonProperty("uuid")]
        public string Uuid { get; set; } = string.Empty;
        [JsonProperty("camera_local_position")]
        public double[] CameraLocalPosition { get; set; } = new double[3];
        [JsonProperty("camera_local_euler_angles")]
        public double[] CameraLocalEulerAngles { get; set; } = new double[3];
        [JsonProperty("camera_local_scale")]
        public double[] CameraLocalScale { get; set; } = new double[3];

        public (Vector3 position, Vector3 eulerAngles, Vector3 scale) ToUnityVectors()
        {
            Vector3 position = new Vector3((float)CameraLocalPosition[0], (float)CameraLocalPosition[1], (float)CameraLocalPosition[2]);
            Vector3 eulerAngles = new Vector3((float)CameraLocalEulerAngles[0], (float)CameraLocalEulerAngles[1], (float)CameraLocalEulerAngles[2]);
            Vector3 scale = new Vector3((float)CameraLocalScale[0], (float)CameraLocalScale[1], (float)CameraLocalScale[2]);
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
            CameraLocalPosition = position;
            CameraLocalEulerAngles = eulerAngles;
            CameraLocalScale = scale;
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

    // thread_url : 当該データのURLを念のため保持
    // comment_url : コメントデータのURL、CommentSetにパース済み(json構造)で提供するかは検討（対データ量）
    // arlog_url : ARログデータのURL、ARLogにパース済み(json構造)で提供するかは検討（対データ量）
    // image_url : 画像データのURL、Imageにパース済み(byte[])で提供するかは検討（対データ量）
    // map_url : マップデータのURL、Mapにパース済み(byte[])で提供するかは検討（対データ量）
    public class ResourceUrls
    {
        [JsonProperty("thread_url")]
        public string ThreadUrl { get; set; } = string.Empty;
        [JsonProperty("comment_url")]
        public string CommentUrl { get; set; } = string.Empty;
        [JsonProperty("arlog_url")]
        public string ArLogUrl { get; set; } = string.Empty;
        [JsonProperty("image_url")]
        public string ImageUrl { get; set; } = string.Empty;
        [JsonProperty("map_url")]
        public string MapUrl { get; set; } = string.Empty;
    }

    public static string ExportThreadJson(Thread thread) => JsonConvert.SerializeObject(thread, Formatting.Indented);

    public static string ExportSampleThreadJson(double[] llh = null)
    {
        string staticUuid = Guid.NewGuid().ToString();
        double[] currentLlh = llh;

        ARLog aRLog = new ARLog();
        aRLog.Uuid = staticUuid;
        aRLog.ApplyFromTransform(Camera.main.transform);

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
                Uuid =  staticUuid,
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
                    }
                }
            },
            ARLog = aRLog,
            Resources = new ResourceUrls
            {
                ThreadUrl = $"https://example.com/threads/{staticUuid}.json",
                CommentUrl = $"https://example.com/comments/{staticUuid}.json",
                ArLogUrl = $"https://example.com/arlogs/{staticUuid}.json",
                ImageUrl = $"https://example.com/images/{staticUuid}.png",
                MapUrl = $"https://example.com/maps/{staticUuid}.dat"
            }
        };
        return JsonConvert.SerializeObject(thread, Formatting.Indented);
    }

}
