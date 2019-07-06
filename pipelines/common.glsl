#define M_PI 3.14159265359
#define ONE_BY_PI (1 / 3.14159265359)

struct PixelData {
	vec4 albedo;
	float roughness;
	float metallic;
	float emission;
	vec3 normal;
	vec3 wpos;
} data;


float saturate(float a) { return clamp(a, 0, 1); }
vec2 saturate(vec2 a) { return clamp(a, vec2(0), vec2(1)); }
vec3 saturate(vec3 a) { return clamp(a, vec3(0), vec3(1)); }
vec4 saturate(vec4 a) { return clamp(a, vec4(0), vec4(1)); }


float packEmission(float emission)
{
	return log2(1 + emission / 64);
}


float unpackEmission(float emission)
{
	return (exp2(emission) - 1) * 64;
}


vec3 getViewPosition(sampler2D depth_buffer, mat4 inv_view_proj, vec2 tex_coord)
{
	float z = texture2D(depth_buffer, tex_coord).r;
	vec4 pos_proj = vec4(tex_coord * 2 - 1, z, 1.0);
	vec4 view_pos = inv_view_proj * pos_proj;
	return view_pos.xyz / view_pos.w;
}


float getShadow(sampler2D shadowmap, vec3 wpos)
{
	vec4 pos = vec4(wpos, 1);
	
	for (int i = 0; i < 4; ++i) {
		vec4 sc = u_shadowmap_matrices[i] * pos;
		sc = sc / sc.w;
		if (all(lessThan(sc.xy, vec2(0.99))) && all(greaterThan(sc.xy, vec2(0.01)))) {
			vec2 sm_uv = vec2(sc.x * 0.25 + i * 0.25, sc.y);
			float occluder = textureLod(shadowmap, sm_uv, 0).r;
			return clamp(exp(5000 * (sc.z - occluder)), 0.0, 1.0);
		}
	}

	return 1;
}


float D_GGX(float ndoth, float roughness)
{
	float a = roughness * roughness;
	float a2 = a * a;
	float f = (ndoth * ndoth) * (a2 - 1) + 1;
	return a2 / (f * f * M_PI);
}
		

float G_SmithSchlickGGX(float ndotl, float ndotv, float roughness)
{
	float r = roughness + 1.0;
	float k = (r * r) / 8.0;
	float l = ndotl / (ndotl * (1.0 - k) + k);
	float v = ndotv / (ndotv * (1.0 - k) + k);
	return l * v;
}


vec3 F_Schlick(float cos_theta, vec3 F0)
{
	return mix(F0, vec3(1), pow(1.0 - cos_theta, 5.0)); 
}


vec3 PBR_ComputeDirectLight(vec3 albedo
	, vec3 N
	, vec3 L
	, vec3 V
	, vec3 light_color
	, float roughness
	, float metallic)
{
	vec3 F0 = vec3(0.04);
	F0 = mix(F0, albedo, metallic);		
	
	float ndotv = abs( dot (N , V )) + 1e-5f;
	vec3 H = normalize (V + L);
	float ldoth = saturate ( dot (L , H ));
	float ndoth = saturate ( dot (N , H ));
	float ndotl = saturate ( dot (N , L ));
	float hdotv = saturate ( dot (H , V ));
	
	float D = D_GGX(ndoth, roughness);
	float G = G_SmithSchlickGGX(ndotl, ndotv, roughness);
	vec3 F = F_Schlick(hdotv, F0);
	vec3 specular = (D * G * F) / max(4 * ndotv * ndotl, 0.001);
	
	vec3 kS = F;
	vec3 kD = vec3(1.0) - kS;
	kD *= 1.0 - metallic;	  
	return (kD * albedo / M_PI + specular) * light_color * ndotl;
}	


vec3 env_brdf_approx (vec3 F0, float roughness, float NoV)
{
	vec4 c0 = vec4(-1, -0.0275, -0.572, 0.022 );
	vec4 c1 = vec4(1, 0.0425, 1.0, -0.04 );
	vec4 r = roughness * c0 + c1;
	float a004 = min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;
	vec2 AB = vec2( -1.04, 1.04 ) * a004 + r.zw;
	return F0 * AB.x + AB.y;
}


vec3 PBR_ComputeIndirectLight(vec3 albedo, float roughness, float metallic, vec3 N, vec3 V)
{
	float ndotv = clamp(dot(N , V ), 1e-5f, 1);
	vec3 F0 = mix(vec3(0.04), albedo, metallic);		
	vec3 irradiance = texture(u_irradiancemap, N).rgb;
	vec3 F = F_Schlick(ndotv, F0);
	vec3 kd = mix(vec3(1.0) - F, vec3(0.0), metallic);
	vec3 diffuse = kd * albedo * irradiance;

	float lod = roughness * 8;
	vec3 RV = reflect(-V, N);
	vec3 radiance = textureLod(u_radiancemap, RV, lod).rgb;    
	vec3 specular = radiance * env_brdf_approx(F0, roughness, ndotv);
	
	return diffuse + specular;
}


vec3 rotateByQuat(vec4 rot, vec3 pos)
{
	vec3 uv = cross(rot.xyz, pos);
	vec3 uuv = cross(rot.xyz, uv);
	uv *= (2.0 * rot.w);
	uuv *= 2.0;

	return pos + uv + uuv;
}
	

vec3 pbr(vec3 albedo
	, float roughness
	, float metallic
	, float emission
	, vec3 N
	, vec3 V
	, vec3 L
	, float shadow
	, vec3 light_color
	, float indirect_intensity)
{
	vec3 indirect = PBR_ComputeIndirectLight(albedo, roughness, metallic, N, V);

	vec3 direct = PBR_ComputeDirectLight(albedo
		, N
		, L
		, V
		, light_color
		, roughness
		, metallic);

	return 
		+ direct * shadow
		+ indirect * indirect_intensity
		+ emission * albedo
	;
}
