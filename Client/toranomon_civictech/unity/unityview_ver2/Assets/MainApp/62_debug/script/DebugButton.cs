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
    [SerializeField] private Button _debug_ShowHideD;
    private static Button debug_ShowHideD => Instance?._debug_ShowHideD;
    [SerializeField] private Button _debug_ShowHideE;
    private static Button debug_ShowHideE => Instance?._debug_ShowHideE;

    [SerializeField] private GameObject _showHideA;
    private static GameObject showHideA => Instance?._showHideA;
    [SerializeField] private GameObject _showHideB;
    private static GameObject showHideB => Instance?._showHideB;
    [SerializeField] private GameObject _showHideC;
    private static GameObject showHideC => Instance?._showHideC;
    [SerializeField] private GameObject _showHideD;
    private static GameObject showHideD => Instance?._showHideD;
    [SerializeField] private GameObject _showHideE;
    private static GameObject showHideE => Instance?._showHideE;

    private void Awake()
    {
        if (Instance == null) Instance = this;
        else Destroy(this);

        debug_OnOff.onClick.AddListener(() => TriggerDebugOnOffAction());
        debug_ShowHideA.onClick.AddListener(() => TriggerDebugShowHideAction(debug_ShowHideA, showHideA));
        debug_ShowHideB.onClick.AddListener(() => TriggerDebugShowHideAction(debug_ShowHideB, showHideB));
        debug_ShowHideC.onClick.AddListener(() => TriggerDebugShowHideAction(debug_ShowHideC, showHideC));
        debug_ShowHideD.onClick.AddListener(() => TriggerDebugShowHideAction(debug_ShowHideD, showHideD));
        debug_ShowHideE.onClick.AddListener(() => TriggerDebugShowHideAction(debug_ShowHideE, showHideE));
        debug_ShowHideA.gameObject.SetActive(false);
        debug_ShowHideB.gameObject.SetActive(false);
        debug_ShowHideC.gameObject.SetActive(false);
        debug_ShowHideD.gameObject.SetActive(false);
        debug_ShowHideE.gameObject.SetActive(false);
    }

    private void Update()
    {
        if (Input.touchCount == 3)
        {
            bool taped = false;
            foreach(Touch touch in Input.touches) if(touch.phase == TouchPhase.Ended) taped = true;
            if (taped) TriggerDebugOnOffAction();
        }
    }
    public static void TriggerDebugOnOffAction()
    {
        Debug.Log("Debug on-off tapped.");
        if(DebugSystem.debugLogs.gameObject != null)
        {
            bool showCondition = DebugSystem.debugLogs.gameObject.activeSelf;
            DebugSystem.debugLogs.gameObject.SetActive(!showCondition);
            debug_ShowHideA.gameObject.SetActive(!showCondition);
            debug_ShowHideB.gameObject.SetActive(!showCondition);
            debug_ShowHideC.gameObject.SetActive(!showCondition);
            debug_ShowHideD.gameObject.SetActive(!showCondition);
            debug_ShowHideE.gameObject.SetActive(!showCondition);
        }
    }

    public static void TriggerDebugShowHideAction(Button button, GameObject obj)
    {
        if(obj != null)
        {
            Debug.Log($"Debug button {button.name} tapped for {obj.name} {(obj.activeSelf ? "hiding" : "showing")}");
            if (obj.activeSelf) { obj.SetActive(false); }
            else { obj.SetActive(true); }
        }
        else
        {
            Debug.LogWarning("Debug show hide tapped, but object is null");
        }
    }
}
