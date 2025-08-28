using System.Collections;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.UI;

public class ShootEffect : MonoBehaviour
{
    [SerializeField] private Image _selfImage;
    [SerializeField] private Transform _myTransform;
    private float _alphaNumber = 1.0f;
    private float _downSpeed = 0.1f;

    public async Task PlayShootEffect()
    {
        //初期値処理
        int randNum = Random.Range(0, _myTransform.childCount);
        Color selfColor = new Color(1.0f, 1.0f, 1.0f, 1.0f);

        // _myTransform.GetChild(randNum).GetComponent<AudioSource>().Play();
        _alphaNumber = 1.0f;
        _selfImage.color = selfColor;

        //動的な処理
        int repMax = 20;
        while (_alphaNumber > 0.0f || repMax > 0)
        {
            selfColor = new Color(1.0f, 1.0f, 1.0f, _alphaNumber);
            _selfImage.color = selfColor;
            _alphaNumber -= _downSpeed;
            repMax--;
            await Task.Delay(10);
        }
    }
}
