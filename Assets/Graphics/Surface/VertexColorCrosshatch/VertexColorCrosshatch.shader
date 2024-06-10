Shader "Outlined/VertexColorCrosshatch"
{
    Properties
    {
        [Header(Base)][Space]
        _LightColor ("Light Color", Color) = (1, 1, 1, 1)
        _DarkColor ("Dark Color", Color) = (0, 0, 0, 1)

        [Space]

        _LightOffset ("Light Offset", Float) = 1

        [Header(Outline Rendering)][Space]
        _CrossTexture ("Cross Hatch Texture", 2D) = "white" {}

        _HatchThreshold0 ("Single Hatch Threshold", Float) = 0.5
        _HatchThreshold1 ("Double Hatch Threshold", Float) = 0.7
        _HatchThreshold2 ("Triple Hatch Threshold", Float) = 0.9
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

            float4 _LightColor, _DarkColor;
            float _LightOffset;

            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Interpolators
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD2;
                float3 normalWS : TEXCOORD3;
            };

            float GetLightLevel(float3 normal, float3 worldPos)
            {
                float4 shadowCoord = TransformWorldToShadowCoord(worldPos);

                Light light = GetMainLight(shadowCoord);
                float NdotL = dot(normal, light.direction) * 0.5f + 0.5f;

                float extraLights;
                int addLightCount = GetAdditionalLightsCount();

                for (int i = 0; i < addLightCount; i++)
                {
                    Light addLight = GetAdditionalLight(i, worldPos);

                    float NdotAdd = dot(normal, addLight.direction) * 0.5f + 0.5f;
                    float attenuation = addLight.color.r * addLight.distanceAttenuation * addLight.shadowAttenuation;

                    extraLights += NdotAdd * attenuation;
                }

                float mainLight = NdotL * light.shadowAttenuation * light.color.r;

                return mainLight + extraLights;
            }

            Interpolators Vertex(Attributes input)
            {
	            Interpolators output;
                
                float3 posOS = input.positionOS.xyz;

                VertexPositionInputs posnInputs = GetVertexPositionInputs(posOS);
	            VertexNormalInputs normInputs = GetVertexNormalInputs(input.normalOS);

	            output.positionCS = posnInputs.positionCS;
                output.positionWS = posnInputs.positionWS;
                output.normalWS = normInputs.normalWS;

	            return output;
            }

            float4 Fragment(Interpolators input) : SV_TARGET
            {
	            float light = GetLightLevel(input.normalWS, input.positionWS);

                return lerp(_DarkColor, _LightColor, light + _LightOffset);
            }
            ENDHLSL
        }

        Pass
        {
            Name "OutlineMaps"
            Tags{"LightMode" = "OutlineMaps"}

            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
	            float4 color : COLOR;
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;

                float2 uv : TEXCOORD1;
            };

            struct Interpolators
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD2;
                float3 normalWS : TEXCOORD3;
                float4 color : COLOR;

                float2 uv : TEXCOORD1;
            };

            TEXTURE2D(_CrossTexture);
            SamplerState sampler_point_repeat;

            float4 _CrossTexture_ST;

            float _HatchThreshold0, _HatchThreshold1, _HatchThreshold2;

            float GetLightLevel(float3 normal, float3 worldPos)
            {
                float4 shadowCoord = TransformWorldToShadowCoord(worldPos);

                Light light = GetMainLight(shadowCoord);
                float NdotL = dot(normal, light.direction);

                float extraLights;
                int addLightCount = GetAdditionalLightsCount();

                for (int i = 0; i < addLightCount; i++)
                {
                    Light addLight = GetAdditionalLight(i, worldPos);

                    float NdotAdd = dot(normal, addLight.direction);
                    float attenuation = addLight.color.r * (addLight.distanceAttenuation * addLight.shadowAttenuation);

                    extraLights += NdotAdd * attenuation;
                }

                float mainLight = NdotL * light.shadowAttenuation * light.color.r;

                return mainLight + extraLights;
            }

            float Crosshatch(float light, float2 uv)
            {
                float4 color = _CrossTexture.Sample(sampler_point_repeat, uv);

                float darkness = clamp(1 - light, 0, 1);

                float hatch0 = step(_HatchThreshold0, darkness);
                float hatch1 = step(_HatchThreshold1, darkness);
                float hatch2 = step(_HatchThreshold2, darkness);

                return (hatch0 * color.r) + (hatch1 * color.g) + (hatch2 * color.b);
            }

            Interpolators Vertex(Attributes input)
            {
	            Interpolators output;
                
                float3 posOS = input.positionOS.xyz;

                VertexPositionInputs posnInputs = GetVertexPositionInputs(posOS);
	            VertexNormalInputs normInputs = GetVertexNormalInputs(input.normalOS);

	            output.positionCS = posnInputs.positionCS;
                output.positionWS = posnInputs.positionWS;
                output.normalWS = normInputs.normalWS;
                output.color = input.color;

                output.uv = TRANSFORM_TEX(input.uv, _CrossTexture);

	            return output;
            }

            float4 Fragment(Interpolators input) : SV_TARGET
            {
                float light = GetLightLevel(input.normalWS, input.positionWS);

                float3 output;
                output.r = input.color.r;
                output.g = Crosshatch(light, input.uv);
                output.b = 0.0f;

	            return float4(output, 0.0f);
            }
            ENDHLSL

        }
    }
}
