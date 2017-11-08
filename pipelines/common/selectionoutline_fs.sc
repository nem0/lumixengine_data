$input v_wpos, v_texcoord0 // in...

#include "common.sh"

SAMPLER2D(u_texture, 15);

void main()
{
	if(texture2D(u_texture, v_texcoord0).r > 0.5) discard;
	
	vec4 color = vec4(0, 0, 0, 0);
	for(int i = 0; i < 3; ++i)
	{
		color += texture2D(u_texture, v_texcoord0 + vec2(u_viewTexel.x * i, 0));
		color += texture2D(u_texture, v_texcoord0 + vec2(-u_viewTexel.x * i, 0));
		color += texture2D(u_texture, v_texcoord0 + vec2(0, u_viewTexel.y * i));
		color += texture2D(u_texture, v_texcoord0 + vec2(0, -u_viewTexel.y * i));
	}

	vec4 x = vec4(toGamma(color.rgb * vec3(1, 0.1, 0)), 1.0f);
	if(x.r < 0.5) discard;
	gl_FragColor.rgba = x;
}
