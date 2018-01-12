$input v_wpos, v_texcoord0 // in...

#include "common.sh"

SAMPLER2D(u_texture, 15);
uniform vec4 u_multiplier;

void main()
{
	vec4 color = texture2D(u_texture, v_texcoord0);
	#ifdef ALPHA_TO_BLACK
		gl_FragColor.rgb = mix(vec3(0, 0, 0), color.rgb, color.a);
	#else
		if (all(lessThan(u_multiplier.xyz, vec3_splat(0.5))))
			gl_FragColor.rgb = vec3_splat(color.a * u_multiplier.a);
		else
			gl_FragColor.rgb = color.rgb * u_multiplier.rgb;
	#endif
	gl_FragColor.w = 1.0;
}
