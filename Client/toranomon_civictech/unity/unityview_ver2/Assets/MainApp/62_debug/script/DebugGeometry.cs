using System.Collections;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.UI;

public class DebugGeometry : MonoBehaviour
{

    [SerializeField] private bool _outLog;
    private static bool outLog;

    [SerializeField] private GameObject _debugPointObject;
    [SerializeField] private GameObject _debugLineObject;
    [SerializeField] private GameObject _debugMeshObject;
    [SerializeField] private GameObject _debugTextObject;
    [SerializeField] private GameObject _debugObjects;
    private static GameObject debugPointObject;
    private static GameObject debugLineObject;
    private static GameObject debugMeshObject;
    private static GameObject debugTextObject;
    private static GameObject debugObjects;

    [SerializeField] private Material _debugColorRED;
    [SerializeField] private Material _debugColorYELLOW;
    [SerializeField] private Material _debugColorGREEN;
    [SerializeField] private Material _debugColorCYAN;
    [SerializeField] private Material _debugColorBLUE;
    [SerializeField] private Material _debugColorMAGENTA;
    [SerializeField] private Material _debugColorBLACK;
    [SerializeField] private Material _debugColorWHITE;
    [SerializeField] private Material _debugColorGRAY;

    public static Material debugColorRED;
    public static Material debugColorYELLOW;
    public static Material debugColorGREEN;
    public static Material debugColorCYAN;
    public static Material debugColorBLUE;
    public static Material debugColorMAGENTA;
    public static Material debugColorBLACK;
    public static Material debugColorWHITE;
    public static Material debugColorGRAY;

    private void Awake()
    {
        debugPointObject = _debugPointObject;
        debugLineObject = _debugLineObject;
        debugMeshObject = _debugMeshObject;
        debugTextObject = _debugTextObject;
        debugObjects = _debugObjects;

        debugColorRED = _debugColorRED;
        debugColorYELLOW = _debugColorYELLOW;
        debugColorGREEN = _debugColorGREEN;
        debugColorCYAN = _debugColorCYAN;
        debugColorBLUE = _debugColorBLUE;
        debugColorMAGENTA = _debugColorMAGENTA;
        debugColorBLACK = _debugColorBLACK;
        debugColorWHITE = _debugColorWHITE;
        debugColorGRAY = _debugColorGRAY;

        outLog = _outLog;
    }

    public static void ResetDebugObjects()
    {
        if (debugObjects.transform.childCount > 0)
        {
            for (int i = debugObjects.transform.childCount - 1; i >= 0; i--)
            {
                GameObject child = debugObjects.transform.GetChild(i).gameObject;
                Destroy(child);
            }
        }
    }
    public static async Task ResetDebugObjectsAsync()
    {
        ResetDebugObjects();
        await Task.Yield();
    } 

    public static void MakePointObject(Vector3 vec, string name, Transform parent) => MakePointObject(vec, name, null, parent);
    public static void MakePointObject(Vector3 vec, string name = null, Material material = null, Transform parent = null)
    {
        GameObject gameObject;
        if (parent == null)
            gameObject = Instantiate(debugPointObject, vec, Quaternion.identity, debugObjects.transform);
        else
            gameObject = Instantiate(debugPointObject, vec, Quaternion.identity, parent);

        if (!string.IsNullOrEmpty(name))
            gameObject.name = name;
        if (material != null)
            gameObject.transform.GetComponent<Renderer>().material = material;
    }

    public static void MakeLineObject(Vector3 vecA, Vector3 vecB, string name, Transform parent) => MakeLineObject(vecA, vecB, name, null, parent);
    public static void MakeLineObject(Vector3 vecA, Vector3 vecB, string name = null, Material material = null, Transform parent = null)
    {
        GameObject tempoObject;
        Transform useParent = parent ?? debugObjects.transform;
        tempoObject = Instantiate(debugLineObject, vecA, Quaternion.identity, useParent);
        tempoObject.transform.LookAt(vecB);
        float vecLength = Vector3.Distance(vecA, vecB);
        if (float.IsNaN(vecLength))
        {
            if (outLog) Debug.Log($"[DEBGU GEOMETRY] It got error vector distance from name:{name} vecA:{vecA}, vecB:{vecB}.");
            return;
        }
        tempoObject.transform.localScale = new Vector3(1.0f, 1.0f, vecLength);
        if (!string.IsNullOrEmpty(name))
            tempoObject.name = name;
        if (material != null)
            tempoObject.transform.GetChild(0).GetComponent<Renderer>().material = material;
    }

