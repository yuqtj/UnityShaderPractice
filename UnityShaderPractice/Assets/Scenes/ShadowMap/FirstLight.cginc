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
	// 添加个世界坐标
	float4 worldPos : TEXCOORD1;

	// 替换上面的shadowCoordinates
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
	// 物体空间的法线转为世界空间的法线需要乘上ModelView的转置逆矩阵
	o.normal = UnityObjectToWorldNormal(v.normal);
	o.worldPos = mul(unity_ObjectToWorld, v.vertex);

	// 填充坐标
	TRANSFER_SHADOW(o);	

	return o;
}

UnityLight CreateLight(v2f i)
{
	UnityLight light;

#if defined(POINT) || defined(SPOT)
	// 点光源时这样计算
	light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
#else
	// _WorldSpaceLightPos0包含当前光源的位置，如果是方向光时，保持的是朝向光源的方向
	light.dir = _WorldSpaceLightPos0.xyz;
#endif

	// 计算点光源衰减，UNITY_LIGHT_ATTENUATION中已经使用了SHADOW_ATTENUATION
	UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);

	light.color = _LightColor0.rgb * attenuation;
	light.ndotl = DotClamped(i.normal, light.dir);
	return light;
}

fixed4 frag(v2f i) : SV_Target
{
	// 法线方向
	i.normal = normalize(i.normal);
	// 获取视角方向
	float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos.xyz);
	// 加上纹理的颜色
	float3 albedo = tex2D(_MainTex, i.uv).rgb;

	// 金属流程Test
	float oneMinusReflectivity;
	float3 specularTint;
	albedo = DiffuseAndSpecularFromMetallic(albedo, _Metallic, specularTint, oneMinusReflectivity);

	// 使用PBR渲染
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