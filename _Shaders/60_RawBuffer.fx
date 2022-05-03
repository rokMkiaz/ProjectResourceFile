ByteAddressBuffer Input; //SRV
RWByteAddressBuffer Output; //UAV

struct Group
{
    uint3 GroupID;
    uint3 GroupThreadID;
    uint3 DispatchThreadID;
    uint GroupIndex;
    float RetValue;
};

struct ComputeInput
{
    uint3 GroupID : SV_GroupID; //SV_ 셰이더로부터 받아옴
    uint3 GroupThreadID : SV_GroupThreadID;
    uint3 DispatchThreadID : SV_DispatchThreadID;
    uint GroupIndex : SV_GroupIndex;
};

[numthreads(10, 8, 3)] //쓰레드 그룹내 쓰레드 갯수
void CS(ComputeInput input)
{
    Group group;
    group.GroupID = asuint(input.GroupID); //컴퓨트셰이더에서 안정성 있는 함수인 asuin( = UINT)로 캐스팅해줘야함.
    group.GroupThreadID = asuint(input.GroupThreadID);
    group.DispatchThreadID = asuint(input.DispatchThreadID);
    group.GroupIndex = asuint(input.GroupIndex);
  
    
	uint index = input.GroupID.x * 10 * 8 * 3 + input.GroupIndex;
	uint outAddress =index * 11 * 4;
    
    uint inAddress = index * 4; //읽어드릴 주소
    group.RetValue = asfloat(Input.Load(inAddress));
    
    Output.Store3(outAddress + 0, asuint(group.GroupID)); //12
    Output.Store3(outAddress + 12, asuint(group.GroupThreadID)); //24
    Output.Store3(outAddress + 24, asuint(group.DispatchThreadID)); //36
    Output.Store(outAddress + 36, asuint(group.GroupIndex)); //40
    Output.Store(outAddress + 40, asuint(group.RetValue));//float이어도 Uint로 캐스팅해줘야함.

}

technique11 T0
{
    pass P0
    {
        SetVertexShader(NULL);
        SetPixelShader(NULL);

        SetComputeShader(CompileShader(cs_5_0, CS()));
    }
}