    public static void MakeCubeObject(Vector3 pos, Vector3 scl, string name, Color clr) => MakeCubeObject(pos, scl, name, null, clr, null);
    public static void MakeCubeObject(Vector3 pos, Vector3 scl, string name, Color clr, Transform parent) => MakeCubeObject(pos, scl, name, null, clr, parent);
    public static void MakeCubeObject(Vector3 pos, Vector3 scl, string name = null, Material material = null, Transform parent = null) => MakeCubeObject(pos, scl, name, material, null, parent);
    public static void MakeCubeObject(Vector3 pos, Vector3 scl, string name = null, Material material = null, Color? clr = null, Transform parent = null)
    {
        GameObject cube = GameObject.CreatePrimitive(PrimitiveType.Cube);
        cube.name = name;
        cube.transform.localPosition = pos;
        cube.transform.localScale = scl;
        if (material != null) cube.GetComponent<Renderer>().material = material;
        if (clr.HasValue) cube.GetComponent<Renderer>().material.color = clr.Value;
        cube.transform.parent = parent ?? debugObjects.transform;
    }

    public static void MakeTextObject(Vector3 vec, string str = null, string name = null, Transform parent = null)
    {
        GameObject tempoObject = Instantiate(debugTextObject, vec, Quaternion.identity, parent ?? debugObjects.transform);
        if (!string.IsNullOrEmpty(name))
            tempoObject.name = name;
        Text tempoText = tempoObject.transform.GetChild(0).gameObject.GetComponent<Text>();
        tempoText.text = str;
    }

    public static void MakePointObjectFromList(List<Vector3> vecs, string name = null) => MakePointObjectFromList(vecs, name, null, null, null);
    public static void MakePointObjectFromList(List<Vector3> vecs, string name = null, List<Material> materials = null, Transform parent = null) => MakePointObjectFromList(vecs, name, null, materials, parent);
    public static void MakePointObjectFromList(List<Vector3> vecs, string name = null, Material material = null, List<Material> materials = null, Transform parent = null)
    {
        if (vecs == null || vecs.Count == 0)
        {
            if (outLog) Debug.Log($"[DEBGU GEOMETRY] It couldn't get List at {(name ?? "MakePointObjectFromList")}. Please check it.");
            return;
        }

        Transform useParent = parent ?? debugObjects.transform;

        if (string.IsNullOrEmpty(name) && material == null && materials == null)
        {
            for (int i = 0; i < vecs.Count; i++)
            {
                MakePointObject(vecs[i], $"{i}");
            }
            return;
        }

        GameObject tempoObject = null;
        if (!string.IsNullOrEmpty(name))
        {
            tempoObject = new GameObject();
            tempoObject.name = name;
            tempoObject.transform.localPosition = Vector3.zero;
            tempoObject.transform.localScale = Vector3.one;
            tempoObject.transform.parent = useParent;
            useParent = tempoObject.transform;
        }

        if (materials != null)
            for (int i = 0; i < vecs.Count; i++)
                MakePointObject(vecs[i], $"{name}-{i}", materials[i], useParent);
        else if (material != null)
            for (int i = 0; i < vecs.Count; i++)
                MakePointObject(vecs[i], $"{name}-{i}", material, useParent);
        else
            for (int i = 0; i < vecs.Count; i++)
                MakePointObject(vecs[i], $"{name}-{i}", useParent);
    }

