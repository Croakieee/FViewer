let particleShaderSource = """
#include <metal_stdlib>
using namespace metal;

struct VertexUniforms {
    float4x4 placement;
    float4 view;
    float4 pan;
};

struct FragmentUniforms {
    float3x3 uv0;
    float3x3 uv1;
    float3x3 uv2;
    float3x3 uv3;
    float3x3 uvDistort;
    float4 particleColor;
    float4 edgeInner;
    float4 edgeOuter;
    float4 nineSlice;
    float4 uvChannel;
    float4 layerMode;
    float4 layerAlphaMode;
    float4 layerColorToAlpha;
    float4 layerDistort;
    float4 misc0;
    float4 misc1;
};

struct VOut {
    float4 position [[position]];
    float2 uv1;
    float2 uv2;
    float2 uv3;
    float2 uv4;
    float4 color;
    float band;
};

vertex VOut particleVertex(uint vid [[vertex_id]],
                           const device float2 *pos [[buffer(0)]],
                           const device float2 *uv [[buffer(1)]],
                           const device float2 *uv2 [[buffer(2)]],
                           const device float2 *uv3 [[buffer(3)]],
                           const device float2 *uv4 [[buffer(4)]],
                           const device float4 *color [[buffer(5)]],
                           const device float *z [[buffer(6)]],
                           constant VertexUniforms &u [[buffer(7)]]) {
    VOut o;
    float4 e = u.placement * float4(pos[vid], z[vid], 1.0);
    float d = u.view.w;
    float w = d > 0.0 ? max((d - e.z) / d, 0.05) : 1.0;
    float2 s = e.xy / w * u.view.z + u.pan.xy;
    o.position = float4(float2(s.x / u.view.x, -s.y / u.view.y) * w, 0.0, w);
    o.uv1 = uv[vid] - 0.5;
    o.uv2 = uv2[vid] - 0.5;
    o.uv3 = uv3[vid] - 0.5;
    o.uv4 = uv4[vid] - 0.5;
    o.color = color[vid];
    o.band = uv[vid].y;
    return o;
}

static float2 channelUv(VOut i, float c) {
    return c < 1.5 ? i.uv1 : c < 2.5 ? i.uv2 : c < 3.5 ? i.uv3 : i.uv4;
}

static float2 uvOf(float3x3 m, VOut i, float channel) {
    return (m * float3(channelUv(i, channel), 1.0)).xy + 0.5;
}

static float slice(float q, float border, float stretch) {
    float e = min(border / stretch, 0.5);
    if (q < e) return q * border / e;
    if (q > 1.0 - e) return 1.0 - (1.0 - q) * border / e;
    return border + (q - e) * (1.0 - 2.0 * border) / max(1.0 - 2.0 * e, 1e-5);
}

static float4 straight(float4 c) {
    return c.a > 0.0 ? float4(c.rgb / c.a, c.a) : float4(0.0);
}

static float4 colorToAlpha(float4 c, float on) {
    return on > 0.5 ? float4(1.0, 1.0, 1.0, dot(c.rgb, float3(0.299, 0.587, 0.114)) * c.a) : c;
}

static float4 applyLayer(float4 c, texture2d<float> tex, sampler smp, float3x3 m, VOut i, float channel,
                         float mode, float alphaMode, float c2a, float distort, float2 offset) {
    if (mode < 0.5) return c;
    float4 l = colorToAlpha(straight(tex.sample(smp, uvOf(m, i, channel) + offset * distort)), c2a);
    if (mode < 1.5) c.rgb *= l.rgb;
    else if (mode < 2.5) c.rgb += l.rgb;
    else if (mode < 3.5) {}
    else if (mode < 4.5) c.rgb = max(c.rgb, l.rgb);
    else c.rgb = min(c.rgb, l.rgb);
    if (alphaMode < 0.5) c.a *= l.a;
    return c;
}

fragment float4 particleFragment(VOut i [[stage_in]],
                                 constant FragmentUniforms &u [[buffer(0)]],
                                 texture2d<float> base [[texture(0)]],
                                 texture2d<float> layer0 [[texture(1)]],
                                 texture2d<float> layer1 [[texture(2)]],
                                 texture2d<float> layer2 [[texture(3)]],
                                 texture2d<float> distortTex [[texture(4)]],
                                 sampler baseSmp [[sampler(0)]],
                                 sampler layer0Smp [[sampler(1)]],
                                 sampler layer1Smp [[sampler(2)]],
                                 sampler layer2Smp [[sampler(3)]],
                                 sampler distortSmp [[sampler(4)]]) {
    float2 offset = float2(0.0);
    if (u.misc0.y != 0.0) {
        offset = (distortTex.sample(distortSmp, uvOf(u.uvDistort, i, u.misc0.x)).rg * 2.0 - 1.0) * u.misc0.y;
    }
    float2 b = channelUv(i, u.uvChannel.x);
    if (u.nineSlice.z > 0.0) {
        float2 q = b + 0.5;
        b = float2(slice(q.x, u.nineSlice.x, u.nineSlice.z), slice(q.y, u.nineSlice.y, u.nineSlice.w)) - 0.5;
    }
    float2 uv = (u.uv0 * float3(b, 1.0)).xy + 0.5 + offset * u.misc0.z;
    float4 c = colorToAlpha(straight(base.sample(baseSmp, uv)), u.misc0.w);
    if (u.misc1.x > 0.5) c.rgb = float3(dot(c.rgb, float3(0.299, 0.587, 0.114)));
    c = applyLayer(c, layer0, layer0Smp, u.uv1, i, u.uvChannel.y, u.layerMode.x, u.layerAlphaMode.x, u.layerColorToAlpha.x, u.layerDistort.x, offset);
    c = applyLayer(c, layer1, layer1Smp, u.uv2, i, u.uvChannel.z, u.layerMode.y, u.layerAlphaMode.y, u.layerColorToAlpha.y, u.layerDistort.y, offset);
    c = applyLayer(c, layer2, layer2Smp, u.uv3, i, u.uvChannel.w, u.layerMode.z, u.layerAlphaMode.z, u.layerColorToAlpha.z, u.layerDistort.z, offset);
    c *= u.particleColor * mix(u.edgeInner, u.edgeOuter, i.band) * i.color;
    if (u.misc1.y > 0.0) c.a *= smoothstep(0.0, u.misc1.y, i.band);
    if (u.misc1.z > 0.0) c.a *= smoothstep(0.0, u.misc1.z, 1.0 - i.band);
    c.a = clamp(c.a, 0.0, 1.0);
    return float4(c.rgb * c.a, c.a);
}
"""
