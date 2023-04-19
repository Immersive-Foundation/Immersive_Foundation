static const char* shader_pretessellated_brush_vs = R"(
#extension GL_EXT_shader_io_blocks : enable

#define NUM_VIEWS 2

#if STEREOMODE==2
#extension GL_OVR_multiview : enable
#define VIEW_ID gl_ViewID_OVR
layout(num_views=NUM_VIEWS) in;
#else
#define VIEW_ID 0
#endif

layout (std140, row_major, binding=0) uniform FrameState
{
    float       mTime;
    int         mFrame;
}frame;

layout (std140, row_major, binding=3) uniform LayersState
{
    mat4x4 mLayerToViewer;
    float  mLayerToViewerScale;
    float  mOpacity;
    float  mkUnused;
    float  mDrawInTime;
    vec4   mAnimParams; // draw-in and other effect parameters
    vec4   mKeepAlive[2];        // note, can't pack in an array of float[8] due to granularity of GLSL array types
    uint   mID;
}layer;

layout (std140, row_major, binding=4) uniform DisplayState
{
    mat4x4      mViewerToEye_Prj[NUM_VIEWS];
    vec2        mResolution;
}display;

layout (std140, row_major, binding=5) uniform PassState
{
    int mID;
    int kk1;
    int kk2;
    int kk3;
}pass;

layout (std140, row_major, binding=9) uniform ChunkData
{
    uint mVertexOffset[128];
} chunk_data;

out V2CData
{
    vec4  col_tra;
    flat uint mask;
}vg;


layout (location=0) in vec3 inVertex;
layout (location=1) in vec4 inColAlpha;

layout (location=2) in vec3  inOri;
layout (location=3) in uint  inInfo;
#if VERTEX_FORMAT==0
layout (location=4) in float inTime;
#endif

void main()
{
    vec3 pos = inVertex;

    #if STEREOMODE==0
    #define iid 0
    #endif
    #if STEREOMODE==1
    #define iid pass.mID
    #endif
    #if STEREOMODE==2
    #define iid VIEW_ID
    #endif

    vec3 cpos = (layer.mLayerToViewer * vec4(pos, 1.0)).xyz;

    vg.mask = (inColAlpha.w>0.999) ? layer.mID : inInfo;

    // directional stroke
    float f = 1.0;
    vec3 ori = inOri;
    if( ((inInfo>>7)&1u)==0u)
    {
        vec3 wori = normalize( (layer.mLayerToViewer * vec4(ori,0.0) ).xyz );
        f = clamp( dot(wori,normalize(cpos)), 0.0, 1.0 );
        f = f*f;
    }

    vg.col_tra.w = inColAlpha.w * f * layer.mOpacity;
    #if COLOR_COMPRESSED==0
    vg.col_tra.xyz = inColAlpha.xyz * inColAlpha.xyz;
    #endif
    #if COLOR_COMPRESSED==1
    vg.col_tra.xyz = inColAlpha.xyz;
    #endif

    gl_Position = display.mViewerToEye_Prj[iid] * vec4(cpos,1.0);
}
)";
