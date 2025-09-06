using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraManager : MonoBehaviour
{
    public static CameraManager Instance { set; get; }

    private const float CAMERA_MAX_DISTANCE = 3000.0f;
    private const float CAMERA_MIN_DISTANCE = 50.0f;

    //◆◆データの指定
    [SerializeField] private GameObject _cameras;
    private static Camera[] cameras;

    //◆◆カメラ操作関係（フォーカス位置固定）
    private static Transform[] camerasTransform; //position
    private static Transform[] camerasParentTransform; //rotation
    private static Vector3[] camerasFocusedPosition;
    private static Vector3[] camerasCurrentPosition;
    private static Vector3[] camerasParentFocusedEulerAngles;
    private static Vector3[] camerasParentCurrentEulerAngles;

    //◆◆移動・回転管理用基準データ
    private static Vector3 rotationBaseAngle;
    private static Vector3 moveBasePosition;

    //◆◆カメラRay関係
    public static event Action<Vector2, Vector3, Vector3> CameraRayAction;

    //◆◆カメラ操作関係（フォーカス位置移動）
    private static int cameraNum = 0;

    private void Awake()
    {
        if (Instance == null) Instance = this;
        else Destroy(this);

        //◆◆カメラ位置移動関係データセット
        //int cameraCount = _cameras.gameObject.transform.childCount;
        int cameraCount = 1; // ■■変更■■
        cameras = new Camera[cameraCount];
        camerasTransform = new Transform[cameraCount];
        camerasParentTransform = new Transform[cameraCount];
        camerasFocusedPosition = new Vector3[cameraCount];
        camerasCurrentPosition = new Vector3[cameraCount];
        camerasParentFocusedEulerAngles = new Vector3[cameraCount];
        camerasParentCurrentEulerAngles = new Vector3[cameraCount];

        //◆◆カメラ位置固定関係データセット
        for (int i = 0; i < cameras.Length; i++)
        {
            //GameObject cameraObject = _cameras.transform.GetChild(i).GetChild(0).gameObject;
            GameObject cameraObject = _cameras; // ■■変更■■
            cameras[i] = cameraObject.GetComponent<Camera>();
            camerasTransform[i] = cameraObject.transform;
            camerasParentTransform[i] = cameraObject.transform.parent.transform;
            camerasFocusedPosition[i] = camerasTransform[i].localPosition;
            camerasCurrentPosition[i] = camerasTransform[i].localPosition;
            camerasParentFocusedEulerAngles[i] = camerasParentTransform[i].localEulerAngles;
            camerasParentCurrentEulerAngles[i] = camerasParentTransform[i].localEulerAngles;
        }

        //◆◆ラープ処理
        StartCoroutine(LerpVector());

    }

    private void Start()
    {
        // 移動アクション
        // MouseManager.DragStartAction += CameraBasePositionSet;
        MouseManager.SelectAction += CameraRaySelect;
        // MouseManager.DragAction += CameraMove;
        // MouseManager.MouseWheelAction += CameraZoom;
        // MouseManager.MultiTouchAction += CameraZoom;
    }

    //◆◆Lerpによるカメラ位置調整処理
    private IEnumerator LerpVector()
    {
        while (true)
        {
            for (int i = 0; i < cameras.Length; i++)
            {
                camerasCurrentPosition[i] = Vector3.Lerp(camerasCurrentPosition[i], camerasFocusedPosition[i], 0.1f);
                camerasParentCurrentEulerAngles[i] = Vector3.Lerp(camerasParentCurrentEulerAngles[i], camerasParentFocusedEulerAngles[i], 0.1f);
                camerasTransform[i].localPosition = camerasCurrentPosition[i];
                camerasParentTransform[i].localEulerAngles = camerasParentCurrentEulerAngles[i];
            }
            yield return new WaitForSeconds(0.01f);
        }
    }

    /* ◆◆◆◆下記より共通動作関数◆◆◆◆ */
    private static void CameraRaySelect(Vector2 pressVec)
    {
        // Debug.Log("camera manager select : " + pressVec.ToString());    //■■■■DEBUG LOG■■■■
        Ray ray= cameras[cameraNum].ScreenPointToRay(pressVec);
        // Debug.Log("ray origin : " + ray.origin.ToString() + ", direction : " + ray.direction.ToString());    //■■■■DEBUG LOG■■■■
        CameraRayAction?.Invoke(pressVec, ray.origin, ray.direction);
    }

    /* ◆◆◆◆下記よりカメラ０動作関数◆◆◆◆ */

    //◆◆プレス：　カメラベース位置の記録
    private static void CameraBasePositionSet(Vector2 pressVec)
    {
        if (cameraNum != 0) return;
        moveBasePosition = camerasFocusedPosition[0];
    }

    //◆◆ドラッグ：　カメラ位置の変更
    private static void CameraMove(Vector2 pressVec, Vector2 releaseVec)
    {
        if (cameraNum != 0) return;

        if (Input.GetKey(KeyCode.LeftShift) || Input.GetKey(KeyCode.RightShift))
        {

        }
        else
        {
            Transform camPos = cameras[0].gameObject.transform;

            Vector2 moveVecs = releaseVec - pressVec;
            Vector3 moveValue = new Vector3(moveVecs.x, 0, moveVecs.y);
            Vector3 moveVec = moveValue * -1.0f * (camerasTransform[0].localPosition.y / 500.0f);
            //◆移動限界値指定
            //if (moveVec.x + camPos.localPosition.x >= 1700 || moveVec.x + camPos.localPosition.x <= -1700) { moveVec.x = 0; }
            //if (moveVec.z + camPos.localPosition.z >= 300 || moveVec.z + camPos.localPosition.z <= -500) { moveVec.z = 0; }

            camerasFocusedPosition[0] = moveBasePosition + moveVec;

            //◆MainCamera2の動作
            //◆平面座標の確認
            Vector3 pointA = camerasFocusedPosition[0];
            Vector3 vectorA = camerasTransform[0].forward;
            Vector3 pointB = Vector3.Scale(pointA, new Vector3(1.0f, 0.0f, 1.0f));
            Vector3 vectorB = Vector3.Scale(vectorA, new Vector3(1.0f, 0.0f, 1.0f));
            // 座標計算を切り出し配置（最下部に記載、Kuwayaライブラリ引用）
            Vector3 basePoint = LineLineCross(pointA, vectorA, pointB, vectorB)[0] + new Vector3(0.0f, 0.0f, 0.0f);
            camerasParentTransform[1].localPosition = basePoint;
        }
    }

    //◆◆ホイール：　カメラズームの変更
    private static void CameraZoom(Vector2 vec)
    {
        if (cameraNum != 0) return;
        // Debug.Log(vec);
        float addSpeed = -camerasFocusedPosition[0].y / 10.0f;
        Vector3 zoomValue = new Vector3(0, vec.y, 0);
        Vector3 zoomVec = Quaternion.Euler(-30, 0, 0) * zoomValue * addSpeed;
        CameraClippingPlane(camerasFocusedPosition[0].y * 2.0f);

        if (zoomVec.y + camerasFocusedPosition[0].y >= CAMERA_MAX_DISTANCE || zoomVec.y + camerasFocusedPosition[0].y <= CAMERA_MIN_DISTANCE) { zoomVec = Vector3.zero; }

        camerasFocusedPosition[0] += zoomVec;
    }

    static List<Vector2> logLastStartVec = new List<Vector2>() { Vector2.zero, Vector2.zero };
    static float logLastDistance = 0.0f;
    //◆◆スマホなどのマルチタッチ時のズーム動作（マウスホイール相当）
    private static void CameraZoom(List<Vector2> startVec, List<Vector2> vec)
    {
        if (cameraNum != 0) return;

        if (vec.Count >= 2 && startVec.Count >= 2)
        {
            if (logLastStartVec[0] != startVec[0] || logLastStartVec[1] != startVec[1])
            {
                logLastStartVec[0] = startVec[0];
                logLastStartVec[1] = startVec[1];
                logLastDistance = (startVec[0] - startVec[1]).magnitude;
            }
            float distance = (vec[0] - vec[1]).magnitude;
            Vector2 zoomVec = new Vector2(0, 0);
            if (logLastDistance != distance)
            {
                float delta = distance - logLastDistance;
                logLastDistance = distance;
                zoomVec = new Vector2(0, delta * 0.05f);
            }
            // Debug.Log(zoomVec);
            CameraZoom(zoomVec);
        }
    }
    private static void CameraClippingPlane(float num)
    {
        foreach (var cam in cameras) cam.farClipPlane = num;
    }

    /* ◆◆◆◆下記よりカメラ１動作関数◆◆◆◆ */

    //◆◆プレス：　値セット
    private static void SetCameraBaseRotation(Vector2 pressVec)
    {
        if (cameraNum != 1) return;
        rotationBaseAngle = camerasParentFocusedEulerAngles[1];
        if (rotationBaseAngle.x >= 180.0f) rotationBaseAngle -= new Vector3(360.0f, 0, 0);
    }

    //◆◆ドラッグ：　カメラ移動動作
    private static void SetCameraRotation(Vector2 pressVec, Vector2 releaseVec)
    {
        if (cameraNum != 1) return;

        float rotateX;
        float rotateY;
        //ドラッグの値を指定
        rotateX = (releaseVec.x - pressVec.x) * 0.15f;
        rotateY = (releaseVec.y - pressVec.y) * 0.15f;
        //上限値下限値を指定
        float checkMaxY = rotationBaseAngle.x - rotateY;
        float checkMinY = rotationBaseAngle.x - rotateY;
        if (checkMaxY > 45.0f) { rotateY = rotationBaseAngle.x - 45.0f; }
        else if (checkMinY < -40.0f) { rotateY = rotationBaseAngle.x + 40.0f; }
        //カメラの向かう角度を指定
        camerasParentFocusedEulerAngles[1] = rotationBaseAngle + new Vector3(-rotateY, rotateX, 0);

    }

    //◆◆ホイール：　カメラ動作
    private static void SetCameraPosition(Vector2 vec)
    {
        if (cameraNum != 1) return;

        float changeNumberY;
        float changeNumberZ;
        //ホイール動作の値を指定
        float addSpeed = camerasFocusedPosition[0].y * 0.02f;
        float zoomSpeed = 10.0f;
        changeNumberY = vec.y * zoomSpeed * addSpeed;
        changeNumberZ = vec.y * zoomSpeed * addSpeed;
        //上限値下限値を指定
        float checkMaxY = camerasFocusedPosition[1].y - changeNumberY;
        float checkMinY = camerasFocusedPosition[1].y - changeNumberY;
        float checkMaxZ = camerasFocusedPosition[1].z + changeNumberZ;
        float checkMinZ = camerasFocusedPosition[1].z + changeNumberZ;
        if (checkMaxY > CAMERA_MAX_DISTANCE || checkMinY < CAMERA_MIN_DISTANCE) { changeNumberY = 0f; }
        if (checkMaxZ < -CAMERA_MAX_DISTANCE || checkMinZ > -CAMERA_MIN_DISTANCE) { changeNumberZ = 0f; }
        //カメラの向かう位置を指定
        CameraClippingPlane(camerasFocusedPosition[1].y * 8.0f);
        camerasFocusedPosition[1] += new Vector3(0, -changeNumberY, changeNumberZ);

    }

    /* ◆◆◆◆下記よりデータ参照・データ割当関数◆◆◆◆ */

    //◆◆カメラの変更
    public static void SetCameraNumber(int num)
    {
        if (num == cameraNum) return; // 変更がない場合は何もしない
        switch (cameraNum)
        {
            case 0:
                // カメラ移動アクション
                MouseManager.DragStartAction -= CameraBasePositionSet;
                MouseManager.DragAction -= CameraMove;
                MouseManager.MouseWheelAction -= CameraZoom;
                break;
            case 1:
                // カメラアングルアクション
                MouseManager.DragStartAction -= SetCameraBaseRotation;
                MouseManager.DragAction -= SetCameraRotation;
                MouseManager.MouseWheelAction -= SetCameraPosition;
                break;
            default:
                break;
        }

        cameraNum = num;
        if (cameraNum >= cameras.Length) cameraNum = 0;
        for (int i = 0; i < cameras.Length; i++)
        {
            if (i == cameraNum) cameras[i].gameObject.SetActive(true);
            else cameras[i].gameObject.SetActive(false);
        }
        switch (cameraNum)
        {
            case 0:
                // カメラ移動アクション
                MouseManager.DragStartAction += CameraBasePositionSet;
                MouseManager.DragAction += CameraMove;
                MouseManager.MouseWheelAction += CameraZoom;
                break;
            case 1:
                // カメラアングルアクション
                MouseManager.DragStartAction += SetCameraBaseRotation;
                MouseManager.DragAction += SetCameraRotation;
                MouseManager.MouseWheelAction += SetCameraPosition;
                break;
            default:
                break;
        }
    }

    public static int GetCameraNumber() => cameraNum;
    public static Camera GetCamera(int num) => cameras[num];






    // 座標計算用の切り出し関数群
    public static float Degree(Vector3 a, Vector3 b)
    {
        float lenA = a.magnitude;
        float lenB = b.magnitude;
        float dot = Vector3.Dot(a, b);

        // 長さ無しの除外
        if (lenA * lenB < 1e-8f) return 0f;
        // acosの例外回避
        float cosTheta = Mathf.Clamp(dot / (lenA * lenB), -1f, 1f);

        float angle = Mathf.Acos(cosTheta) * (180f / Mathf.PI);
        //MathF.Acos() : -1.0～+1.0に対して π～0.0を返す
        return angle;
    }

    public static Vector3[] LineLineCross(Vector3 pntA, Vector3 vecA, Vector3 pntB, Vector3 vecB, float distanceTolerance = 0.0001f, float angleTolerance = 0.01f)
    {
        Vector3[] returnVec = new Vector3[2];
        if (Degree(vecA, vecB) <= angleTolerance || Degree(vecA, vecB) >= 180.0f - angleTolerance)
        {
            //２つのベクトルが平行の場合、交点無しで0ベクトルを返す
            returnVec[0] = new Vector3(0, 0, 0);
            returnVec[1] = new Vector3(0, 0, 0);
        }
        else if (pntA == pntB)
        {
            //二つの点が共通の場合、交点は自ずと同位置となるため、その値を返す
            returnVec[0] = pntA;
            returnVec[1] = pntA;
        }
        else
        {
            Vector3 norVecA = Vector3.Normalize(vecA);
            Vector3 norVecB = Vector3.Normalize(vecB);

            float work1 = Vector3.Dot(norVecA, norVecB);
            float work2 = 1 - work1 * work1;
            float dotA = Vector3.Dot(pntB - pntA, norVecA);
            float dotB = Vector3.Dot(pntB - pntA, norVecB);

            //点Aから最近点までの距離d1、点Bから最近点までの距離d2を算出
            float d1 = (dotA - work1 * dotB) / work2;
            float d2 = (work1 * dotA - dotB) / work2;

            Vector3 crossA = new Vector3(pntA.x + d1 * norVecA.x, pntA.y + d1 * norVecA.y, pntA.z + d1 * norVecA.z);
            Vector3 crossB = new Vector3(pntB.x + d2 * norVecB.x, pntB.y + d2 * norVecB.y, pntB.z + d2 * norVecB.z);

            returnVec[0] = crossA;
            returnVec[1] = crossB;
        }
        return returnVec;
    }

}
