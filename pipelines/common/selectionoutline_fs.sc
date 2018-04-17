$input v_wpos, v_texcoord0 // in...

#include "common.sh"

SAMPLER2D(u_texture, 15);

void main()
{
	if(texture2D(u_texture, v_texcoord0).r > 0.999) discard;
	
	vec4 color = vec4(0, 0, 0, 0);
	int c = 0;
	for(int i = 0; i < 3; ++i)
	{
		if(texture2D(u_texture, v_texcoord0 + vec2(u_viewTexel.x * i, 0)).r < 0.999) ++c;
		if(texture2D(u_texture, v_texcoord0 + vec2(-u_viewTexel.x * i, 0)).r < 0.999) ++c;
		if(texture2D(u_texture, v_texcoord0 + vec2(0, u_viewTexel.y * i)).r < 0.999) ++c;
		if(texture2D(u_texture, v_texcoord0 + vec2(0, -u_viewTexel.y * i)).r < 0.999) ++c;
	}

	if(c == 12) discard;
	vec4 x = vec4(1, 0.5, 0, 1.0f);
	gl_FragColor.rgba = x;
}
