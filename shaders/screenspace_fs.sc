$input v_wpos, v_texcoord0 // in...

/*
 * Copyright 2011-2015 Branimir Karadzic. All rights reserved.
 * License: http://www.opensource.org/licenses/BSD-2-Clause
 */

#include "common.sh"

SAMPLER2D(u_texShadowmap2, 1);

void main()
{
	vec4 color = (texture2D(u_texShadowmap2, v_texcoord0) );

	gl_FragColor.rgb = vec3_splat(color.r*0.5 + 0.5);
	gl_FragColor.w = 1.0;
}
