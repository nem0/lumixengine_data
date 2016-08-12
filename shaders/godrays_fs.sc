$input v_wpos, v_texcoord0 // in...

#include "common.sh"

SAMPLER2D(u_texture, 15);
uniform vec4 u_light_screen_pos;

void main()
{	
	const float exposure = 0.01;
	const float decay = 0.99;
	const float density = 0.5;
	const float weight = 1.0;
	vec2 lightPositionOnScreen = u_light_screen_pos.xy;
	const int NUM_SAMPLES = 100;
	float illuminationDecay = 0.5;

	vec2 deltaTextCoord = vec2(v_texcoord0.xy - lightPositionOnScreen.xy);
	vec2 textCoo = v_texcoord0.xy;
	deltaTextCoord *= 1.0 /  float(NUM_SAMPLES) * density;

	vec4 res = vec4(0, 0, 0, 0);
	textCoo = v_texcoord0.xy;
	for(int i=0; i < NUM_SAMPLES; i++)
	{
		textCoo -= deltaTextCoord;
		vec2 dif = textCoo - lightPositionOnScreen;
		vec4 sample = vec4_splat(texture2D(u_texture, textCoo).r == 1 ? 1.0 : 0.0);
		if(abs(dot(dif, dif)) > 0.1) sample *= 0;
		sample *= illuminationDecay * weight;
		res += sample;
		illuminationDecay *= decay;
	}
	gl_FragColor = res * exposure;
}

