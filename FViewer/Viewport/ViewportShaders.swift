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
    float4 dissolve;
    float4 dissolveColor;
    float4 dissolveUv;
    float4 dissolveOffset;
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
                                 texture2d<float> map [[texture(0)]], texture2d<float> dissolveMap [[texture(1)]], sampler mapSampler [[sampler(0)]]) {
    float4 color = in.color;
    float glow = -1.0;
    if (u.dissolve.w > 0.5) {
        float2 centred = in.uv - 0.5;
        float2 where = float2(u.dissolveUv.x * centred.x + u.dissolveUv.y * centred.y, u.dissolveUv.z * centred.x + u.dissolveUv.w * centred.y) + u.dissolveOffset.xy + 0.5;
        float n = dissolveMap.sample(mapSampler, where).r;
        if (u.dissolve.z > 0.5) n = 1.0 - n;
        if (n < u.dissolve.x) discard_fragment();
        glow = 1.0 - smoothstep(0.0, u.dissolve.y, n - u.dissolve.x);
    }
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
    if (glow > 0.0) color.rgb += u.dissolveColor.rgb * glow;
    return color;
}

struct PostOut {
    float4 position [[position]];
    float2 uv;
};

struct PostUniforms {
    float4 center[4];
    float4 shape[4];
    float4 count;
};

vertex PostOut postVertex(uint id [[vertex_id]]) {
    PostOut out;
    float2 p = float2(float((id << 1) & 2), float(id & 2));
    out.position = float4(p * 2.0 - 1.0, 0.0, 1.0);
    out.uv = float2(p.x, 1.0 - p.y);
    return out;
}

fragment float4 bloomFragment(PostOut in [[stage_in]], constant float4 &u [[buffer(0)]],
                              texture2d<float> map [[texture(0)]], sampler mapSampler [[sampler(0)]]) {
    float3 color = map.sample(mapSampler, in.uv).rgb;
    float3 glow = float3(0.0);
    float total = 0.0;
    for (int k = 0; k < 40; k++) {
        float turn = float(k) * 2.39996;
        float ring = sqrt((float(k) + 0.5) / 40.0);
        float2 offset = float2(cos(turn), sin(turn)) * ring * u.z * float2(1.0 / u.w, 1.0);
        float3 tap = map.sample(mapSampler, in.uv + offset).rgb;
        float bright = max(max(tap.r, tap.g), tap.b);
        float weight = 1.0 - ring * 0.7;
        glow += tap * smoothstep(u.x, u.x + 0.25, bright) * weight;
        total += weight;
    }
    return float4(color + glow / total * u.y, 1.0);
}

fragment float4 postFragment(PostOut in [[stage_in]], constant PostUniforms &u [[buffer(0)]],
                             texture2d<float> map [[texture(0)]], sampler mapSampler [[sampler(0)]]) {
    float3 color = map.sample(mapSampler, in.uv).rgb;
    float aspect = u.count.y;
    for (int i = 0; i < int(u.count.x); i++) {
        float2 center = u.center[i].xy;
        int kind = int(u.center[i].z + 0.5);
        float strength = clamp(u.center[i].w, 0.0, 1.0);
        float reach = u.shape[i].x;
        float2 away = in.uv - center;
        float distance = length(away * float2(aspect, 1.0));
        float inner = u.shape[i].y, outer = u.shape[i].z;
        float weight = outer > inner ? smoothstep(inner, outer, distance) : 1.0;
        float3 sum = float3(0.0);
        if (kind == 7) {
            for (int k = 0; k < 16; k++) sum += map.sample(mapSampler, in.uv - away * reach * weight * (float(k) / 15.0)).rgb;
            color = mix(color, sum / 16.0, strength);
        } else if (kind == 5) {
            float2 direction = float2(cos(u.shape[i].w), sin(u.shape[i].w)) * float2(1.0 / aspect, 1.0) * reach;
            for (int k = 0; k < 16; k++) sum += map.sample(mapSampler, in.uv + direction * (float(k) / 15.0 - 0.5)).rgb;
            color = mix(color, sum / 16.0, strength);
        } else if (kind == 4) {
            for (int k = 0; k < 16; k++) {
                float turn = float(k) * 2.39996;
                float2 offset = float2(cos(turn), sin(turn)) * sqrt((float(k) + 0.5) / 16.0) * reach * float2(1.0 / aspect, 1.0);
                sum += map.sample(mapSampler, in.uv + offset * weight).rgb;
            }
            color = mix(color, sum / 16.0, strength);
        } else if (kind == 3) {
            float2 shift = away * reach * weight * strength;
            color.r = map.sample(mapSampler, in.uv - shift).r;
            color.b = map.sample(mapSampler, in.uv + shift).b;
        }
    }
    return float4(color, 1.0);
}
"""
}
