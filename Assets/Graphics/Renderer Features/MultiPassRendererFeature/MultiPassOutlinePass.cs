using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

using System.Collections.Generic;

public class MultiPassOutlinePass : ScriptableRenderPass
{
    private MultiPassOutlineSettings settings;
    private Color colorForClear;

    private List<ShaderTagId> firstPassTags;
    private List<ShaderTagId> secondPassTags;

    private FilteringSettings filteringSettings;

    private RTHandle rtTempColor;
    private RTHandle rtBaseColor;

    private Material material;

    public MultiPassOutlinePass(string[] tags, MultiPassOutlineSettings settings, Material material)
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
        RTHandle depthTarget = renderingData.cameraData.renderer.cameraDepthTargetHandle;

        ConfigureTarget(camTarget, depthTarget);
        ConfigureClear(ClearFlag.Color, colorForClear);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        CommandBuffer cmd = CommandBufferPool.Get();

        RTHandle camTarget = renderingData.cameraData.renderer.cameraColorTargetHandle;
        SortingCriteria sortingCriteria = renderingData.cameraData.defaultOpaqueSortFlags;

        using (new ProfilingScope(cmd, new ProfilingSampler("Draw Outline Maps")))
        {
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();

            cmd.SetGlobalTexture("_BaseColorTexture", rtBaseColor);

            DrawingSettings drawingSettings = CreateDrawingSettings(firstPassTags, ref renderingData, sortingCriteria);
            context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref filteringSettings);

            Blitter.BlitCameraTexture(cmd, camTarget, rtBaseColor);
        }

        using (new ProfilingScope(cmd, new ProfilingSampler("Draw Objects and Outlines")))
        {
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();

            cmd.SetGlobalTexture("_OutlineMapsTexture", camTarget);

            DrawingSettings drawingSettings = CreateDrawingSettings(secondPassTags, ref renderingData, sortingCriteria);
            context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref filteringSettings);

            material.SetVector("_SampleRange", settings.SampleRange);
            material.SetColor("_OutlineColor", settings.OutlineColor);
            material.SetFloat("_Threshold", settings.Threshold);
            material.SetFloat("_Tightening", settings.Tightening);

            Blitter.BlitCameraTexture(cmd, camTarget, rtTempColor, material, 0);
            Blitter.BlitCameraTexture(cmd, rtTempColor, camTarget);
        }

        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        CommandBufferPool.Release(cmd);
    }

    public void Dispose()
    {
        rtTempColor?.Release();
        rtBaseColor?.Release();
    }
}