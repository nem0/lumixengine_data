$input v_texcoord0

#include "common.sh"


SAMPLER2D(s_texColor, 15);
#ifdef LUM1
	SAMPLER2D(s_texPrevLum, 14);
#endif
uniform vec4 u_offset[16];


void main()
{
#ifdef HDR_LUMINANCE
	vec3 rgb0 = texture2D(s_texColor, v_texcoord0 + u_offset[0].xy).rgb;
	vec3 rgb1 = texture2D(s_texColor, v_texcoord0 + u_offset[1].xy).rgb;
	vec3 rgb2 = texture2D(s_texColor, v_texcoord0 + u_offset[2].xy).rgb;
	vec3 rgb3 = texture2D(s_texColor, v_texcoord0 + u_offset[3].xy).rgb;
	vec3 rgb4 = texture2D(s_texColor, v_texcoord0 + u_offset[4].xy).rgb;
	vec3 rgb5 = texture2D(s_texColor, v_texcoord0 + u_offset[5].xy).rgb;
	vec3 rgb6 = texture2D(s_texColor, v_texcoord0 + u_offset[6].xy).rgb;
	vec3 rgb7 = texture2D(s_texColor, v_texcoord0 + u_offset[7].xy).rgb;
	vec3 rgb8 = texture2D(s_texColor, v_texcoord0 + u_offset[8].xy).rgb;
	float avg = log(1e-5 + luma(rgb0).r)
			  + log(1e-5 + luma(rgb1).r)
			  + log(1e-5 + luma(rgb2).r)
			  + log(1e-5 + luma(rgb3).r)
			  + log(1e-5 + luma(rgb4).r)
			  + log(1e-5 + luma(rgb5).r)
			  + log(1e-5 + luma(rgb6).r)
			  + log(1e-5 + luma(rgb7).r)
			  + log(1e-5 + luma(rgb8).r)
			  ;
	avg *= 1.0/9.0;

	gl_FragColor.r = avg;
#else
	float sum;
	sum  = texture2D(s_texColor, v_texcoord0 + u_offset[ 0].xy).r;
	sum += texture2D(s_texColor, v_texcoord0 + u_offset[ 1].xy).r;
	sum += texture2D(s_texColor, v_texcoord0 + u_offset[ 2].xy).r;
	sum += texture2D(s_texColor, v_texcoord0 + u_offset[ 3].xy).r;
	sum += texture2D(s_texColor, v_texcoord0 + u_offset[ 4].xy).r;
	sum += texture2D(s_texColor, v_texcoord0 + u_offset[ 5].xy).r;
	sum += texture2D(s_texColor, v_texcoord0 + u_offset[ 6].xy).r;
	sum += texture2D(s_texColor, v_texcoord0 + u_offset[ 7].xy).r;
	sum += texture2D(s_texColor, v_texcoord0 + u_offset[ 8].xy).r;
	sum += texture2D(s_texColor, v_texcoord0 + u_offset[ 9].xy).r;
	sum += texture2D(s_texColor, v_texcoord0 + u_offset[10].xy).r;
	sum += texture2D(s_texColor, v_texcoord0 + u_offset[11].xy).r;
	sum += texture2D(s_texColor, v_texcoord0 + u_offset[12].xy).r;
	sum += texture2D(s_texColor, v_texcoord0 + u_offset[13].xy).r;
	sum += texture2D(s_texColor, v_texcoord0 + u_offset[14].xy).r;
	sum += texture2D(s_texColor, v_texcoord0 + u_offset[15].xy).r;
	float avg = sum/16.0;
	#ifdef LUM1
		float prev_lum = texture2D(s_texPrevLum, vec2(0.5, 0.5)).r;
		gl_FragColor.r = mix(avg, prev_lum, 0.9);
	#else
		gl_FragColor.r = avg;
	#endif
#endif
}
