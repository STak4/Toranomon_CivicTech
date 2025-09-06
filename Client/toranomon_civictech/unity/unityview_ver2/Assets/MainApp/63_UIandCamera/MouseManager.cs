using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.InputSystem.Controls;
using UnityEngine.InputSystem.Utilities;
using TouchPhase = UnityEngine.InputSystem.TouchPhase;

public class MouseManager : MonoBehaviour
{
    /*
     * ◆◆コントローラ―構築解説
     * 
     * ◆必要な要素
     * 　　・PlayerInputを特定のオブジェクトにアタッチ
     * 　　・PlayerInput > Actions > PlayerControl(Input Action Asset)をアタッチ
     * 　　・PlayerInput > Behavior > Invoke C Sharp Eventsに変更
     * 　　・MouseManager.cs(当script)をPlayerInputと同じオブジェクトにアタッチ
     * 　　
     * ◆当該スクリプト構造
     * 　　・下記をデフォルトとして呼び出し
     * 　　　　・Select : マウス左クリック・スクリーンタップ動作
     * 　　　　　　・MultiTouchAction : 複数同時タップ時挙動
     * 　　　　　　　　・TriggerMultiTouchAction : 上記時呼び出し関数
     *   　　　　　・SelectAction : シンプルなクリック・タップ時挙動
     *   　　　　　　　・TriggerSelectAction : 上記時呼び出し関数
     *   　　　　　・DragAction : ドラッグ時挙動
     *   　　　　　　　・TriggerDragAction : 上記時呼び出し関数
     *   　　　　　・HoldAction : ホールド時挙動
     *   　　　　　　　・TriggerHoldAction : 上記時呼び出し関数
     * 　　　　・ZoomMouse : ズーム動作
     *   　　　　　・MouseWheelAction : 
     *   　　　　　　　・TriggerMouseWheelAction : 上記時呼び出し関数
     * 
     * ◆構築時一般事項
     * 　　・関数の追加：外部スクリプトにて各Actionに関数を追加。（Publicの為、任意に追加可能。）
     * 　　・軽微な実装操作：当該スクリプト内でTrigger関数内に処理を記述。
     * 　　・画面内ＵＩコントロール：別途定義を前提とし当該スクリプトは無関係が前提。
     * 
     * ◆高度な構築の考察
     * 　　・当該スクリプトはあくまで「マウス挙動」のみを管理するため、それによるボタンタップ・画面タップの違いは別途要構築。
     * 
     */

    public static MouseManager Instance { set; get; }

    //◆◆タップやクリックなどの処理の際に実行
    private static Vector2 pressPosition;
    private static Vector2 releasePosition;
    private static bool selectStartLock = false;
    private static bool holdCondition = false;
    private static bool multiTouchCondition = false;
    private static bool dragCondition = false;
    private static Vector2 moveVector;
    private static float tapDistance = 400.0f;  //タップ・ドラッグとする切り替えラインの距離の二乗（400≒20px越えで）
    private static float tapTime = 0.2f;    //タップ・ホールドとする切り替えラインの秒数
    private static float tapDeltaTime = 0.0f;

    private static List<Vector2> startTouchVectors = new List<Vector2>();

    //◆◆アクション管理（OnSelect関連）

    /// <summary>
    /// Multiple touch action. The fist List is start touch positions at window. The second List is end touch positions at window.
    /// </summary>
    /// <param name="list1">start touch positions at window</param>
    /// <param name="list2">end touch positions at window</param>
    public static event Action<List<Vector2>, List<Vector2>> MultiTouchAction;

    /// <summary>
    /// Select action. The Vector2 is select position at window.
    /// </summary>
    /// <param name="list1">select position at window</param>
    public static event Action<Vector2> SelectAction;

    /// <summary>
    /// Drag action. The first Vector2 is start position at window. The second Vector2 is progress or end position at window.
    /// </summary>
    /// <param name="list1">start position at window</param>
    /// <param name="list2">progress or end position at window</param>
    public static event Action<Vector2, Vector2> DragAction;

    /// <summary>
    /// Drag start action. The Vector2 is start position at window.
    /// </summary>
    /// <param name="list1">start position at window</param>
    public static event Action<Vector2> DragStartAction;

    /// <summary>
    /// Drag end action. The Vector2 is end position at window.
    /// </summary>
    /// <param name="list1">progress or end position at window</param>
    public static event Action<Vector2> DragEndAction;

    /// <summary>
    /// Hold start action. The Vector2 is Holded position at window.
    /// </summary>
    /// <param name="list1">Holded position at window</param>
    public static event Action<Vector2> HoldStartAction;

