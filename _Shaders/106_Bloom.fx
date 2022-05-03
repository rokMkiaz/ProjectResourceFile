#include "00_Global.fx"
#include "00_Light.fx"

float2 PixelSize;

struct VertexOutput
{
    float4 Position : SV_Position;
    float2 Uv : Uv;
};

VertexOutput VS(float4 Position : Position)
{
    VertexOutput output;
    
    output.Position = Position;
    output.Uv.x = Position.x * 0.5f + 0.5f;
    output.Uv.y = -Position.y * 0.5f + 0.5f;
    
    return output;
}

float4 PS_Diffuse(VertexOutput input) : SV_Target
{
    return DiffuseMap.Sample(LinearSampler, input.Uv);
}

float Threshold = 0.6f;
float4 PS_Luminosity(VertexOutput input) : SV_Target
{
    float4 color = DiffuseMap.Sample(LinearSampler, input.Uv); //컬러를 정규화하고 일정값 이상인 부분
    
    return saturate((color - Threshold) / (1 - Threshold));
}

#define MAX_SAMPLE_COUNT 33
int SampleCount = 15;

float2 Offsets[MAX_SAMPLE_COUNT];
float Weights[MAX_SAMPLE_COUNT];

float4 PS_Blur(VertexOutput input) : SV_Target
{
    float4 color = 0;
    
    for (int i = 0; i < SampleCount; i++)
        color += DiffuseMap.Sample(LinearSampler, input.Uv + Offsets[i]) * Weights[i];

    return color;
}
float4x4 ColorToSepiaMatrix = float4x4
(
    0.393, 0.769, 0.189, 0,
    0.349, 0.686, 0.168, 0,
    0.272, 0.534, 0.131, 0,
    0, 0, 0, 1
);

float4 PS_Sepia(VertexOutput input) : SV_Target
{
	float4 color = DiffuseMap.Sample(LinearSampler, input.Uv);
    
	return mul(ColorToSepiaMatrix, color);
}


Texture2D LuminosityMap;
Texture2D BlurMap;
float4 PS_Composite(VertexOutput input) : SV_Target
{
	float4 Sepia = PS_Sepia(input);
    float4 luminosity = LuminosityMap.Sample(LinearSampler, input.Uv);
    float4 blur = BlurMap.Sample(LinearSampler, input.Uv);
    
    luminosity *= (1.0f - saturate(blur));
    
	return float4((luminosity + blur).rgb*Sepia.rgb, 1.0f);


}



technique11 T0
{
    P_VP(P0, VS, PS_Diffuse)
    P_VP(P1, VS, PS_Luminosity)
    P_VP(P2, VS, PS_Blur)
    P_VP(P3, VS, PS_Composite)
}