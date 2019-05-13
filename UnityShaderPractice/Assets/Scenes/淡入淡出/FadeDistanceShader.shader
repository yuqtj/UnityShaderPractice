Shader "Unlit/FadeDistanceShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_FadeDistanceNear("_FadeDistanceNear", Range(0.1, 3.0)) = 0.1
		_FadeDistanceFar("_FadeDistanceFar", Range(10, 30)) = 10
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "IgnoreProjector" = "True" }
        LOD 100

        Pass
        {
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
				float4 worldPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			float _FadeDistanceNear;
			float _FadeDistanceFar;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

				// 获取视角向量
				float viewLength = length(i.worldPos.xyz - _WorldSpaceCameraPos);
				float fade = 1 - saturate((viewLength - _FadeDistanceNear) / (_FadeDistanceFar - _FadeDistanceNear));
                return float4(col.rgb, fade);
            }
            ENDCG
        }
    }
}
