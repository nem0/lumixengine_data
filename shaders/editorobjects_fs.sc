$input v_wpos, v_texcoord0, v_normal

/*
 * Copyright 2011-2015 Branimir Karadzic. All rights reserved.
 * License: http://www.opensource.org/licenses/BSD-2-Clause
 */

#include "common.sh"

#ifdef DIFFUSE_TEXTURE
	SAMPLER2D(u_texColor, 0);
#endif

	
uniform vec4 u_materialColorShininess;

	
void main()
{
	#ifdef DIFFUSE_TEXTURE
		vec3 color = texture2D(u_texColor, v_texcoord0).rgb;
	#else
		vec3 dir_light = vec3(0.707, 0.707, 0);
		float ndotl = clamp(dot(v_normal, dir_light), 0, 1);
		vec3 ambient = vec3_splat(0.1);
		vec3 diffuse = vec3_splat(0.9);
		vec3 color = ndotl * diffuse + ambient;
	#endif
	color *= u_materialColorShininess.rgb;
	gl_FragColor = vec4(toGamma(color.rgb), 1);
}
