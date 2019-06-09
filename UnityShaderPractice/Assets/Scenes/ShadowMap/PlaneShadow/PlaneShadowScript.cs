using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlaneShadowScript : MonoBehaviour
{
    public Light mLight;
    public Material planeShadowMaterial;
    public Transform planeTransform;
    // 软阴影参数调整
    public Vector4 shadowFadeParams;

    // Update is called once per frame
    void Update()
    {
        UpdateShader();
    }

    private void UpdateShader()
    {
        Vector4 worldpos = transform.position;
        Vector4 projdir = mLight.transform.forward;

        if (planeShadowMaterial == null)
            return;

        Vector3 planePos = planeTransform.position;
        Vector3 planeNormal = new Vector3(0, 1, 0);
        float d = Vector3.Dot(planeNormal, planePos);

        planeShadowMaterial.SetVector("_WorldPos", worldpos);
        planeShadowMaterial.SetVector("_ShadowProjDir", projdir);
        planeShadowMaterial.SetVector("_ShadowPlane", new Vector4(planeNormal.x, planeNormal.y, planeNormal.z, d));
        planeShadowMaterial.SetVector("_ShadowFadeParams", shadowFadeParams);
        planeShadowMaterial.SetFloat("_ShadowFalloff", 1.35f);
    }
}
