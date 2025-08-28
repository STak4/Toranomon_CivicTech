using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ShootEffect : MonoBehaviour
{
    private static Image selfIlmage;
    private static Color selfColor;
    private static float alphaNumber = 1.0f;
    private static float downSpeed = 0.1f;
    private static Transform myTransform;

    private void Awake()
    {
        selfIlmage = gameObject.GetComponent<Image>();
        myTransform = gameObject.transform;
    }

    public static IEnumerator PhotoShootEffect()
    {
        //初期値処理
        int randNum = Random.Range(0, myTransform.childCount);
        myTransform.GetChild(randNum).GetComponent<AudioSource>().Play();
        selfColor = new Color(1.0f, 1.0f, 1.0f, 1.0f);
        alphaNumber = 1.0f;
        selfIlmage.color = selfColor;

        //動的な処理
        int repMax = 20;
        while (alphaNumber > 0.0f || repMax > 0)
        {
            selfColor = new Color(1.0f, 1.0f, 1.0f, alphaNumber);
            selfIlmage.color = selfColor;
            alphaNumber -= downSpeed;
            repMax--;
            yield return new WaitForSeconds(0.01f);
        }

        //戻り値無し終了
        yield break;
    }
}