    /// <summary>
    /// Hold end action. The Vector2 is Holded position at window.
    /// </summary>
    /// <param name="list1">Holded position at window</param>
    public static event Action<Vector2> HoldEndAction;

    //◆◆アクション管理（OnZoomMouse関連）
    /// <summary>
    /// Mouse wheel action.
    /// </summary>
    /// <param name="list1">mouse wheel value</param>
    public static event Action<Vector2> MouseWheelAction;

    private void Awake()
    {
        if (Instance == null) Instance = this;
        else Destroy(this);
    }

    private void Start()
    {
        PlayerInput playerInput = this.transform.GetComponent<PlayerInput>();
        if (playerInput != null) playerInput.onActionTriggered += OnActionTriggered;
        else Debug.LogWarning("[MouseManager] PlayerInput component not found.");
    }

    private void OnActionTriggered(InputAction.CallbackContext context)
    {
        if (context.action.name == "Select") OnSelect(context);
        else if (context.action.name == "ZoomMouse") OnZoomMouse(context);
    }

    //◆◆◆Select関係挙動（Player Input > Events > Playerにて定義・発報）
    public void OnSelect(InputAction.CallbackContext context)
    {
        //◆◆マルチタッチスクリーンの処理
        if (Touchscreen.current != null)
        {
            TouchControl prime = Touchscreen.current.touches[0];
            List<Vector2> touchVectors = new List<Vector2>();
            //phase = TouchPhase.None, Began, Moved, Ended.
            //１つ目のデータが存在してる≒タッチ操作になっている確認処理
            if (prime.phase.ReadValue() != TouchPhase.None)
            {
                //タッチ数の確認
                int touchCount = 0;
                ReadOnlyArray<TouchControl> touchControls = Touchscreen.current.touches;
                for (int i = 0; i < 9; i++)
                {
                    if (touchControls[i].phase.ReadValue() == TouchPhase.Moved)
                    {
                        touchCount++;
                        touchVectors.Add(touchControls[i].position.ReadValue());
                    }
                }

                //マルチタッチの際の分岐処理
                if (touchCount == 1)
                {
                    //◆シングルタッチ処理
                    if (multiTouchCondition)
                    {
                        //下記の処理整理
                        pressPosition = Pointer.current.position.ReadValue();
                        releasePosition = Pointer.current.position.ReadValue();
                        multiTouchCondition = false;
                    }
                }
                if (touchCount > 1)
                {
                    //◆マルチタッチ処理
                    if (!multiTouchCondition)
                    {
                        //マルチタッチ開始初期データを格納
                        startTouchVectors = touchVectors;
                        multiTouchCondition = true;
                        selectStartLock = false;
                    }
                    MultiTouchAction?.Invoke(startTouchVectors, touchVectors);
                }
                else
                {
                    //◆タッチが開始もしくは終了のみ際の処理（Began, Ended）
                    multiTouchCondition = false;
                }
            }
            else
            {
                //Debug.Log("You don't use touch screen, we don't use multi touch.");    //■■DEBUG LOG■■
            }
        }
        else
        {
            //Debug.Log("Touch screen is null. maybe you are at UNITY ENGINE.");//■■DEBUG LOG■■
        }

        //◆◆マルチタッチ以外の処理（シングルタッチ）
        if (!multiTouchCondition)
        {
            //タップ開始時の処理
            if (context.phase == InputActionPhase.Started && Pointer.current != null && !selectStartLock)
            {
                pressPosition = Pointer.current.position.ReadValue();
                selectStartLock = true;

                //◆ホールド確認コールチン
                StartCoroutine(CountHoldTime(pressPosition));
            }
            //タップ継続中の処理
            else if (context.phase == InputActionPhase.Performed && Pointer.current != null)
            {
                //ドラッグ処理分岐
                releasePosition = Pointer.current.position.ReadValue();
                moveVector = releasePosition - pressPosition;
                if (Vector2.SqrMagnitude(moveVector) > tapDistance)
                {
                    //◆ドラッグの処理
                    if(!dragCondition) DragStartAction?.Invoke(pressPosition);
                    dragCondition = true;
                    DragAction?.Invoke(pressPosition, releasePosition);
                }
            }
            //タップ終了時の処理
            else if (context.phase == InputActionPhase.Canceled && Pointer.current != null)
            {
                //セレクト処理分岐
                if (Vector2.SqrMagnitude(moveVector) < tapDistance && selectStartLock && !holdCondition) SelectAction?.Invoke(pressPosition);
                selectStartLock = false;

                //ホールド処理の初期化
                tapDeltaTime = 0.0f;
                if (holdCondition) HoldEndAction?.Invoke(releasePosition);
                holdCondition = false;

                //ドラッグ処理の初期化
                if (dragCondition) DragEndAction?.Invoke(releasePosition);
                dragCondition = false;
            }
        }
    }

