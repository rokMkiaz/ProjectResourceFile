#include"00_Global.fx"
#include "00_Light.fx"
#include "00_Render.fx"

cbuffer CB_Tessellation
{
	matrix TessellationVP;
	float TessellationFactor;
};
float4 PS(MeshOutput input) : SV_Target
{
	return PS_AllLight(input);

}

struct VertexTS
{
	float3 position : CONTROL_POINT_POSITION;
	float2 Scale : Scale;
	uint MapIndex : MapIndex;
};

struct TSVertexOutput
{
	float3 position : WORLD_SPACE_CONTROL_POINT_POSITION;
	float2 Scale : Scale;
	uint MapIndex : MapIndex;
};

TSVertexOutput VS_TS_Out(VertexTS input)
{
	TSVertexOutput output;
	output.position = WorldPosition(float4(input.position, 1.0f)).xyz;
	output.Scale = input.Scale;
	output.MapIndex = input.MapIndex;
	return output;
}


// Output control point
struct BEZIER_CONTROL_POINT
{
	float3 vPosition : BEZIERPOS;
};



struct OutputConstantHS
{
	float edges[3] : SV_TessFactor;
	float inside : SV_InsideTessFactor;
};

struct OutputHS
{
	float3 position : CONTROL_POINT_POSITION;
	uint MapIndex : MapIndex;
};


void MainConstantHS(InputPatch<TSVertexOutput, 3> InPatches,
				 uint uPatchID : SV_PrimitiveID)
{
	OutputConstantHS output;
	output.edges[0] = output.edges[1] = output.edges[2] = TessellationFactor;
	output.inside = TessellationFactor;

}

[domain("tri")]
[partitioning("integer")]
[outputtopology("triangle_cw")]
[outputcontrolpoints(3)]
[patchconstantfunc("MainConstantHS")] 

OutputHS MainHS(InputPatch<TSVertexOutput, 3> InPatches,
		 uint uControlPointID : SV_OutputControlPointID,
		 uint uPatchID : SV_PrimitiveID)
{
	OutputHS output;
	output.position = InPatches[uControlPointID].position;
	output.MapIndex = InPatches[uControlPointID].MapIndex;
	
	
	return output;

}
//void MainHS(point TSVertexOutput input[1], inout TriangleStream<OutputHS> stream)
//{
//	float3 up = float3(0, 1, 0);
//	float3 forward = input[0].position.xyz - ViewPosition();
//	float3 right = normalize(cross(up, forward));
//	
//	float2 size = input[0].Scale * 0.5f;
//	
//	
//	
//	float4 position[4];
//	position[0] = float4(input[0].position.xyz - size.x * right - size.y * up, 1);
//	position[1] = float4(input[0].position.xyz - size.x * right + size.y * up, 1);
//	position[2] = float4(input[0].position.xyz + size.x * right - size.y * up, 1);
//	position[3] = float4(input[0].position.xyz + size.x * right + size.y * up, 1);
//	
//	float2 uv[4] =
//	{
//		float2(0, 1), float2(0, 0), float2(1, 1), float2(1, 0)
//	};
//	
//	OutputHS output;
//	[unroll(4)]
//	for (int i = 0; i < 4; i++)
//	{
//		output.position = ViewProjection(position[i]);
//		output.MapIndex = input[0].MapIndex;
//        
//		stream.Append(output);
//	}
//}

struct OutputDS
{
	float4 position : SV_Position;
	float3 colour : COLOUR;
	float3 uvw : DOMAIN_SHADER_LOCATION;
	float3 wPos : WORLD_POSITION;
	float4 edges : EDGE_FACTORS;
	float2 inside : INNER_FACTORS;
};


[domain("tri")] 
OutputDS MainDS(OutputConstantHS input, //OutputDS
		 float3 uvw : SV_DomainLocation,
		 const OutputPatch<OutputHS, 3> Patches)
{

	OutputDS output = (OutputDS)0;
	
	float3 finalVertexCoord = float3(0.0f, 0.0f, 0.0f);
	
	
	finalVertexCoord += (Patches[0].position * uvw.x);
	finalVertexCoord += (Patches[1].position * uvw.y);
	finalVertexCoord += (Patches[2].position * uvw.z);
	
	output.uvw = uvw;
	output.wPos = finalVertexCoord;
	output.edges = float4(input.edges[0], input.edges[1], input.edges[2], 0.0f);
	output.inside = float2(input.inside, 0.0f);

	output.position = mul(float4(output.wPos, 1.0f),TessellationVP);
	
	return output;

}

float4 PS_Test(OutputDS In) : SV_TARGET
{
	
	return float4(1, 0, 0, 1);
}


float4 MainSolidPS(OutputDS In) : SV_TARGET
{

	return float4(1, 1, 1, 1);

}



technique11 T0
{
	P_VP(P0, VS_Mesh, PS)
	P_VP(P1, VS_Model, PS)
	P_VP(P2, VS_Animation, PS)

	//P_RS_VTP(P0, CullMode_None, VS_Mesh, Hull, Domain, PS)
	P_VTP(P3, VS_TS_Out, MainHS, MainDS, MainSolidPS)



}



