using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class AppMaster : MonoBehaviour
{
    [SerializeField] private GameObject _status;
    [SerializeField] private TMP_Text _statusText;
    [SerializeField] private GameObject _information;
    [SerializeField] private TMP_Text _informationText;
    [SerializeField] private GameObject _radarView;

    [SerializeField] private Button _radarButton;
    [SerializeField] private Button _trackingButton;
    [SerializeField] private Button _arViewButton;
    [SerializeField] private Button _mappingButton;
    [SerializeField] private Button _photoShootButton;
    [SerializeField] private Button _submitButton;

    private void Awake()
    {
        _radarButton.onClick.AddListener(() => TriggerRadarButtonAction());
        _trackingButton.onClick.AddListener(() => TriggerTrackingButtonAction());
        _arViewButton.onClick.AddListener(() => TriggerARViewButtonAction());
        _mappingButton.onClick.AddListener(() => TriggerMappingButtonAction());
        _photoShootButton.onClick.AddListener(() => TriggerPhotoShootButtonAction());
        _submitButton.onClick.AddListener(() => TriggerSubmitButtonAction());
        _status.gameObject.SetActive(true);
        _information.gameObject.SetActive(false);
        _radarView.gameObject.SetActive(false);
    }

    private void TriggerRadarButtonAction()
    {
        bool isActive = _radarView.activeSelf;
        _radarView.gameObject.SetActive(!isActive);
    }
    private void TriggerTrackingButtonAction()
    {
        // Implement tracking button action
        Debug.Log("Tracking button pressed.");
    }
    private void TriggerARViewButtonAction()
    {
        // Implement AR view button action
        Debug.Log("AR View button pressed.");
    }
    private void TriggerMappingButtonAction()
    {
        // Implement mapping button action
        Debug.Log("Mapping button pressed.");
    }
    private void TriggerPhotoShootButtonAction()
    {
        // Implement photo shoot button action
        Debug.Log("Photo Shoot button pressed.");
    }
    private void TriggerSubmitButtonAction()
    {
        // Implement submit button action
        Debug.Log("Submit button pressed.");
    }

}
