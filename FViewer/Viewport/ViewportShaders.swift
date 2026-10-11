enum ViewportShaders {
    static let source = """
#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float4 color [[attribute(2)]];
    float2 uv [[attribute(3)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 normal;
    float4 color;
    float2 uv;
    float3 world;
    float size [[point_size]];
};

struct Uniforms {
    float4x4 viewProjection;
    float4x4 model;
    float4 tint;
    float4 options;
    float4 lightPosition[4];
    float4 lightColor[4];
};

vertex VertexOut viewportVertex(VertexIn in [[stage_in]], constant Uniforms &u [[buffer(1)]]) {
    VertexOut out;
    float4 world = u.model * float4(in.position, 1.0);
    out.position = u.viewProjection * world;
    out.world = world.xyz;
    out.normal = (u.model * float4(in.normal, 0.0)).xyz;
    out.color = in.color * u.tint;
    out.uv = in.uv;
    out.size = u.options.z;
    return out;
}

fragment float4 viewportFragment(VertexOut in [[stage_in]], constant Uniforms &u [[buffer(1)]],
                                 texture2d<float> map [[texture(0)]], sampler mapSampler [[sampler(0)]]) {
    float4 color = in.color;
    if (u.options.y > 0.5) {
        color *= map.sample(mapSampler, in.uv);
    }
    if (u.options.x > 0.5) {
        float3 n = normalize(in.normal);
        float light = 0.45 + 0.55 * abs(dot(n, normalize(float3(0.4, 0.8, 0.45))));
        color.rgb *= light;
    }
    if (u.options.w > 0.5) {
        float3 n = normalize(in.normal);
        float3 added = float3(0.0);
        for (int i = 0; i < 4; i++) {
            float3 toLight = u.lightPosition[i].xyz - in.world;
            float d = max(length(toLight), 0.001);
            float range = u.lightColor[i].w;
            float decay = u.lightPosition[i].w;
            float falloff = range > 0.0 ? pow(clamp(1.0 - d / range, 0.0, 1.0), decay) : 1.0 / pow(max(d, 0.25), decay);
            added += u.lightColor[i].rgb * falloff * max(dot(n, toLight / d), 0.0);
        }
        color.rgb += in.color.rgb * added * 1.27;
    }
    return color;
}
"""
}
