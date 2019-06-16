#version 330 core

// Input
in vec3 RawPosition;
in vec4 RawColor0;
in vec2 RawTex0;
in vec2 RawTex1;
in vec2 RawTex2;
in vec2 RawTex3;
in vec2 RawTex4;
in vec2 RawTex5;
in vec2 RawTex6;
in vec2 RawTex7;

// Output
out vec4 Color0;
out vec3 Tex0;

// Uniforms
   uniform mat4 ModelMtx;
   uniform mat4 ViewMtx;
   uniform mat4 ProjMtx;

   uniform mat4 TexMtx[10];
   uniform mat4 PostMtx[20];
   uniform vec4 COLOR0_Amb;
   uniform vec4 COLOR0_Mat;
   uniform vec4 COLOR1_Amb;
   uniform vec4 COLOR1_Mat;

struct GXLight
{
   vec4 Position;
   vec4 Direction;
   vec4 Color;
   vec4 DistAtten;
   vec4 AngleAtten;
};

   GXLight Lights[8];

uniform int NumLights;
uniform vec4 ambLightColor;

// Main
void main()
{
    mat4 MVP = ProjMtx * ViewMtx * ModelMtx;
    mat4 MV = ViewMtx * ModelMtx;
    gl_Position = MVP * vec4(RawPosition, 1);

    // Ambient Colors & Material Colors
    vec4 ambColor0 = vec4(0.1960784, 0.1960784, 0.1960784, 0.1960784);
    vec4 ambColor1 = vec4(0, 0, 0, 0);
    vec4 matColor0 = vec4(0.8, 0.8, 0.8, 1);
    vec4 matColor1 = vec4(0.8, 0.8, 0.8, 1);

    // ChanCtrl's - 1 count
    Color0 = vec4(1, 1, 1, 1);
    Color0.rgb = RawColor0.rgb;


    // TexGen - 1 count
    Tex0 = vec3(RawTex0.xy, 0);
}
