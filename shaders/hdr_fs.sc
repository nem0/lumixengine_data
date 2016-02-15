$input v_wpos, v_texcoord0 // in...

#include "common.sh"

SAMPLER2D(u_hdrBuffer, 15);
SAMPLER2D(u_avgLuminance, 14);

uniform vec4 exposure;
uniform vec4 midgray;

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
	vec3 hdr_color = texture2D(u_hdrBuffer, v_texcoord0).xyz * exposure.x;
	float lum = luma(hdr_color);

	float map_middle = (midgray.r / (avg_loglum + 0.001)) * lum;
	
	//float ld = reinhard2(map_middle, 1.1*1.1);
	//float ld = map_middle / (map_middle + 1);
	
	float ld = Uncharted2Tonemap(map_middle) / Uncharted2Tonemap(11);
	
	vec3 finalColor = (hdr_color / lum) * ld;

	gl_FragColor =  vec4(toGamma(finalColor), 1.0f);
}



