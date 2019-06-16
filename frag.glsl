#version 330 core

in vec3 Position;
in vec4 Color0;
in vec3 Tex0;

// Final Output
out vec4 PixelColor;
uniform sampler2D Texture0;
void main()
{
    // Initial TEV Register Values
    vec4 result = vec4(0, 0, 0, 1);
    vec4 color0 = vec4(1, 1, 1, 1);
    vec4 color1 = vec4(1, 1, 1, 1);
    vec4 color2 = vec4(0, 0, 0, 0);

    // Konst TEV Colors
    vec4 konst0 = vec4(1, 1, 1, 1);
    vec4 konst1 = vec4(1, 1, 1, 1);
    vec4 konst2 = vec4(1, 1, 1, 1);
    vec4 konst3 = vec4(1, 1, 1, 1);

    vec4 texCol0 = texture(Texture0, Tex0.xy);

    // TEV Stages


    // TEV Stage 0
    // Rasterization Swap Table: [0, 1, 2, 3]

    // Texture Swap Table: [0, 1, 2, 3]

    // Color and Alpha Operations
    result.rgb = (0.0f.rrr + mix(color0.rgb, konst0.rgba.rgb, Color0.rgba.rgb));
	result.rgb = clamp(result.rgb,0.0,1.0);


    result.a = (0.0f + mix(0.0f, 0.0f, 0.0f));
	result.a = clamp(result.a,0.0,1.0);

    // TEV Stage 1
    // Rasterization Swap Table: [0, 1, 2, 3]

    // Texture Swap Table: [0, 1, 2, 3]

    // Color and Alpha Operations
    result.rgb = (0.0f.rrr + mix(0.0f.rrr, result.rgb, texCol0.rgb));
	result.rgb = clamp(result.rgb,0.0,1.0);
	
    result.a = (0.0f + mix(0.0f, 0.0f, 0.0f));
	result.a = clamp(result.a,0.0,1.0);




    // Alpha Compare Test
    // Alpha Compare (Clip)
    if(!(true || true))
		discard;
    PixelColor = result;
}
