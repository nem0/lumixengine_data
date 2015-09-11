$input v_wpos, v_texcoord0

#include "common.sh"

SAMPLER2D(u_texShadowmap2, 1);

uniform vec4 u_lightDirFov; 
uniform mat4 u_camView;
uniform mat4 u_camInvProj;

static const float3 Kr = float3(0.18867780436772762, 0.4978442963618773, 0.6616065586417131); // air color
static const float rayleigh_brightness = 5;//3.3f;
static const float mie_brightness = 0.15f; // 0.20
static const float spot_brightness = 200;   // 1000
static const float scatter_strength = 28.0f/1000;
static const float rayleigh_strength = 0.139f;
static const float mie_strength = 0.0264f;
static const float rayleigh_collection_power = 0.51f;
static const float mie_collection_power = 0.39f;
static const float mie_distribution = 0.63f;
    
static const float surface_height = 0.993;
static const float range = 0.01;
static const float intensity = 1.8;
static const int step_count = 16;

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
    return color-color*pow(Kr, vec3_splat(factor/dist));
}


vec3 get_world_normal(vec2 frag_coord)
{
    frag_coord = (frag_coord - 0.5) * 2.0;
    vec4 device_normal = vec4(frag_coord, 0.0, 1.0);
    vec3 eye_normal = normalize(mul(u_camInvProj, device_normal).xyz);
    vec3 world_normal = normalize(mul(u_camView,eye_normal));
	return world_normal;
}


vec3 getEyeDir(vec2 uv)
{
	uv = uv * 2 - 1;
	
	mat3 m;
	m[0] = vec3(1, 0, 0);
	m[1] = vec3(0, 1, 0);
	m[2] = vec3(0, 0, 1);
	
	vec3 v = mul(m, normalize(vec3(-uv.x, -uv.y, 1)));
	
	return v; 
}


void main()
{
	vec3 lightdir = -u_lightDirFov.xyz;
	//vec3 eyedir = -getEyeDir(v_texcoord0);
	//vec3 eyedir = -normalize(v_view);
	vec3 eyedir = get_world_normal(v_texcoord0);
	
	float alpha = dot(eyedir, lightdir);
	
	gl_FragColor = vec4(eyedir, 1);
	//return ;
	float rayleigh_factor = phase(alpha, -0.01)*rayleigh_brightness;
	float mie_factor = phase(alpha, mie_distribution)*mie_brightness;
	float spot = smoothstep(0.0, 15.0, phase(alpha, 0.9995))*spot_brightness;
	
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
		vec3 influx = absorb(sample_depth, vec3_splat(intensity), scatter_strength)*extinction;
		rayleigh_collected += absorb(sample_distance, Kr*influx, rayleigh_strength);
		mie_collected += absorb(sample_distance, influx, mie_strength);
	}
	
	rayleigh_collected = (rayleigh_collected * eye_extinction * pow(eye_depth, rayleigh_collection_power))/float(step_count);
	mie_collected = (mie_collected * eye_extinction * pow(eye_depth, mie_collection_power))/float(step_count);
	
	vec3 color = vec3(spot*mie_collected + mie_factor*mie_collected +rayleigh_factor*rayleigh_collected);
	
	gl_FragColor.xyz = color;
	gl_FragColor.w = 1;
}
