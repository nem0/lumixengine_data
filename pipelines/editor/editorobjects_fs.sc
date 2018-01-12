$input v_wpos, v_texcoord0, v_normal

/*
 * Copyright 2011-2015 Branimir Karadzic. All rights reserved.
 * License: http://www.opensource.org/licenses/BSD-2-Clause
 */

#include "common.sh"

#ifdef DIFFUSE_TEXTURE
	SAMPLER2D(u_texColor, 0);
#endif
SAMPLER2D(u_depthBuffer, 15);
	
uniform vec4 u_materialColor;

	
void main()
{
	vec3 screen_coord = getScreenCoord(v_wpos);

	#ifdef DIFFUSE_TEXTURE
		vec3 color = texture2D(u_texColor, v_texcoord0).rgb;
	#else
		vec3 dir_light = vec3(0.707, 0.707, 0);
		float ndotl = clamp(dot(v_normal, dir_light), 0, 1);
		vec3 ambient = vec3_splat(0.1);
		vec3 diffuse = vec3_splat(0.9);
		vec3 color = ndotl * diffuse + ambient;
	#endif
	color *= u_materialColor.rgb;
	float depth = texture2D(u_depthBuffer, screen_coord.xy * 0.5 + 0.5).x;
	gl_FragColor = vec4(toGamma(color.rgb), screen_coord.z < depth ? 1 : 0.1);
}
