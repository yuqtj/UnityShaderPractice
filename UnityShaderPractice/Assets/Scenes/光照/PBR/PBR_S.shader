// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/PBR_S"
{
    Properties
    {
	   _Matel("Matel",2D) = "white"{}
	   _Albedo("Albedo", 2D) = "white" {}
	   _Normal("Normal", 2D) = "bump"{}
	   _Matellic("Matellic", Range(0.0, 1.0)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
			Name "FORWARD"

			Tags{
				"LightMode" = "ForwardBase"
			}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#define PI 3.1415926

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
            };

            struct v2f
            {
				float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
				float4 posWorld : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
				float3 tangentDir : TEXCOORD3;
				float3 bitangentDir : TEXCOORD4;
				LIGHTING_COORDS(5, 6)
                UNITY_FOG_COORDS(7)
            };

			sampler2D _Albedo;
			float4 _Albedo_ST;
			sampler2D _Matel;
			float4 _Matel_ST;
			uniform sampler2D _Normal;
			uniform float4 _Normal_ST;
			uniform float4 _LightColor0;
			float _Matellic;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _Albedo);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.normalDir = UnityObjectToWorldNormal(v.normal);
				o.tangentDir = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
				o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

			float DistributionGGX(float NdotH, float roughness)
			{
				float a = roughness * roughness;
				float a2 = a * a;
				float NdotH2 = NdotH * NdotH;

				float nom = a2;
				float denom = (NdotH2 * (a2 - 1.0) + 1.0);
				denom = PI * denom * denom;

				return nom / denom;
			}

			float GeometrySchlickGGX(float NdotV, float roughness)
			{
				float r = (roughness + 1.0);
				float k = (r * r) / 8.0;

				float nom = NdotV;
				float denom = NdotV * (1.0 - k) + k;

				return nom / denom;
			}

			float GeometrySmith(float NdotV, float NdotL, float roughness)
			{
				// 分别对入射光线和反射光线的模拟，所以需要两次
				float ggx2 = GeometrySchlickGGX(NdotV, roughness);
				float ggx1 = GeometrySchlickGGX(NdotL, roughness);

				return ggx1 * ggx2;
			}

			float3 fresnelSchlick(float cosTheta, float3 F0)
			{
				return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
			}

            fixed4 frag (v2f i) : SV_Target
            {
				i.normalDir = normalize(i.normalDir);
				float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);

				// 法线贴图采样

				// 法线的TBN旋转矩阵
				float3x3 tangentTransform = float3x3(i.tangentDir, i.bitangentDir, i.normalDir);
				float4 normalAlbedo = tex2D(_Normal, TRANSFORM_TEX(i.uv, _Normal));
				float3 normalLocal = normalAlbedo * 2 - 1;
				float3 normalDirection = normalize(mul(normalLocal, tangentTransform));

				// 金属贴图采样
				fixed4 matelTex = tex2D(_Matel, TRANSFORM_TEX(i.uv, _Matel));
				//float matellic = matelTex.r;
				float matellic = _Matellic;
				float roughness = matelTex.r;

				// 半程向量
				float3 H = normalize(lightDirection + viewDirection);

				float NoL = saturate(dot(normalDirection, lightDirection));
				float NoV = saturate(dot(normalDirection, viewDirection));
				float NoH = saturate(dot(normalDirection, H));
				float VoH = saturate(dot(viewDirection, H));

				//light & light color
				float3 attenColor = LIGHT_ATTENUATION(i) * _LightColor0.xyz;

				// sample the _Albedo texture
				fixed4 albedo = tex2D(_Albedo, i.uv);


				// 法线分布函数NDF
				float NDF = DistributionGGX(NoH, roughness);

				// 几何函数G
				float G = GeometrySmith(NoV, NoL, roughness);

				// 菲涅尔光照F
				float3 F0 = 0.04;
				//F0 = mix(F0, albedo.rgb, matellic);
				F0 = F0 * (1 - matellic) + albedo.rgb * matellic;
				// F表示物体表面光线被反射的百分比
				float3 F = fresnelSchlick(VoH, F0);
				// 高光
				float3 nominator = NDF * G * F;
				float denominator = 4 * NoV * NoL + 0.001; // 0.001 to prevent divide by zero.
				// 由于specular已经把F乘进去了，所以不需要再乘一次kS了。
				float3 specular = nominator / denominator;

				// kS is equal to Fresnel
				float3 kS = F;
				float3 kD = 1.0 - kS;
				// 金属不会有漫反射
				kD *= 1.0 - matellic;

				// 漫反射
				float3 indirectDiffuse = float3(0, 0, 0);
				// Ambient Light
				indirectDiffuse += UNITY_LIGHTMODEL_AMBIENT.rgb; 
				// 这里除以PI的原因是漫反射是在法相半球上均匀发射的，这里只是其中一个微分，半球圆心角为π，所以除以π
				float3 diffuse = kD * albedo / PI;

				fixed4 finalColor = (fixed4)0;
				finalColor.rgb = (diffuse + specular) * attenColor * NoL;
				finalColor.a = albedo.a;
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, finalcolor);

                return finalColor;
            }
            ENDCG
        }
    }
}
