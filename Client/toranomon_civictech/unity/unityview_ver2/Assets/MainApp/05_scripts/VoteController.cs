using UnityEngine;

public class VoteController : MonoBehaviour
{
    private ParticleSystem[] _particleSystems;

    void Start()
    {
        InitParticles();
        StopParticles();
    }

    public void InitParticles()
    {
        if (transform.childCount >= 3)
        {
            Transform thirdChild = transform.GetChild(2);
            int particleCount = thirdChild.childCount;
            _particleSystems = new ParticleSystem[particleCount];
            for (int i = 0; i < particleCount; i++)
            {
                _particleSystems[i] = thirdChild.GetChild(i).GetComponent<ParticleSystem>();
            }
        }
    }
    public void SetParticlesRate(float[] rates)
    {
        if (_particleSystems == null) return;
        int count = Mathf.Min(_particleSystems.Length, rates.Length);
        for (int i = 0; i < count; i++)
        {
            var ps = _particleSystems[i];
            if (ps != null)
            {
                var emission = ps.emission;
                emission.rateOverTime = rates[i] * 5.0f;
            }
        }
    }

    public void PlayParticles()
    {
        if (_particleSystems == null) return;
        foreach (var ps in _particleSystems)
        {
            if (ps != null)
            {
                ps.Play();
            }
        }
    }

    public void StopParticles()
    {
        if (_particleSystems == null) return;
        foreach (var ps in _particleSystems)
        {
            if (ps != null)
            {
                ps.Stop();
            }
        }
    }

}
