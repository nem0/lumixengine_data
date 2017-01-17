$input v_wpos, v_texcoord0

#include "common.sh"

uniform vec4 u_lightDirFov; 
uniform vec4 u_airColor;
uniform vec4 u_brightness;
uniform vec4 u_strength;
uniform vec4 u_sunSize;


const float rayleigh_collection_power = 0.51f;
const float mie_collection_power = 0.39f;
const float mie_distribution = 0.13f;

const float surface_height = 0.993;
const float intensity = 1.8;
const int step_count = 4;

//http://codeflow.org/entries/2011/apr/13/advanced-webgl-part-2-sky-rendering/


float phase(float alpha, float g)
{
    float a = 3.0*(1.0-g*g);
    float b = 2.0*(2.0+g*g);
    float c = 1.0+alpha*alpha;
    float d = pow(1.0+g*g-2.0*g*alpha, 1.5);
    return (a/b)*(c/d);
}


float atmospheric_depth(vec3 position, vec3 dir)
{
    float a = dot(dir, dir);
    float b = 2.0*dot(dir, position);
    float c = dot(position, position)-1.0;
    float det = b*b-4.0*a*c;
    float detSqrt = sqrt(det);
    float q = (-b - detSqrt)/2.0;
    float t1 = c/q;
    return t1;
}


float horizon_extinction(vec3 position, vec3 dir, float radius)
{
    float u = dot(dir, -position);
    if(u<0.0){
        return 1.0;
    }
    vec3 near = position + u*dir;
    if(length(near) < radius){
        return 0.0;
    }
    else{
        vec3 v2 = normalize(near)*radius - position;
        float diff = acos(dot(normalize(v2), dir));
        return smoothstep(0.0, 1.0, pow(diff*2.0, 3.0));
    }
}

vec3 absorb(float dist, vec3 color, float factor)
{
    return color-color*pow(u_airColor.rgb, vec3_splat(factor/dist));
}


vec3 get_world_normal(vec2 frag_coord)
{
	float z = 1;
	vec4 posProj = vec4(frag_coord * 2 - 1, z, 1.0);
	vec4 wpos = mul(u_camInvViewProj, posProj);
	wpos /= wpos.w;
	vec3 view = mul(u_camInvView, vec4(0.0, 0.0, 0.0, 1.0)).xyz - wpos.xyz;

    return -normalize(view);
}


void main()
{
	vec3 lightdir = -u_lightDirFov.xyz;
	vec3 eyedir = get_world_normal(v_wpos.xy);
	
	float alpha = dot(eyedir, lightdir);
	
	gl_FragColor = vec4(eyedir, 1);
	//return ;
	float rayleigh_factor = phase(alpha, -0.01)*u_brightness.x;
	float mie_factor = phase(alpha, mie_distribution)*u_brightness.y;
	float spot = smoothstep(0.0, u_sunSize.x, phase(alpha, 0.9995))*u_brightness.z;
	
	vec3 eye_position = vec3(0.0, surface_height, 0.0);
	float eye_depth = atmospheric_depth(eye_position, eyedir);
	float step_length = eye_depth/float(step_count);
	
	float eye_extinction = horizon_extinction(
		eye_position, eyedir, surface_height-0.15
	);
	
	vec3 rayleigh_collected = vec3(0.0, 0.0, 0.0);
	vec3 mie_collected = vec3(0.0, 0.0, 0.0);
	
	for(int i=0; i<step_count; i++)
	{
		float sample_distance = step_length*float(i);
		vec3 position = eye_position + eyedir*sample_distance;
		float extinction = horizon_extinction(position, lightdir, surface_height-0.35);
		float sample_depth = atmospheric_depth(position, lightdir);
		vec3 influx = absorb(sample_depth, vec3_splat(intensity), u_strength.x)*extinction;
		rayleigh_collected += absorb(sample_distance, u_airColor.rgb*influx, u_strength.y);
		mie_collected += absorb(sample_distance, influx, u_strength.z);
	}
	
	rayleigh_collected = (rayleigh_collected * eye_extinction * pow(eye_depth, rayleigh_collection_power))/float(step_count);
	mie_collected = (mie_collected * eye_extinction * pow(eye_depth, mie_collection_power))/float(step_count);
	
	vec3 color = vec3(spot*mie_collected + mie_factor*mie_collected +rayleigh_factor*rayleigh_collected);
	
	gl_FragColor.xyz = color;
	gl_FragColor.w = 1;
}