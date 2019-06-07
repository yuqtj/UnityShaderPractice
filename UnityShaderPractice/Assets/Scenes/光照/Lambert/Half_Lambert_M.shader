﻿Shader "Unlit/Half_Lambert_M"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

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
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normal = UnityObjectToWorldNormal(v.normal);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				i.normal = normalize(i.normal);
				// 获取当前光源位置
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				// 半程Lambert
				float hLambert = max(0, dot(i.normal, lightDir)) * 0.5 + 0.5;
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return float4(_LightColor0 * col * hLambert * hLambert);
            }
            ENDCG
        }
    }
}