    //◆タップ時間の確認処理
    private IEnumerator CountHoldTime(Vector2 vec)
    {
        //タップ中のみ時間をカウント
        while (selectStartLock && tapDeltaTime < tapTime)
        {
            tapDeltaTime += Time.deltaTime;
            yield return null;
        }
        if (selectStartLock && Vector2.SqrMagnitude(moveVector) < tapDistance)
        {
            //◆ホールド処理
            holdCondition = true;
            HoldStartAction?.Invoke(vec);
        }
    }

    //◆◆◆Zoom関係挙動（Player Input > Events > Playerにて定義・発報）
    public void OnZoomMouse(InputAction.CallbackContext context)
    {
        if (context.phase != InputActionPhase.Performed) return;
        MouseWheelAction?.Invoke(context.ReadValue<Vector2>());
    }

    //◆◆◆◆下記よりManager内部で個別に処理を指定　※privateで個別Viewのため、非動作とする◆◆◆◆

    /*
    //◆マルチタッチ時の挙動を指定
    private static void TriggerMultiTouchAction(List<Vector2> startVec, List<Vector2> vec)
    {
        //◆◆実行処理スクリプトを記載
    }
    //◆セレクト時の挙動を指定
    private static void TriggerSelectAction(Vector2 vec)
    {
        Debug.Log("[mouse manager] select : " + vec.ToString());    //■■■■DEBUG LOG■■■■
        //◆◆実行処理スクリプトを記載
    }
    //◆ドラッグ時の挙動を指定
    private static void TriggerDragAction(Vector2 pressVec, Vector2 releaseVec)
    {
        //Debug.Log("drag : " + releaseVec.ToString());    //■■■■DEBUG LOG■■■■
        //◆◆実行処理スクリプトを記載
    }
    //◆ドラッグ開始時の挙動を指定
    private static void TriggerDragStartAction(Vector2 pressVec)
    {
        //Debug.Log("drag start : " + pressVec.ToString());    //■■■■DEBUG LOG■■■■
        //◆◆実行処理スクリプトを記載
    }
    //◆ドラッグ終了時の挙動を指定
    private static void TriggerDragEndAction(Vector2 releaseVec)
    {
        //Debug.Log("drag end : " + releaseVec.ToString());    //■■■■DEBUG LOG■■■■
        //◆◆実行処理スクリプトを記載
    }
    //◆ホールド開始時の挙動を指定
    private static void TriggerHoldStartAction(Vector2 vec)
    {
        //Debug.Log("hold start vec : " + vec.ToString());    //■■■■DEBUG LOG■■■■
        //◆◆実行処理スクリプトを記載
    }
    //◆ホールド終了時の挙動を指定
    private static void TriggerHoldEndAction(Vector2 vec)
    {
        //Debug.Log("hold end vec : " + vec.ToString());    //■■■■DEBUG LOG■■■■
        //◆◆実行処理スクリプトを記載
    }
    //◆マウスホイールズーム時の挙動を指定
    private static void TriggerMouseWheelAction(Vector2 vec)
    {
        //Debug.Log("wheel : " + vec.ToString()); //■■■■DEBUG LOG■■■■
        //◆◆実行処理スクリプトを記載
    }
    */




    /*
    //◆◆アクション管理（OnKeyType関連）
    /// <summary>
    /// Key type action.
    /// </summary>
    /// <param name="list1">key type value</param>
    public static Action<KeyControl> KeyTypeAction;

    //◆◆◆KeyType関係挙動
    public void OnKeyType(InputAction.CallbackContext context)
    {
        if (context.phase != InputActionPhase.Performed) return;
        if (context.control is AnyKeyControl anyKeyControl)
        {
            Debug.Log($"get key{anyKeyControl .anyKeyControl}");
        }
        Debug.Log("Control type: " + context.control.GetType().Name); // コントロールの型を表示
        //KeyTypeAction?.Invoke(context.control as KeyControl);
    }
    //◆キータイプの挙動を指定
    private static void TriggerKeyTypeAction(KeyControl key)
    {
        Debug.Log($"key : {key.name}");
    }
    */
}
