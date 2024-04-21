using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[System.Serializable]
public class MultiPassSettings
{
    [field: SerializeField] public bool ShowInSceneView { get; set; }
    [field: SerializeField] public RenderPassEvent RenderPassEvent { get; set; } = RenderPassEvent.AfterRenderingOpaques;

    [field: Header("Draw Renderers Settings"), SerializeField] public string[] LightModePasses { get; set; } = new string[] { "" };
    [field: SerializeField] public Color ClearColor { get; set; }

    [field: Header("Outline Settings"), SerializeField] public Vector2 SampleRange { get; set; }
    [field: SerializeField] public Color OutlineColor { get; set; }
    [field: SerializeField] public float Threshold { get; set; }
    [field: SerializeField] public float Tightening { get; set; }
}