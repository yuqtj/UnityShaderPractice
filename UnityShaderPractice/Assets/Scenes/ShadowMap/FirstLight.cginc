#if !defined(MY_LIGHTING_INCLUDED)
#define MY_LIGHTING_INCLUDED

#include "UnityCG.cginc"
#include "UnityLightingCommon.cginc"
#include "UnityStandardUtils.cginc"
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

struct appdata
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
};

struct v2f
{
	float2 uv : TEXCOORD0;
	float3 normal : NORMAL;
	float4 pos : SV_POSITION;
	// ��Ӹ���������
	float4 worldPos : TEXCOORD1;

	// �滻�����shadowCoordinates
	SHADOW_COORDS(2)
};

sampler2D _MainTex;
float4 _MainTex_ST;
float _SpecShininess;
float _Metallic;

v2f vert(appdata v)
{
	v2f o;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = TRANSFORM_TEX(v.uv, _MainTex);
	// ����ռ�ķ���תΪ����ռ�ķ�����Ҫ����ModelView��ת�������
	o.normal = UnityObjectToWorldNormal(v.normal);
	o.worldPos = mul(unity_ObjectToWorld, v.vertex);

	// �������
	TRANSFER_SHADOW(o);	

	return o;
}

UnityLight CreateLight(v2f i)
{
	UnityLight light;

#if defined(POINT) || defined(SPOT)
	// ���Դʱ��������
	light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
#else
	// _WorldSpaceLightPos0������ǰ��Դ��λ�ã�����Ƿ����ʱ�����ֵ��ǳ����Դ�ķ���
	light.dir = _WorldSpaceLightPos0.xyz;
#endif

	// ������Դ˥����UNITY_LIGHT_ATTENUATION���Ѿ�ʹ����SHADOW_ATTENUATION
	UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);

	light.color = _LightColor0.rgb * attenuation;
	light.ndotl = DotClamped(i.normal, light.dir);
	return light;
}

fixed4 frag(v2f i) : SV_Target
{
	// ���߷���
	i.normal = normalize(i.normal);
	// ��ȡ�ӽǷ���
	float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos.xyz);
	// �����������ɫ
	float3 albedo = tex2D(_MainTex, i.uv).rgb;

	// ��������Test
	float oneMinusReflectivity;
	float3 specularTint;
	albedo = DiffuseAndSpecularFromMetallic(albedo, _Metallic, specularTint, oneMinusReflectivity);

	// ʹ��PBR��Ⱦ
	UnityIndirect indirectLight;
	indirectLight.diffuse = 0;
	indirectLight.specular = 0;

	return UNITY_BRDF_PBS(
		albedo, specularTint,
		oneMinusReflectivity, _SpecShininess,
		i.normal, viewDir,
		CreateLight(i), indirectLight
);

}

#endif