Shader "Unlit/ShadowSimulation"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}
	SubShader
	{
		LOD 100

		Pass
		{
			Tags
			{ "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma target 3.0

			#pragma multi_compile _ SHADOWS_SCREEN

			#pragma vertex vert
			#pragma fragment frag

			#include "FirstLight.cginc"

			ENDCG
		}

		Pass
		{
			Tags
			{
				"LightMode" = "ForwardAdd"
			}

			Blend One One
			ZWrite Off

			CGPROGRAM
			#pragma target 3.0

			#pragma multi_compile DIRECTIONAL POINT SPOT
			// 多重阴影
			#pragma multi_compile_fwdadd_fullshadows
			//#pragma multi_compile_shadowcaster

			#pragma vertex vert
			#pragma fragment frag

			#include "FirstLight.cginc"

			ENDCG
		}

		Pass
		{
			Tags
			{
				"LightMode" = "ShadowCaster"
			}

			CGPROGRAM

			#pragma target 3.0

			#pragma multi_compile_shadowcaster
			#pragma vertex MyShadowVertexProgram
			#pragma fragment MyShadowFragmentProgram

			#include "MyShadows.cginc"

			ENDCG
		}
	}
}