using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

using System.Collections.Generic;

public class MultiPassRenderPass : ScriptableRenderPass
{
    private MultiPassSettings settings;
    private Color colorForClear;

    private List<ShaderTagId> firstPassTags;
    private List<ShaderTagId> secondPassTags;

    private FilteringSettings filteringSettings;

    private RTHandle rtTempColor;
    private RTHandle rtBaseColor;

    private Material material;

    public MultiPassRenderPass(string[] tags, MultiPassSettings settings, Material material)
    {
        filteringSettings = FilteringSettings.defaultValue;
        firstPassTags = new List<ShaderTagId>();
        secondPassTags = new List<ShaderTagId>();

        for (int i = 0; i < tags.Length; i++)
        {
            firstPassTags.Add(new ShaderTagId(tags[i]));
        }

        secondPassTags.Add(new ShaderTagId("SRPDefaultUnlit"));
        secondPassTags.Add(new ShaderTagId("UniversalForward"));
        secondPassTags.Add(new ShaderTagId("UniversalForwardOnly"));

        this.settings = settings;
        this.material = material;
        colorForClear = settings.ClearColor;
    }

    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        RenderTextureDescriptor descriptor = renderingData.cameraData.cameraTargetDescriptor;
        descriptor.depthBufferBits = 0;

        _ = RenderingUtils.ReAllocateIfNeeded(ref rtBaseColor, descriptor, name: "_BaseColorTexture");
        _ = RenderingUtils.ReAllocateIfNeeded(ref rtTempColor, descriptor, name: "_TemporaryColorTexture");

        RTHandle camTarget = renderingData.cameraData.renderer.cameraColorTargetHandle;

        ConfigureTarget(camTarget);
        ConfigureClear(ClearFlag.Color, colorForClear);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        CommandBuffer cmd = CommandBufferPool.Get();

        RTHandle camTarget = renderingData.cameraData.renderer.cameraColorTargetHandle;
        SortingCriteria sortingCriteria = renderingData.cameraData.defaultOpaqueSortFlags;

        using (new ProfilingScope(cmd, new ProfilingSampler("Vertex Color Pass")))
        {
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();

            DrawingSettings drawingSettings = CreateDrawingSettings(firstPassTags, ref renderingData, sortingCriteria);
            context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref filteringSettings);

            Blitter.BlitCameraTexture(cmd, camTarget, rtBaseColor);
            cmd.SetGlobalTexture("_BaseColorTexture", rtBaseColor);
        }

        using (new ProfilingScope(cmd, new ProfilingSampler("Outline Pass")))
        {
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();

            DrawingSettings drawingSettings = CreateDrawingSettings(secondPassTags, ref renderingData, sortingCriteria);
            context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref filteringSettings);

            material.SetFloat("_SampleRange", settings.SampleRange);
            material.SetColor("_OutlineColor", settings.OutlineColor);
            material.SetFloat("_Threshold", settings.Threshold);
            material.SetFloat("_Tightening", settings.Tightening);

            cmd.SetGlobalTexture("_VertexColorTexture", camTarget);

            Blitter.BlitCameraTexture(cmd, camTarget, rtTempColor, material, 0);
            Blitter.BlitCameraTexture(cmd, rtTempColor, camTarget);
        }

        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        CommandBufferPool.Release(cmd);
    }

    public void Dispose()
    {
        rtTempColor.Release();
        rtBaseColor?.Release();
    }
}