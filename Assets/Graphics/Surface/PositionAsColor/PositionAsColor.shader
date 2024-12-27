Shader "Outlined/PositionAsColor"
{
	Properties
	{
		_MinPos ("Minimum Position", Vector) = (-1, -1, -1, 0)
		_MaxPos ("Maximum Position", Vector) = (1, 1, 1, 0)
	}

	SubShader
	{
		Tags { "RenderPipeline" = "UniversalRenderPipeline" }
		LOD 100

		Pass
		{
			Name "UniversalForward"
			Tags { "LightMode" = "UniversalForward" }

			ZTest LEqual
			ZWrite On

			HLSLPROGRAM

			#pragma vertex Vertex
			#pragma fragment Fragment

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Assets/Graphics/Shader Includes/GeneralUtilities.hlsl"

			float3 _MinPos;
			float3 _MaxPos;

			struct Attributes
			{
				float3 positionOS : POSITION;
			};

			struct Interpolators
			{
				float4 positionCS : SV_POSITION;
				float3 positionWS : TEXCOORD2;
			};

			float3 RemapPosition(float3 position, float3 min, float3 max)
			{
				float3 remapped = position;

				remapped.x = RemapZeroOne(remapped.x, min.x, max.x);
				remapped.y = RemapZeroOne(remapped.y, min.y, max.y);
				remapped.z = RemapZeroOne(remapped.z, min.z, max.z);

				return remapped;
			}

			Interpolators Vertex(Attributes input)
			{
				Interpolators output;

				float3 posOS = input.positionOS.xyz;
				VertexPositionInputs posnInputs = GetVertexPositionInputs(posOS);
				VertexPositionInputs centerInputs = GetVertexPositionInputs(float3(0.0f, 0.0f, 0.0f));

				output.positionCS = posnInputs.positionCS;
                output.positionWS = centerInputs.positionWS;

				return output;
			}

			float4 Fragment(Interpolators input) : SV_TARGET
			{
				float3 remapped = RemapPosition(input.positionWS, _MinPos, _MaxPos);

				return float4(remapped, 1.0f);
			}

			ENDHLSL
		}
	}
}