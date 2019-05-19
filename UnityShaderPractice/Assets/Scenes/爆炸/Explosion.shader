Shader "Unlit/Explosion"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Speed("Speed", Float) = 10
		_AccelerationValue("_AccelerationValue", Float) = 10
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
			#pragma geometry geom
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

			struct g2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

            sampler2D _MainTex;
            float4 _MainTex_ST;

			float _Speed;
			float _AccelerationValue;
			float _StartTime;

            v2f vert (appdata v)
            {
                v2f o;
				o.vertex = v.vertex;  
				o.uv = v.uv; TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

			// 输出的最大顶点数量为1
			[maxvertexcount(1)]
			// 输入的图元是三角形，所以顶点数量为3。如图元为点则为point v2f IN[1]
			// 输出的是点，所以为点流PointStream，如果输出三角形流则为TriangleStream
			void geom(triangle v2f IN[3], inout PointStream<g2f> pointStream)
			{
				g2f o;
				float3 v1 = IN[1].vertex - IN[0].vertex;
				float3 v2 = IN[2].vertex - IN[0].vertex;

				float3 norm = normalize(cross(v1, v2));
				// 求三角形中心点
				float3 centerPos = (IN[0].vertex + IN[1].vertex + IN[2].vertex) / 3;
				// 将中心点向法线方向移动，s = v0 * t + 1 / 2 * a * t ^ 2
				float deltaTime = _Time.y - _StartTime;
				centerPos += norm * (_Speed * deltaTime + 0.5 * _AccelerationValue * pow(deltaTime, 2));

				o.vertex = UnityObjectToClipPos(centerPos);
				o.uv = (IN[0].uv + IN[1].uv + IN[2].uv) / 3;
				pointStream.Append(o);
			}

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
