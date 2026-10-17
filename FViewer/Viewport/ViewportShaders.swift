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
    float4x4 dissolveShape;
    float4 dissolveInfo;
    float4 dissolveBands[3];
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
    float4 band = float4(0.0);
    if (u.dissolve.w > 0.5 && u.dissolveOffset.w > 0.5) {
        float3 p = (u.dissolveShape * float4(in.world, 1.0)).xyz;
        int shape = int(u.dissolveInfo.x + 0.5);
        float d;
        if (shape == 2) d = length(p) - 0.5;
        else if (shape == 3) d = max(length(p.xz) - 0.5, abs(p.y) - 0.5);
        else d = max(max(abs(p.x), abs(p.y)), abs(p.z)) - 0.5;
        if (u.dissolve.z > 0.5) d = -d;
        if (d < 0.0) discard_fragment();
        if (u.dissolveOffset.z > 0.5 && u.dissolve.x > 0.0) {
            float2 centred = in.uv - 0.5;
            float2 where = float2(u.dissolveUv.x * centred.x + u.dissolveUv.y * centred.y, u.dissolveUv.z * centred.x + u.dissolveUv.w * centred.y) + u.dissolveOffset.xy + 0.5;
            if (dissolveMap.sample(mapSampler, where).r < u.dissolve.x) discard_fragment();
        }
        float a = u.dissolveInfo.y, b = a + u.dissolveInfo.z, c = b + u.dissolveInfo.w;
        if (d < a) band = u.dissolveBands[0];
        else if (d < b) band = u.dissolveBands[1];
        else if (d < c) band = u.dissolveBands[2];
    } else if (u.dissolve.w > 0.5) {
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
    if (band.a > 0.0) color.rgb = mix(color.rgb, band.rgb, band.a);
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
    float4 extra[4];
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
        float4 extra = u.extra[i];
        float r2 = dot(away, away);
        float donutG = u.shape[i].w > 0.0 ? 0.5 / u.shape[i].w : 1e6;
        float donutIn = inner > 0.0 ? 1.0 + donutG * (r2 / (0.25 * inner * inner) - 1.0) : 1e6;
        float donutOut = outer > 0.0 ? 0.5 + donutG * (1.0 - r2 / (0.25 * outer * outer)) : -1e6;
        float donut = clamp(min(donutIn, donutOut), 0.0, 1.0);
        if (kind == 3 && extra.w > 0.5) {
            float2 base = in.uv - away * extra.x * extra.z;
            float2 shift = away * extra.y * extra.z;
            float3 split = float3(map.sample(mapSampler, base - shift).r, map.sample(mapSampler, base).g, map.sample(mapSampler, base + shift).b);
            color = mix(color, split, clamp(max(u.center[i].w, 0.0) * donut, 0.0, 1.0));
            continue;
        }
        if (kind == 4 && extra.w > 0.5) {
            for (int k = 0; k < 16; k++) {
                float turn = float(k) * 2.39996;
                float2 offset = float2(cos(turn), sin(turn)) * sqrt((float(k) + 0.5) / 16.0) * reach * float2(1.0 / aspect, 1.0);
                sum += map.sample(mapSampler, in.uv + offset).rgb;
            }
            color = mix(color, sum / 16.0, clamp(strength * donut, 0.0, 1.0));
            continue;
        }
        if (kind == 5 && extra.w > 0.5) {
            float2 direction = float2(cos(u.shape[i].w), sin(u.shape[i].w)) * float2(1.0 / aspect, 1.0) * reach;
            for (int k = 0; k < 16; k++) sum += map.sample(mapSampler, in.uv + direction * (float(k) / 15.0 - (extra.x > 0.5 ? 0.0 : 0.5))).rgb;
            color = mix(color, sum / 16.0, strength);
            continue;
        }
        if (kind == 7 && u.count.z > 0.5) {
            for (int k = 0; k < 24; k++) sum += map.sample(mapSampler, center + away * (1.0 - reach * (float(k) + 0.5) / 24.0)).rgb;
            float gradation = u.shape[i].w;
            float g = gradation > 0.0 ? 0.5 / gradation : 1e6;
            float r2 = dot(away, away);
            float innerMask = inner > 0.0 ? 1.0 + g * (r2 / (0.25 * inner * inner) - 1.0) : 1e6;
            float outerMask = outer > 0.0 ? 0.5 + g * (1.0 - r2 / (0.25 * outer * outer)) : -1e6;
            color = mix(color, sum / 24.0, clamp(max(u.center[i].w, 0.0) * clamp(min(innerMask, outerMask), 0.0, 1.0), 0.0, 1.0));
        } else if (kind == 7) {
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
