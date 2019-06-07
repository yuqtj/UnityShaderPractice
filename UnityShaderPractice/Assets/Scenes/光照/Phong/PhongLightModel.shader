// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Unlit/PhongLightModel"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		//镜面反射颜色  
		_SpecColor("Specular Color", Color) = (1, 1, 1, 1)
		//镜面反射光泽度  
		_SpecShininess("Specular Shininess", Range(1.0, 100.0)) = 10.0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
				// 添加个世界位置
				float4 worldPos : TEXCOORD1;
			};

			sampler2D _MainTex;
			float _SpecShininess;
			float4 _MainTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				// 物体空间的法线转为世界空间的法线需要乘上ModelView的转置逆矩阵
				o.normal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}
			
			float4 frag (v2f o) : SV_Target
			{
				// 法线方向
				o.normal = normalize(o.normal);
				// 获取当前光源的位置
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				// 加上纹理的颜色
				float3 albedo = tex2D(_MainTex, o.uv).rgb;
				// 半程Lamert
				float hLambert = max(0, dot(o.normal, lightDir)) * 0.5 + 0.5;
				// 计算漫反射光照
				float3 diffuse = albedo * _LightColor0.xyz * hLambert;

				// 获取视角方向
				float3 viewDir = normalize(_WorldSpaceCameraPos - o.worldPos.xyz);
				// 计算镜面反射颜色
				float3 specular = float3(0, 0, 0);
				// 如果法线方向和入射光方向小于180才有高光颜色
				if (dot(o.normal, lightDir) > 0.0)
				{
					// 基础高光计算
					float3 reflectDir = reflect(-lightDir, o.normal);
					specular = _SpecColor.rgb * _LightColor0.rgb * pow(max(0.0, dot(reflectDir, viewDir)), _SpecShininess);
				}

				// _LightColor0.xyz 在这个里面#include "UnityLightingCommon.cginc"，这里获取到了场景默认的方向光
				return float4(diffuse + specular, 1);
			}
			ENDCG
		}
	}
}
