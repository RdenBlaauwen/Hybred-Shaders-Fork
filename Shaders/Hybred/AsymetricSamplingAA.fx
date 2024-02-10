#include "ReShade.fxh"

#define PHI (1.6180339887498)

uniform uint frame_count < source = "framecount"; >;

struct VSOUT { float4 vpos : SV_POSITION; float2 uv : TEXCOORD0; };

uniform float JitterAmount < \
    ui_label = "Jitter Amount"; \
    ui_min = 0.0; \
    ui_max = 2.0; \
    ui_step = 0.01; \
    ui_type = "slider"; \
    ui_tooltip = "How much the noise moves, which is what causes the AA effect"; \
> = 0.35;

uniform float BlurAmount < \
    ui_label = "Blur Amount"; \
    ui_min = 0.0; \
    ui_max = 1.0; \
    ui_step = 0.05; \
    ui_type = "slider"; \
    ui_tooltip = "How much blurring occurs"; \
> = 0.5;

uniform float LuminanceThreshold < \
    ui_label = "Luma Edge Threshold"; \
    ui_min = 0.0; \
    ui_max = 0.25; \
    ui_step = 0.01; \
    ui_type = "slider"; \
    ui_tooltip = "Strength of edge detection, affects what the noise is applied to"; \
> = 0.1;

texture2D ColorTex : COLOR;
sampler2D sColorTex { Texture = ColorTex; };

// https://www.shadertoy.com/view/ltB3zD
float GetGoldNoise(float2 vpos, float seed){
    float n = frac(tan(distance(vpos * PHI, vpos) * seed) * vpos.x);
    n = isnan(n) ? 0.0 : n;
    return n;
}

void PS_Main(in VSOUT i, out float3 o : SV_Target0)
{
    float noise = GetGoldNoise(i.vpos.xy, frame_count % 16 + 1);
    i.uv += (noise * 2.0 - 1.0) * BUFFER_PIXEL_SIZE * JitterAmount;

    float blur = BlurAmount;
    float2 blurDir = float2(blur, 0.0) * BUFFER_PIXEL_SIZE;
    float3 blurredSample = 0.25 * (
        tex2D(sColorTex, i.uv - blurDir.xy).rgb +
        tex2D(sColorTex, i.uv + blurDir.xy).rgb +
        tex2D(sColorTex, i.uv - blurDir.yx).rgb +
        tex2D(sColorTex, i.uv + blurDir.yx).rgb
    );

    o = blurredSample;
}

technique ASAA3
{
    pass { VertexShader = PostProcessVS; PixelShader = PS_Main; }
}
