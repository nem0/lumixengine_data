$input v_wpos, v_texcoord0, v_common // in...

#include "common.sh"

SAMPLER2D(u_texColor, 0);
SAMPLER2D(u_depthBuffer, 15);



void main()
{
	const float SOFT_MULTIPLIER = 5.0;
	vec4 prj = mul(u_viewProj, vec4(v_wpos, 1.0) );
	prj.y = -prj.y;
	prj /= prj.w;
	
	float depth = texture2D(u_depthBuffer, prj.xy * 0.5 + 0.5).x;

	vec4 linear_depth_v = mul(u_invProj, vec4(0, 0, depth, 1));
	linear_depth_v /= linear_depth_v.w;
	vec4 linear_prjz_v = mul(u_invProj, vec4(0, 0, prj.z, 1));
	linear_prjz_v /= linear_prjz_v.w;

	float depth_diff = linear_prjz_v.z - linear_depth_v.z;
	
	vec4 col = texture2D(u_texColor, v_texcoord0) * v_common.x;
	col.a *= clamp(depth_diff * SOFT_MULTIPLIER, 0, 1);
	gl_FragColor.rgba = col; 
}
