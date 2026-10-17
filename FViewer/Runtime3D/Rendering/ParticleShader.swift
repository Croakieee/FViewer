enum ParticleShader {
    static let source = """
#include <metal_stdlib>
using namespace metal;

struct VIn {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float4 color [[attribute(2)]];
    float2 uv [[attribute(3)]];
    float2 uv2 [[attribute(4)]];
    float2 uv3 [[attribute(5)]];
    float2 uv4 [[attribute(6)]];
};

struct U {
    float4x4 view;
    float4x4 projection;
    float4x4 model;
    float4x4 normalMatrix;
    float4 color;
    float4 colorBegin;
    float4 colorEnd;
    float4 spriteColor;
    float4 spriteCell;
    float4 uvMatrix[5];
    float4 uvOffset[5];
    float4 layer[4];
    float4 channels;
    float4 misc;
    float4 distortLayers;
    float4 flags;
    float4 flags2;
    float4 cameraPosition;
    float4 debugColor;
    float4 scene;
    float4 scene2;
    float4 flags3;
    float4 flags4;
    float4 pixelUv;
    float4 litDirection;
    float4 litAmbient;
    float4 litColor;
    float4 fresnelAxis;
    float4 pointPosition[2];
    float4 pointColor[2];
    float4 normalInfo;
};

struct VOut {
    float4 position [[position]];
    float2 uv1;
    float2 uv2;
    float2 uv3;
    float2 uv4;
    float2 uv5;
    float4 color;
    float3 worldNormal;
    float3 worldPosition;
    float along;
    float viewDistance;
};

static float2 channelUv(VIn in, float c) {
    if (c > 2.5) return in.uv4;
    if (c > 1.5) return in.uv3;
    if (c > 0.5) return in.uv2;
    return in.uv;
}

static float2 transformUv(U u, int slot, float2 uv) {
    float4 m = u.uvMatrix[slot];
    return float2(m.x * uv.x + m.y * uv.y, m.z * uv.x + m.w * uv.y) + u.uvOffset[slot].xy + 0.5;
}

vertex VOut particleVertex(VIn in [[stage_in]], constant U &u [[buffer(1)]]) {
    VOut out;
    out.uv1 = transformUv(u, 0, channelUv(in, u.channels.x));
    out.uv2 = transformUv(u, 1, channelUv(in, u.channels.y));
    out.uv3 = transformUv(u, 2, channelUv(in, u.channels.z));
    out.uv4 = transformUv(u, 3, channelUv(in, u.channels.w));
    out.uv5 = transformUv(u, 4, channelUv(in, u.misc.x));
    if (u.flags.z > 0.5) {
        out.uv1 = u.spriteCell.xy + out.uv1 * u.spriteCell.zw;
    }
    out.color = in.color;
    out.along = in.position.y + 0.5;
    float4 world = u.model * float4(in.position, 1.0);
    float4 mv = u.view * world;
    out.worldPosition = world.xyz;
    out.worldNormal = (u.normalMatrix * float4(in.normal, 0.0)).xyz;
    out.position = u.projection * mv;
    float depthOffset = u.misc.w;
    float pull = u.flags4.y > 0.5 ? depthOffset * length(mv.xyz) : depthOffset;
    out.viewDistance = u.scene2.z > 0.5 ? -(mv.xyz + normalize(-mv.xyz) * pull).z : -mv.z;
    if (depthOffset != 0.0) {
        float4 pulled = u.projection * float4(mv.xyz + normalize(-mv.xyz) * pull, 1.0);
        out.position.z = pulled.z / pulled.w * out.position.w;
    }
    return out;
}

static float4 sampleLayer(texture2d<float> map, sampler s, float2 uv, float4 layer, float2 base, bool footprint) {
    float4 t = footprint ? map.sample(s, uv, gradient2d(dfdx(base), dfdy(base))) : map.sample(s, uv);
    if (layer.w > 0.5) {
        t = float4(1.0, 1.0, 1.0, dot(t.rgb, float3(0.299, 0.587, 0.114)));
    }
    return t;
}

static float4 combine(float4 base, float4 t, float4 layer) {
    float3 rgb;
    int mode = int(layer.y + 0.5);
    if (mode == 9) rgb = base.rgb;
    else if (mode == 1) rgb = base.rgb + t.rgb;
    else if (mode == 2) rgb = base.rgb - t.rgb;
    else if (mode == 3) rgb = max(base.rgb, t.rgb);
    else if (mode == 4) rgb = min(base.rgb, t.rgb);
    else rgb = base.rgb * t.rgb;
    float a;
    int alphaMode = int(layer.z + 0.5);
    if (alphaMode == 1) a = max(base.a, t.a);
    else if (alphaMode == 2) a = min(base.a, t.a);
    else if (alphaMode == 3) a = base.a;
    else a = base.a * t.a;
    return float4(rgb, a);
}

fragment float4 particleFragment(VOut in [[stage_in]], constant U &u [[buffer(1)]],
                                 texture2d<float> map1 [[texture(0)]], texture2d<float> map2 [[texture(1)]],
                                 texture2d<float> map3 [[texture(2)]], texture2d<float> map4 [[texture(3)]],
                                 texture2d<float> map5 [[texture(4)]], texture2d<float> map6 [[texture(5)]],
                                 texture2d<float> sceneColor [[texture(6)]], depth2d_ms<float> sceneDepth [[texture(7)]],
                                 sampler s1 [[sampler(0)]], sampler s2 [[sampler(1)]], sampler s3 [[sampler(2)]],
                                 sampler s4 [[sampler(3)]], sampler s5 [[sampler(4)]], sampler s6 [[sampler(5)]],
                                 texture2d<float> normalMap [[texture(8)]], sampler s7 [[sampler(6)]]) {
    if (u.debugColor.w > 0.0) return u.debugColor;
    float2 uv1 = in.uv1;
    float2 uv2 = in.uv2;
    float2 uv3 = in.uv3;
    float2 uv4 = in.uv4;
    float2 uv5 = in.uv5;
    float2 pixel = in.position.xy / max(u.scene.zw, float2(1.0)) - 0.5;
    if (u.pixelUv.x > 0.5) uv1 = transformUv(u, 0, pixel);
    if (u.pixelUv.y > 0.5) uv2 = transformUv(u, 1, pixel);
    if (u.pixelUv.z > 0.5) uv3 = transformUv(u, 2, pixel);
    if (u.pixelUv.w > 0.5) uv4 = transformUv(u, 3, pixel);
    if (u.flags4.z > 0.5) uv5 = transformUv(u, 4, pixel);
    float2 b1 = uv1, b2 = uv2, b4 = uv4, b5 = uv5;
    bool footprint = u.flags4.w > 0.5 && u.flags2.y > 0.5;
    float2 d = float2(0.0);
    if (u.flags2.y > 0.5) {
        float2 raw = map3.sample(s3, uv3).rg;
        d = (u.flags3.x > 0.5 ? raw - 0.5 : raw * 2.0 - 1.0) * u.misc.y;
        if (u.distortLayers.x > 0.5) uv1 += d;
        if (u.distortLayers.y > 0.5) uv2 += d;
        if (u.distortLayers.z > 0.5) uv4 += d;
        if (u.distortLayers.w > 0.5) uv5 += d;
    }
    float4 t = float4(1.0);
    bool hasT = false;
    if (u.scene.y > 0.5) {
        float2 suv = in.position.xy / u.scene.zw;
        if (u.scene.y > 1.5 && u.flags2.y > 0.5) suv += d;
        t = float4(sceneColor.sample(s6, clamp(suv, float2(0.0), float2(1.0))).rgb, 1.0);
        hasT = true;
    }
    if (u.flags3.w > 0.5) {
        hasT = true;
        if (u.flags3.w > 1.5) t.a = 0.0;
    }
    if (u.layer[0].x > 0.5) {
        t = sampleLayer(map1, s1, uv1, u.layer[0], b1, footprint);
        if (u.layer[0].y < 0.5) {
            if (u.flags4.x > 0.5) t.rgb = float3(1.0);
            else if (u.flags2.w > 0.5) t.rgb = float3(dot(t.rgb, float3(0.299, 0.587, 0.114)));
        }
        if (u.flags3.y > 0.5) {
            float4 pv = t + u.misc.z;
            t = float4(map6.sample(s6, float2(pv.r, 0.5)).r, map6.sample(s6, float2(pv.g, 0.5)).g,
                       map6.sample(s6, float2(pv.b, 0.5)).b, map6.sample(s6, float2(pv.a, 0.5)).a);
        }
        hasT = true;
    }
    float tc1Alpha = t.a;
    if (u.layer[1].x > 0.5) {
        float4 l = sampleLayer(map2, s2, uv2, u.layer[1], b2, footprint);
        t = hasT ? combine(t, l, u.layer[1]) : l;
        if (u.flags3.w > 1.5 && u.layer[1].z < 0.5) t.a = l.a;
        hasT = true;
    }
    if (u.layer[2].x > 0.5) {
        float4 l = sampleLayer(map4, s4, uv4, u.layer[2], b4, footprint);
        t = hasT ? combine(t, l, u.layer[2]) : l;
        hasT = true;
    }
    if (u.layer[3].x > 0.5) {
        float4 l = sampleLayer(map5, s5, uv5, u.layer[3], b5, footprint);
        t = hasT ? combine(t, l, u.layer[3]) : l;
    }
    if (u.flags2.z > 0.5) {
        t.a *= map6.sample(s6, float2(tc1Alpha + u.misc.z, 0.5)).a;
    }
    float4 c = u.color * t;
    if (u.litDirection.w > 0.5) {
        int kind = int(u.litDirection.w + 0.5) - 1;
        float3 l = u.litDirection.xyz;
        float3 surface = normalize(in.worldNormal);
        if (u.normalInfo.x > 0.5) {
            int slot = int(u.normalInfo.y + 0.5);
            float2 nuv = slot == 1 ? uv2 : slot == 2 ? uv3 : slot == 3 ? uv4 : slot == 4 ? uv5 : uv1;
            float3 tn = normalMap.sample(s7, nuv).xyz * 2.0 - 1.0;
            tn.xy *= u.normalInfo.z;
            float3 dp1 = dfdx(in.worldPosition), dp2 = dfdy(in.worldPosition);
            float2 duv1 = dfdx(nuv), duv2 = dfdy(nuv);
            float3 dp2perp = cross(dp2, surface), dp1perp = cross(surface, dp1);
            float3 tangent = dp2perp * duv1.x + dp1perp * duv2.x;
            float3 bitangent = dp2perp * duv1.y + dp1perp * duv2.y;
            float scale = rsqrt(max(max(dot(tangent, tangent), dot(bitangent, bitangent)), 1e-12));
            surface = normalize(tangent * scale * tn.x + bitangent * scale * tn.y + surface * max(tn.z, 0.0));
        }
        float lit;
        if (kind == 2) {
            lit = 0.5 * dot(normalize((u.model * float4(0.0, -1.0, 0.0, 0.0)).xyz), l) + 0.5;
        } else {
            float3 viewDir = normalize(u.cameraPosition.xyz - in.worldPosition);
            float3 seen = float3(l.x, -l.y, l.z);
            seen -= 2.0 * dot(seen, viewDir) * viewDir;
            float3 n = surface;
            lit = kind == 1 ? 0.5 * dot(n, seen) + 0.5 : max(0.0, dot(n, seen));
        }
        float3 points = float3(0.0);
        for (int k = 0; k < 2; k++) {
            if (u.pointColor[k].w <= 0.0) continue;
            float3 toLight = u.pointPosition[k].xyz - in.worldPosition;
            float d = max(length(toLight), 0.01);
            int pointKind = int(u.normalInfo.w + 0.5);
            float facing = pointKind == 3 ? 0.5 * dot(normalize((u.model * float4(0.0, -1.0, 0.0, 0.0)).xyz), toLight / d) + 0.5
                : pointKind == 1 ? 0.5 * dot(surface, toLight / d) + 0.5 : max(0.0, dot(surface, toLight / d));
            points += u.pointColor[k].rgb * facing * min(1.0, u.pointColor[k].w / pow(d, u.pointPosition[k].w));
        }
        c.rgb *= u.litAmbient.xyz + u.litColor.xyz * lit + points;
    }
    if (u.flags.x > 0.5) c *= in.color;
    if (u.flags.z > 0.5) c *= u.spriteColor;
    if (u.flags.y > 0.5) {
        float3 toward = u.fresnelAxis.w > 0.5 ? u.fresnelAxis.xyz : normalize(u.cameraPosition.xyz - in.worldPosition);
        float facing = abs(dot(normalize(in.worldNormal), toward));
        c *= mix(u.colorEnd, u.colorBegin, 1.0 - facing);
    }
    if (u.flags.w > 0.5) c *= mix(u.colorEnd, u.colorBegin, in.along);
    if (u.scene.x > 0.0) {
        float d = sceneDepth.read(uint2(in.position.xy), 0);
        if (d < 1.0) {
            float zc = u.scene2.y / (u.scene2.x - u.scene2.y);
            float sceneDistance = u.scene2.w > 0.5 ? mix(u.scene2.x, u.scene2.y, d) : zc * u.scene2.x / (d + zc);
            float soft = clamp((sceneDistance - in.viewDistance) / u.scene.x, 0.0, 1.0);
            if (u.flags3.z > 0.5) soft *= soft;
            c.a *= soft;
        }
    }
    if (c.a <= 0.002) discard_fragment();
    float3 rgb = max(c.rgb, float3(0.0));
    float a = clamp(c.a, 0.0, 1.0);
    if (u.flags2.x > 1.5) rgb = mix(float3(1.0), rgb, a);
    else if (u.flags2.x > 0.5) rgb *= a;
    rgb += (fract(sin(dot(in.position.xy, float2(12.9898, 78.233))) * 43758.5453) - 0.5) / 255.0;
    return float4(rgb, a);
}
"""
}
