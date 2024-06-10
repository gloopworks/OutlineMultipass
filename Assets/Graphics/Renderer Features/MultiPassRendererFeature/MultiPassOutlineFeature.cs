using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class MultiPassOutlineFeature : ScriptableRendererFeature
{
    [SerializeField] private MultiPassOutlineSettings settings;
    [SerializeField] private Shader shader;
    private Material material;

    private MultiPassOutlinePass mainPass;
    
    public override void Create()
    {
        material = CoreUtils.CreateEngineMaterial(shader);

        mainPass = new MultiPassOutlinePass(settings.LightModePasses, settings, material)
        {
            renderPassEvent = settings.RenderPassEvent
        };
    }
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
#if UNITY_EDITOR
        CameraType cameraType = renderingData.cameraData.cameraType;
        if (cameraType == CameraType.Preview)
        {
            return;
        }
        if (!settings.ShowInSceneView && cameraType == CameraType.SceneView)
        {
            return;
        }
#endif
        renderer.EnqueuePass(mainPass);
    }

    protected override void Dispose(bool disposing)
    {
        mainPass.Dispose();
    }
}
