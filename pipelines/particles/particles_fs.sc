$input v_wpos, v_texcoord0, v_common // in...

#include "common.sh"

SAMPLER2D(u_texColor, 0);
SAMPLER2D(u_depthBuffer, 15);



void main()
{
	const float SOFT_MULTIPLIER = 5.0;
	vec3 screen_coord = getScreenCoord(v_wpos);
	
	float depth = texture2D(u_depthBuffer, screen_coord.xy * 0.5 + 0.5).x;

	float depth_diff = toLinearDepth(screen_coord.z) - toLinearDepth(depth);
	
	vec4 col = texture2D(u_texColor, v_texcoord0) * v_common.x;
	col.a *= clamp(depth_diff * SOFT_MULTIPLIER, 0, 1);
	gl_FragColor.rgba = col; 
}
