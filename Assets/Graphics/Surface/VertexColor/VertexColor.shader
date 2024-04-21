Shader "Unlit/VertexColor"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" }
        LOD 100

        Pass
        {
            Name "UniversalForward"
            Tags{"LightMode" = "UniversalForward"}

            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            float4 _Color;

            struct Attributes
            {
	            float3 positionOS : POSITION;
            };

            struct Interpolators
            {
	            float4 positionCS : SV_POSITION;
            };

            Interpolators Vertex(Attributes input)
            {
	            Interpolators output;
                
	            VertexPositionInputs posnInputs = GetVertexPositionInputs(input.positionOS);
                
	            output.positionCS = posnInputs.positionCS;
                
	            return output;
            }

            float4 Fragment(Interpolators input) : SV_TARGET
            {
	            return _Color;
            }
            ENDHLSL
        }

        Pass
        {
            Name "VertexColor"
            Tags{"LightMode" = "VertexColor"}

            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
	            float4 color : COLOR;
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Interpolators
            {
	            float4 color : COLOR;
                float4 positionCS : SV_POSITION;
            };

            Interpolators Vertex(Attributes input)
            {
	            Interpolators output;
                
                float3 posOS = input.positionOS.xyz;

                VertexPositionInputs posnInputs = GetVertexPositionInputs(posOS);
	            output.positionCS = posnInputs.positionCS;
                output.color = input.color;

	            return output;
            }

            float4 Fragment(Interpolators input) : SV_TARGET
            {
	            return input.color;
            }
            ENDHLSL

        }
    }
}
