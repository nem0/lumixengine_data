$input v_wpos, v_texcoord0 // in...

#include "common.sh"

SAMPLER2D(u_hdrBuffer, 15);
SAMPLER2D(u_avgLuminance, 14);
#ifdef HDR_DOF
	SAMPLER2D(u_dofBuffer, 13);
	SAMPLER2D(u_depthBuffer, 12);
#endif

uniform vec4 exposure;
uniform vec4 midgray;
uniform mat4 u_camInvProj;
uniform vec4 focal_distance;
uniform vec4 focal_range;


float reinhard2(float x, float whiteSqr)
{
	return (x * (1.0 + x/whiteSqr) ) / (1.0 + x);
}

// Unchared2 tone mapping (See http://filmicgames.com)
vec3 Uncharted2Tonemap(vec3 x)
{
	const float A = 0.15;
	const float B = 0.50;
	const float C = 0.10;
	const float D = 0.20;
	const float E = 0.02;
	const float F = 0.30;
	return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}


void main()
{
	float avg_loglum = max(0.1, exp(texture2D(u_avgLuminance, half2(0.5, 0.5)).r));
	vec3 hdr_color = texture2D(u_hdrBuffer, v_texcoord0).xyz;
	#ifdef HDR_DOF
	
		float depth = texture2D(u_depthBuffer, v_texcoord0).x;
		vec4 linear_depth_v = mul(u_camInvProj, vec4(0, 0, depth, 1));
		linear_depth_v /= linear_depth_v.w;

		#if 0
			float depth2 = texture2D(u_depthBuffer, vec2(0.5, 0.5)).x;
			vec4 linear_depth2_v = mul(u_camInvProj, vec4(0, 0, depth2, 1));
			linear_depth2_v /= linear_depth2_v.w;
			float t = clamp(abs(-linear_depth_v.z - -linear_depth2_v.z) / focal_range.x, 0, 1);
		#else 
			float t = clamp(abs(-linear_depth_v.z - focal_distance.x) / focal_range.x, 0, 1);
		#endif
		
		vec3 dof_color = texture2D(u_dofBuffer, v_texcoord0).xyz;
		if (-linear_depth_v.z > 10000) t = 0;
		hdr_color = lerp(hdr_color, dof_color, t);
	#endif		
	hdr_color *= exposure.x;
	float lum = luma(hdr_color);

	float map_middle = (midgray.r / (avg_loglum + 0.001)) * lum;
	
	//float ld = reinhard2(map_middle, 1.1*1.1);
	//float ld = map_middle / (map_middle + 1);
	
	float ld = Uncharted2Tonemap(map_middle) / Uncharted2Tonemap(11);
	
	vec3 finalColor = (hdr_color / lum) * ld;

	gl_FragColor =  vec4(toGamma(finalColor), 1.0f);
}



