$input v_tc0, v_tc1, v_tc2

#include "common.sh"

uniform vec4 u_textureSize;
uniform vec4 u_dofParams;

#define DOF_NEAR_BLUR u_dofParams.x
#define DOF_NEAR_SHARP u_dofParams.y
#define DOF_FAR_SHARP u_dofParams.z
#define DOF_FAR_BLUR u_dofParams.w

SAMPLER2D(u_texture, 15);
SAMPLER2D(u_depthBuffer, 14);

void main()
{
	vec4 color = texture2D(u_texture, v_tc0.xy) * 0.2270270270
		+ texture2D(u_texture, v_tc1.xy) * 0.3162162162
		+ texture2D(u_texture, v_tc1.zw) * 0.0702702703
		+ texture2D(u_texture, v_tc2.xy) * 0.3162162162
		+ texture2D(u_texture, v_tc2.zw) * 0.0702702703;

	float depth = texture2D(u_depthBuffer, v_tc0.xy).r;
	float linear_depth = toLinearDepth(depth);
	#ifdef NEAR
		color.a = 1 - smoothstep(DOF_NEAR_BLUR, DOF_NEAR_SHARP, linear_depth);
	#else
		color.a = smoothstep(DOF_FAR_SHARP, DOF_FAR_BLUR, linear_depth);
	#endif
		
	gl_FragColor = color;
}
