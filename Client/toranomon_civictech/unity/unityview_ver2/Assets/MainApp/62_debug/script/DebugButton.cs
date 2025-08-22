using UnityEngine;
using UnityEngine.UI;

public class DebugButton : MonoBehaviour
{
    public static DebugButton Instance { get; private set; }

    [SerializeField] private Button _debug_OnOff;
    private static Button debug_OnOff => Instance?._debug_OnOff;

    [SerializeField] private Button _debug_ShowHideA;
    private static Button debug_ShowHideA => Instance?._debug_ShowHideA;
    [SerializeField] private Button _debug_ShowHideB;
    private static Button debug_ShowHideB => Instance?._debug_ShowHideB;
    [SerializeField] private Button _debug_ShowHideC;
    private static Button debug_ShowHideC => Instance?._debug_ShowHideC;

    [SerializeField] private GameObject _showHideA;
    private static GameObject showHideA => Instance?._showHideA;
    [SerializeField] private GameObject _showHideB;
    private static GameObject showHideB => Instance?._showHideB;
    [SerializeField] private GameObject _showHideC;
    private static GameObject showHideC => Instance?._showHideC;

    private void Awake()
    {
        if (Instance == null) Instance = this;
        else Destroy(this);

        debug_OnOff.onClick.AddListener(() => TriggerDebugOnOffAction());
        debug_ShowHideA.onClick.AddListener(() => TriggerDebugShowHideAAction());
        debug_ShowHideB.onClick.AddListener(() => TriggerDebugShowHideBAction());
        debug_ShowHideC.onClick.AddListener(() => TriggerDebugShowHideCAction());
    }

    private void Update()
    {
        if (Input.touchCount == 3)
        {
            bool taped = false;
            foreach(Touch touch in Input.touches)
            {
                if(touch.phase == TouchPhase.Ended)
                {
                    taped = true;
                }
            }
            if (taped)
            {
                TriggerDebugOnOffAction();
            }
        }
    }
    public static void TriggerDebugOnOffAction()
    {
        Debug.Log("Debug on-off tapped.");
        if(DebugSystem.debugLogs.gameObject != null)
        {
            if (DebugSystem.debugLogs.gameObject.activeSelf) { DebugSystem.debugLogs.gameObject.SetActive(false); }
            else { DebugSystem.debugLogs.gameObject.SetActive(true); }
        }
    }

    public static void TriggerDebugShowHideAAction()
    {
        Debug.Log("Debug show hide A tapped.");
        if(showHideA != null)
        {
            if (showHideA.activeSelf) { showHideA.SetActive(false); }
            else { showHideA.SetActive(true); }
        }
    }
    public static void TriggerDebugShowHideBAction()
    {
        Debug.Log("Debug show hide B tapped.");
        if(showHideB != null)
        {
            if (showHideB.activeSelf) { showHideB.SetActive(false); }
            else { showHideB.SetActive(true); }
        }
    }
    public static void TriggerDebugShowHideCAction()
    {
        Debug.Log("Debug show hide C tapped.");
        if(showHideC != null)
        {
            if (showHideC.activeSelf) { showHideC.SetActive(false); }
            else { showHideC.SetActive(true); }
        }
    }



}