    //if close is true, it will connect the last point to the first point
    public static void MakeLineObjectFromList(List<Vector3> vecs, string name) => MakeLineObjectFromList(vecs, name, null, null, null, true);
    public static void MakeLineObjectFromList(List<Vector3> vecs, string name = null, bool close = true) => MakeLineObjectFromList(vecs, name, null, null, null, close);
    public static void MakeLineObjectFromList(List<Vector3> vecs, string name = null, Material material = null) => MakeLineObjectFromList(vecs, name, material, null, null, true);
    public static void MakeLineObjectFromList(List<Vector3> vecs, string name = null, Material material = null, bool close = true) => MakeLineObjectFromList(vecs, name, material, null, null, close);
    public static void MakeLineObjectFromList(List<Vector3> vecs, string name = null, Material material = null, Transform parent = null, bool close = true) => MakeLineObjectFromList(vecs, name, material, null, parent, close);
    public static void MakeLineObjectFromList(List<Vector3> vecs, string name = null, List<Material> materials = null, Transform parent = null, bool close = true) => MakeLineObjectFromList(vecs, name, null, materials, parent, close);
    public static void MakeLineObjectFromList(List<Vector3> vecs, string name = null, Material material = null, List<Material> materials = null, Transform parent = null, bool close = true)
    {
        if (vecs == null || vecs.Count == 0)
        {
            if (outLog) Debug.Log($"[DEBGU GEOMETRY] It couldn't get List at {(name ?? "MakeLineObjectFromList")}. Please check it.");
            return;
        }

        Transform useParent = parent ?? debugObjects.transform;

        // 単純なラインのみ
        if (string.IsNullOrEmpty(name) && material == null && materials == null && close)
        {
            for (int i = 0; i < vecs.Count; i++)
            {
                if (i < vecs.Count - 1)
                    MakeLineObject(vecs[i], vecs[i + 1]);
                else
                    MakeLineObject(vecs[i], vecs[0]);
            }
            return;
        }

        GameObject tempoObject = null;
        if (!string.IsNullOrEmpty(name))
        {
            tempoObject = new GameObject();
            tempoObject.name = name;
            tempoObject.transform.localPosition = Vector3.zero;
            tempoObject.transform.localScale = Vector3.one;
            tempoObject.transform.parent = useParent;
            useParent = tempoObject.transform;
        }

        int count = vecs.Count;
        for (int i = 0; i < count; i++)
        {
            int next = (i < count - 1) ? i + 1 : (close ? 0 : -1);
            if (next == -1) break;

            string childName = !string.IsNullOrEmpty(name) ? $"{name}-{i}" : null;

            if (materials != null)
                MakeLineObject(vecs[i], vecs[next], childName, materials[i], useParent);
            else if (material != null)
                MakeLineObject(vecs[i], vecs[next], childName, material, useParent);
            else if (!string.IsNullOrEmpty(name))
                MakeLineObject(vecs[i], vecs[next], childName, useParent);
            else
                MakeLineObject(vecs[i], vecs[next]);
        }
    }

    public static void MakeTextObjectFromList(List<Vector3> vecs, List<string> strs, string name = null)
    {
        if (vecs == null || vecs.Count == 0)
        {
            if (outLog) Debug.Log($"[DEBGU GEOMETRY] It couldn't get List at {(name ?? "MakeTextObjectFromList")}. Please check it.");
            return;
        }

        Transform useParent = debugObjects.transform;

        if (string.IsNullOrEmpty(name))
        {
            for (int i = 0; i < vecs.Count; i++)
            {
                MakeTextObject(vecs[i], strs[i]);
            }
        }
        else
        {
            GameObject tempoObject = new GameObject();
            tempoObject.name = name;
            tempoObject.transform.localPosition = Vector3.zero;
            tempoObject.transform.localScale = Vector3.one;
            tempoObject.transform.parent = useParent;

            for (int i = 0; i < vecs.Count; i++)
            {
                MakeTextObject(vecs[i], strs[i], name, tempoObject.transform);
            }
        }
    }


    public static void MakeCubeObjectFromList(List<Vector3> pos, Vector3 scl, string name, List<Color> clr = null, Material material = null, Transform parent = null)
    {
        if (pos == null || pos.Count == 0)
        {
            if (outLog) Debug.Log($"[DEBGU GEOMETRY] It couldn't get List at {name}. Please check it.");
            return;
        }

        Transform useParent = parent ?? debugObjects.transform;

        GameObject tempoObject = new GameObject();
        tempoObject.name = name;
        tempoObject.transform.localPosition = Vector3.zero;
        tempoObject.transform.localScale = Vector3.one;
        tempoObject.transform.parent = useParent;

        for (int i = 0; i < pos.Count; i++)
        {
            string childName = $"{name}-{i}";
            if (clr != null)
                MakeCubeObject(pos[i], scl, childName, clr[i], tempoObject.transform);
            else if (material != null)
                MakeCubeObject(pos[i], scl, childName, material, tempoObject.transform);
        }
    }

    public static GameObject GenerateMeshObject(Mesh mesh, string name)
    {

        //◆◆一時利用の変数
        GameObject returnObj;

        //プレファブオブジェクトをコピーして生成
        returnObj = Instantiate(debugMeshObject, Vector3.zero, Quaternion.identity);
        //スケールを親依存からリセット再設定
        returnObj.transform.localScale = new Vector3(1, 1, 1);
        //スクリプト上に作成されたメッシュを割り当て
        returnObj.GetComponent<MeshFilter>().sharedMesh = mesh;
        //マテリアルを割り当て
        //returnObj.GetComponent<Renderer>().material = material;
        //オブジェクトに名前を入れる
        returnObj.name = name;
        //オブジェクトの親子関係を整理
        returnObj.transform.parent = debugObjects.transform;

        return returnObj;
    }


}
