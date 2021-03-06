//
//  model_io.metal
//  MetalCameraTest
//
//  Created by HasegawaYasuo on 2018/08/12.
//  Copyright © 2018年 HasegawaYasuo. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct xyz_n_st {
    float3 xyz [[ attribute(0) ]];
    float3 n   [[ attribute(1) ]];
    half2 st   [[ attribute(2) ]];
};

struct xyzw_n_st_rgba {
    float4 xyzw [[ position ]];
    float3 n;
    float4 rgba;
    half2  st;
};

struct TransformPackage {
    float4x4 normalMatrix;
    float4x4 modelMatrix;
    float4x4 viewMatrix;
    float4x4 modelViewMatrix;
    float4x4 modelViewProjectionMatrix;
};

vertex xyzw_n_st_rgba textureMIOVertexShader(xyz_n_st in [[ stage_in ]], constant TransformPackage &transformPackage [[ buffer(1) ]]) {
    
    xyzw_n_st_rgba out;
    
    // xyzw
    out.xyzw = transformPackage.modelViewProjectionMatrix * float4(in.xyz, 1.0);
    
    // n
    out.n = in.n;
    
    // st
    out.st = in.st;
    
    // rgba
    out.rgba = float4(0,0,0,0);
    
    return out;
    
}

fragment float4 textureMIOFragmentShader(xyzw_n_st_rgba in [[ stage_in ]], texture2d<float> texas [[ texture(0) ]]) {
    
    constexpr sampler defaultSampler;
    
    float4 rgba = texas.sample(defaultSampler, float2(in.st)).rgba;
    
    return rgba;
    
}

vertex xyzw_n_st_rgba showMIOVertexShader(xyz_n_st in [[ stage_in ]],
                                          constant TransformPackage &transformPackage [[ buffer(1) ]]) {
    
    xyzw_n_st_rgba out;
    
    // eye space normal
    float4 nes = transformPackage.normalMatrix * float4(in.n, 1);
    float3 normalEyeSpace = normalize(nes.xyz);
    
    // world space normal
    float3 in_n = normalize(in.n);
    
    // rgba
    //    out.rgba = float4(in.st.x, in.st.y, 0, 1);
    //    out.rgba = float4(in_n, 1.0);
    out.rgba = float4((normalEyeSpace.x + 1.0)/2.0, (normalEyeSpace.y + 1.0)/2.0, (normalEyeSpace.z + 1.0)/2.0, 1.0);
    
    // xyzw
    out.xyzw = transformPackage.modelViewProjectionMatrix * float4(in.xyz, 1);
    
    // st
    out.st = in.st;
    
    return out;
    
}

fragment float4 showMIOFragmentShader(xyzw_n_st_rgba in [[ stage_in ]], texture2d<float> texas [[ texture(0) ]]) {
    
    constexpr sampler defaultSampler;
    
    float4 rgba;
    float4 texColor = texas.sample(defaultSampler, float2(in.st)).rgba;
    
    rgba = texColor*in.rgba;
    
    return rgba;
    
}
