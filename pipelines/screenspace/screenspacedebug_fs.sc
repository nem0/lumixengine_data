$input v_wpos, v_texcoord0 // in...

/*
 * Copyright 2011-2015 Branimir Karadzic. All rights reserved.
 * License: http://www.opensource.org/licenses/BSD-2-Clause
 */

#include "common.sh"

SAMPLER2D(u_texture, 15);
uniform vec4 u_multiplier;

void main()
{
	vec4 color = texture2D(u_texture, v_texcoord0);
	if (all(lessThan(u_multiplier.xyz, vec3_splat(0.5))))
		gl_FragColor.rgb = vec3_splat(color.a * u_multiplier.a);
	else
	gl_FragColor.rgb = color.rgb * u_multiplier.rgb;
	gl_FragColor.w = 1.0;
}
