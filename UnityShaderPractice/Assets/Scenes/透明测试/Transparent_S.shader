Shader "Unlit/Transparent_S"
{
    Properties
    {
		_Color("Color", Color) = (1, 1, 1, 1)
		_MainTex("MainTex", 2D) = "White" {}
		_AlphaScale("AlphaScale", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags { 
			"RenderType"="Transparent"
			"Ignoreprojector" = "True"
			"Queue" = "Transparent"
		}
        LOD 100

        Pass
        {
			// Blend SrcFactor DstFactor
			// Add:  FinalColor=SrcFactor*SrcColor+DstFactor*DstColor

			ZWrite off
			//Blend SrcAlpha OneMinusSrcAlpha
			//Blend One One
			//Blend One Zero
			//Blend Zero One
			Blend Zero SrcColor

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
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			float _AlphaScale;
			fixed4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
				col *= _Color;
				col.a *= _AlphaScale;
                return col;
            }
            ENDCG
        }
    }
}
