Shader "Screen/SobelOutline"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 100
        ZWrite Off
        Cull Off

        Pass
        {
            Name "Outline"

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            #pragma vertex Vert
            #pragma fragment frag

            float2 _SampleRange;
			float4 _OutlineColor;

            float _Threshold;
            float _Tightening;

            SamplerState sampler_point_clamp;
            TEXTURE2D(_VertexColorTexture);
            TEXTURE2D(_BaseColorTexture);

            static float2 samplePoints[9] =
            {
				float2(-1, 1), float2(0, 1), float2(1, 1),
				float2(-1, 0), float2(0, 0), float2(1, 0),
				float2(-1, -1), float2(0, -1), float2(1, -1)
			};

			static float sobelXMatrix[9] =
            {
				1, 0, -1,
				2, 0, -2,
				1, 0, -1
			};

			static float sobelYMatrix[9] =
            {
				1, 2, 1,
				0, 0, 0,
				-1, -2, -1
			};

            float Outline(float2 UV, float2 sampleRange, float threshold, float tightening, float opacity)
            {
                float2 sobelR = 0;
                float2 sobelG = 0;
                float2 sobelB = 0;

                [unroll]
                for (int i = 0; i < 9; i++)
                {
                    float3 color = _VertexColorTexture.Sample(sampler_point_clamp, UV + (samplePoints[i] * sampleRange)).rgb;

                    float2 kernel = float2(sobelXMatrix[i], sobelYMatrix[i]);

                    sobelR += color.r * kernel;
                    sobelG += color.g * kernel;
                    sobelB += color.b * kernel;
                }

                float maxLength = max(length(sobelR), max(length(sobelG), length(sobelB)));
                
                float outline = step(threshold, maxLength);

                outline = pow(outline, tightening);

                return outline * opacity;
            }

            half4 frag (Varyings input) : SV_Target
            {
                float4 color = _BaseColorTexture.Sample(sampler_point_clamp, input.texcoord);
                float outline = Outline(input.texcoord, _SampleRange, _Threshold, _Tightening, _OutlineColor.a);

                return lerp(color, _OutlineColor, outline);
            }

            ENDHLSL
        }
    }
}
