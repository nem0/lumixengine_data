#ifndef __LUMIX_COMMON_SH__
#define __LUMIX_COMMON_SH__


#if BGFX_SHADER_LANGUAGE_HLSL
	#define BEGIN_CONST_ARRAY(type, count, name) static const type name[count] = {
	#define END_CONST_ARRAY }
#else
	#define BEGIN_CONST_ARRAY(type, count, name) const type name[count] = type[](
	#define END_CONST_ARRAY )
#endif


uniform mat4 u_camInvViewProj;
uniform mat4 u_camInvProj;
uniform mat4 u_camProj;
uniform mat4 u_camInvView;
uniform mat4 u_camView;




BEGIN_CONST_ARRAY (vec2, 8, POISSON_DISK_8) 
	vec2(0.9107129, -0.1382225),
	vec2(0.1669144, 0.1477467),
	vec2(0.2404192, -0.9629959),
	vec2(0.7414493, 0.4999895),
	vec2(-0.1282596, -0.3942416),
	vec2(-0.08354819, 0.7726957),
	vec2(-0.7772845, -0.5541942),
	vec2(-0.6782485, 0.119899)
END_CONST_ARRAY;



BEGIN_CONST_ARRAY (vec2, 16, POISSON_DISK_16) 
	vec2(0.3568125,-0.5825516),
	vec2(-0.2828444,-0.1149732),
	vec2(-0.2575171,-0.579991),
	vec2(0.3328768,-0.0916517),
	vec2(-0.0177952,-0.9652126),
	vec2(0.7636694,-0.3370355),
	vec2(0.9381924,0.05975571),
	vec2(0.6547356,0.373677),
	vec2(-0.1999273,0.4483816),
	vec2(0.167026,0.2838214),
	vec2(0.2164582,0.6978411),
	vec2(-0.7202712,-0.07400024),
	vec2(-0.6624036,0.559697),
	vec2(-0.1909649,0.8721116),
	vec2(-0.6493049,-0.4945979),
	vec2(0.6104985,0.7838438)
END_CONST_ARRAY;


float rand(vec4 seed)
{
	float dot_product = dot(seed, vec4(12.9898,78.233,45.164,94.673));
    return fract(sin(dot_product) * 43758.5453);
}

float rand(vec3 seed)
{
	float dot_product = dot(seed, vec3(12.9898,78.233,45.164));
    return fract(sin(dot_product) * 43758.5453);
}

float rand(vec2 seed)
{
	float dot_product = dot(seed, vec2(12.9898,78.233));
    return fract(sin(dot_product) * 43758.5453);
}

vec2 lit(vec3 light_dir, vec3 normal, vec3 view_dir, float shininess)
{
	float ndotl = dot(normal, light_dir);
	vec3 reflected = light_dir - 2.0 * ndotl * normal;
	float rdotv = max(0.0, dot(-reflected, view_dir));

	float diff = max(0.0, ndotl);
	
	float spec = step(0.0, ndotl) * pow(max(0.0, rdotv), shininess);
	return vec2(diff, step(1.0, shininess) * spec);
}


#if BGFX_SHADER_TYPE_FRAGMENT == 1
	vec3 shadePointLight(
		vec4 dir_fov, 
		vec3 wpos, 
		vec3 normal, 
		vec3 view, 
		vec2 uv,
		vec4 light_pos_radius,
		vec4 light_color_attenuation,
		vec4 material_specular_shininess,
		vec3 light_specular,
		vec3 texture_specular
		)
	{
		vec3 lp = light_pos_radius.xyz - wpos;
		float dist = length(lp);
		float attn = pow(max(0.0, 1.0 - dist / light_pos_radius.w), light_color_attenuation.w);
		
		vec3 to_light_dir = lp / dist;
		
		if(dir_fov.w < 3.14159)
		{
			float cosDir = dot(normalize(dir_fov.xyz), -to_light_dir);
			float cosCone = cos(dir_fov.w * 0.5);
		
			if(cosDir < cosCone) discard;
			attn *= (cosDir - cosCone) / (1.0 - cosCone);
		}
		
		vec2 lc = lit(to_light_dir, normal, view, material_specular_shininess.w);
		vec3 rgb = 
			attn * (light_color_attenuation.rgb * saturate(lc.x) 
			+ light_specular 
				* material_specular_shininess.rgb 
				* texture_specular 
				* saturate(lc.y));
		return rgb;
	}
#endif


float getFogFactor(vec3 camera_wpos, float fog_density, vec3 fragment_wpos, vec4 fog_params) 
{ 
	vec3 v = fragment_wpos - camera_wpos;
	float to_top = max(0.0, camera_wpos.y - (fog_params.x + fog_params.y));
	camera_wpos += v * to_top / -v.y;

	float frag_to_top = max(0.0, fragment_wpos.y - (fog_params.x + fog_params.y));
	fragment_wpos += v * frag_to_top / -v.y;
	
	float avg_y = (fragment_wpos.y + camera_wpos.y) * 0.5;
	float avg_density = fog_density * clamp(1.0 - (avg_y - fog_params.x) / fog_params.y, 0, 1);
	float res = exp(-pow(avg_density * length(fragment_wpos - camera_wpos), 2));
	return 1 - clamp(res, 0.0, 1.0);
}


vec3 shadeDirectionalLight(vec3 light_dir
	, vec3 view_dir
	, vec3 light_color
	, vec3 light_specular
	, vec3 normal
	, vec4 material_specular_shininess
	, vec3 texture_specular)
{
	float ndotl = dot(normal, light_dir);
	vec3 reflected = light_dir - 2.0 * ndotl * normal;
	float rdotv = max(0.0, dot(reflected, view_dir));
	float shininess = max(0.0001, material_specular_shininess.w);
	float spec = pow(max(0.0, rdotv), shininess);
	vec3 col = step(0.0, -ndotl) * 
		(-ndotl * light_color
			+ light_specular 
				* material_specular_shininess.rgb 
				* texture_specular 
				* step(1.0, shininess) * spec);
	return col;	
}

float noCheckESM(sampler2D shadowmap, vec2 shadow_coord, float receiver, float depth_multiplier)
{
	float occluder = texture2D(shadowmap, shadow_coord).r * 0.5 + 0.5;

	float visibility = clamp(exp(depth_multiplier * (occluder - receiver)), 0.0, 1.0);

	return visibility;
}

float ESM(sampler2D shadowmap, vec4 shadow_coord, float bias, float depth_multiplier)
{
	vec2 texCoord = shadow_coord.xy / shadow_coord.w;

	bool outside = any(greaterThan(texCoord, vec2_splat(1.0)))
				|| any(lessThan   (texCoord, vec2_splat(0.0)));

	if (outside) return 1.0;

	float receiver = (shadow_coord.z - bias) / shadow_coord.w;
	float occluder = (texture2D(shadowmap, texCoord).r * 0.5 + 0.5);

	float visibility = clamp(exp(depth_multiplier * (occluder - receiver)), 0.0, 1.0);

	return visibility;
}


float pointLightShadow(sampler2D shadowmap, mat4 shadowmap_matrices[4], vec4 position, float fov)
{
	const float DEPTH_MULTIPLIER = 900.0;

	if(fov > 3.14159)
	{
		vec4 a = mul(shadowmap_matrices[0], position);
		vec4 b = mul(shadowmap_matrices[1], position);
		vec4 c = mul(shadowmap_matrices[2], position);
		vec4 d = mul(shadowmap_matrices[3], position);
		
		a = a / a.w;
		b = b / b.w;
		c = c / c.w;
		d = d / d.w;
	
		bool selection0 = all(lessThan(a.xy, vec2_splat(0.99))) && all(greaterThan(a.xy, vec2_splat(0.01))) && a.z < 1.0;
		if(selection0) return noCheckESM(shadowmap, vec2(a.x * 0.5, a.y * 0.5), a.z, DEPTH_MULTIPLIER);

		bool selection1 = all(lessThan(b.xy, vec2_splat(0.99))) && all(greaterThan(b.xy, vec2_splat(0.01))) && b.z < 1.0;
		if(selection1) return noCheckESM(shadowmap, vec2(0.5 + b.x * 0.5, b.y * 0.5), b.z, DEPTH_MULTIPLIER);
		
		bool selection2 = all(lessThan(c.xy, vec2_splat(0.99))) && all(greaterThan(c.xy, vec2_splat(0.01))) && c.z < 1.0;
		if(selection2) return noCheckESM(shadowmap, vec2(c.x * 0.5, 0.5 + c.y * 0.5), c.z, DEPTH_MULTIPLIER);
		
		return noCheckESM(shadowmap, vec2(0.5 + d.x * 0.5, 0.5 + d.y * 0.5), d.z, DEPTH_MULTIPLIER);
	}
	else
	{
		vec4 tmp = mul(shadowmap_matrices[0], position);
		vec3 shadow_coord = tmp.xyz / tmp.w;
			return ESM(shadowmap, vec4(shadow_coord.xy, shadow_coord.z, 1.0), 0.0, DEPTH_MULTIPLIER);
	}
}


float directionalLightShadow(sampler2D shadowmap, mat4 shadowmap_matrices[4], vec4 position, float ndotl)
{
	vec3 shadow_coord[4];
	shadow_coord[0] = mul(shadowmap_matrices[0], position).xyz;
	shadow_coord[1] = mul(shadowmap_matrices[1], position).xyz;
	shadow_coord[2] = mul(shadowmap_matrices[2], position).xyz;
	shadow_coord[3] = mul(shadowmap_matrices[3], position).xyz;

	vec2 shadow_subcoords[2];

	int split_index = 3;
	float weight = 0.0;
	if(all(lessThan(shadow_coord[0].xy, vec2_splat(1.0))) && all(greaterThan(shadow_coord[0].xy, vec2_splat(0.0))))
	{
		shadow_subcoords[0] = vec2(shadow_coord[0].x * 0.5, shadow_coord[0].y * 0.5);
		shadow_subcoords[1] = vec2(0.5 + shadow_coord[1].x * 0.5, shadow_coord[1].y * 0.5);
		weight = max(max(abs(shadow_coord[0].x - 0.5) - 0.3, 0), max(abs(shadow_coord[0].y - 0.5) - 0.3, 0)) * 5.0;
		split_index = 0;
	}
	else if(all(lessThan(shadow_coord[1].xy, vec2_splat(1.0))) && all(greaterThan(shadow_coord[1].xy, vec2_splat(0.0))))
	{
		shadow_subcoords[0] = vec2(0.5 + shadow_coord[1].x * 0.5, shadow_coord[1].y * 0.5);
		shadow_subcoords[1] = vec2(shadow_coord[2].x * 0.5, 0.5 + shadow_coord[2].y * 0.5);
		weight = max(max(abs(shadow_coord[1].x - 0.5) - 0.3, 0), max(abs(shadow_coord[1].y - 0.5) - 0.3, 0)) * 5.0;
		split_index = 1;
	}
	else if(all(lessThan(shadow_coord[2].xy, vec2_splat(1.0))) && all(greaterThan(shadow_coord[2].xy, vec2_splat(0.0))))
	{
		shadow_subcoords[0] = vec2(shadow_coord[2].x * 0.5, 0.5 + shadow_coord[2].y * 0.5);
		shadow_subcoords[1] = vec2(0.5 + shadow_coord[3].x * 0.5, 0.5 + shadow_coord[3].y * 0.5);
		weight = max(max(abs(shadow_coord[2].x - 0.5) - 0.3, 0), max(abs(shadow_coord[2].y - 0.5) - 0.3, 0)) * 5.0;
		split_index = 2;
	}
	else if(all(lessThan(shadow_coord[3].xy, vec2_splat(1.0))) && all(greaterThan(shadow_coord[3].xy, vec2_splat(0.0))))
	{
		shadow_subcoords[0] = vec2(0.5 + shadow_coord[3].x * 0.5, 0.5 + shadow_coord[3].y * 0.5);
		weight = max(max(abs(shadow_coord[3].x - 0.5) - 0.3, 0), max(abs(shadow_coord[3].y - 0.5) - 0.3, 0)) * 5.0;
		split_index = 3;
	}
	else
		return 1.0;

	BEGIN_CONST_ARRAY(float, 5, offsets) 0.0000009, 0.000005, 0.00001, 0.00005, -1.0 END_CONST_ARRAY; // for distances 6, 14, 40, 100
	float nl_tan = tan(acos(ndotl));
	float bias = clamp(offsets[split_index] * nl_tan, 0.0, 0.1); 
	float next_bias = clamp(offsets[split_index + 1] * nl_tan, 0.0, 0.1); 

	float v1 = noCheckESM(shadowmap, shadow_subcoords[0], shadow_coord[split_index].z - bias, 15000.0);
	float v2 = split_index == 3 ? 1.0 : noCheckESM(shadowmap, shadow_subcoords[1], shadow_coord[split_index + 1].z - next_bias, 15000.0);
	return mix(v1, v2, weight);
}



// simple == no smooth transition between cascades
float directionalLightShadowSimple(sampler2D shadowmap, mat4 shadowmap_matrices[4], vec4 position, float ndotl)
{
	vec3 shadow_coord[4];
	shadow_coord[0] = mul(shadowmap_matrices[0], position).xyz;
	shadow_coord[1] = mul(shadowmap_matrices[1], position).xyz;
	shadow_coord[2] = mul(shadowmap_matrices[2], position).xyz;
	shadow_coord[3] = mul(shadowmap_matrices[3], position).xyz;

	vec2 shadow_subcoords[2];

	int split_index = 3;
	float weight = 0.0;
	if(all(lessThan(shadow_coord[0].xy, vec2_splat(1.0))) && all(greaterThan(shadow_coord[0].xy, vec2_splat(0.0))))
	{
		return noCheckESM(shadowmap, vec2(shadow_coord[0].x * 0.5, shadow_coord[0].y * 0.5), shadow_coord[0].z, 15000.0);
	}
	else if(all(lessThan(shadow_coord[1].xy, vec2_splat(1.0))) && all(greaterThan(shadow_coord[1].xy, vec2_splat(0.0))))
	{
		return noCheckESM(shadowmap, vec2(0.5 + shadow_coord[1].x * 0.5, shadow_coord[1].y * 0.5), shadow_coord[1].z, 15000.0);
	}
	else if(all(lessThan(shadow_coord[2].xy, vec2_splat(1.0))) && all(greaterThan(shadow_coord[2].xy, vec2_splat(0.0))))
	{
		return noCheckESM(shadowmap, vec2(shadow_coord[2].x * 0.5, 0.5 + shadow_coord[2].y * 0.5), shadow_coord[2].z, 15000.0);
	}
	else if(all(lessThan(shadow_coord[3].xy, vec2_splat(1.0))) && all(greaterThan(shadow_coord[3].xy, vec2_splat(0.0))))
	{
		return noCheckESM(shadowmap, vec2(0.5 + shadow_coord[3].x * 0.5, 0.5 + shadow_coord[3].y * 0.5), shadow_coord[3].z, 15000.0);
	}
	else
		return 1.0;
}



void PBR_ComputeDirectLight(vec3 normal, vec3 lightDir, vec3 viewDir,
                            vec3 lightColor, float fZero, float roughness,
                            out vec3 outDiffuse, out vec3 outSpecular)
{
    vec3 halfVec = normalize(lightDir + viewDir);
    float ndotl = saturate(dot(normal,   lightDir));
    float hdotv = saturate(dot(viewDir,  halfVec));
    float ndoth = saturate(dot(normal,   halfVec));       

    outDiffuse = vec3_splat(ndotl) * lightColor;

    float alpha = roughness * roughness;
    float alpha2 = alpha * alpha;
    float sum  = ((ndoth * ndoth) * (alpha2 - 1.0) + 1.0);
    float denom = M_PI * sum * sum;
    float D = alpha2 / denom;  

	float F_b = pow(1 - hdotv, 5);
	float k = alpha2 * 0.25;
	float inv_k = 1 - k;
	float vis = 1/(hdotv * hdotv * inv_k + k);
    float specular = ndotl * D * (fZero * vis + (1-fZero) * F_b * vis); 
	
    outSpecular = vec3_splat(specular) * lightColor;
}


vec3 PBR_ComputeIndirectDiffuse(samplerCube irradiance_map, vec3 normal, vec3 diffuseColor)
{
	return textureCube(irradiance_map, normal.xyz).rgb * diffuseColor.rgb;
}


// from urho
vec3 EnvBRDFApprox (vec3 SpecularColor, float Roughness, float NoV)
{
	vec4 c0 = vec4(-1, -0.0275, -0.572, 0.022 );
	vec4 c1 = vec4(1, 0.0425, 1.0, -0.04 );
	vec4 r = Roughness * c0 + c1;
	float a004 = min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;
	vec2 AB = vec2( -1.04, 1.04 ) * a004 + r.zw;
	return SpecularColor * AB.x + AB.y;
}


vec3 PBR_ComputeIndirectSpecular(samplerCube radiance_map, vec3 spec_color , float roughness, float ndotv, vec3 reflected_vec)
{
    float Lod = roughness * 8;
    vec3 PrefilteredColor =  textureCubeLod(radiance_map, reflected_vec.xyz, Lod).rgb;    
    return PrefilteredColor * EnvBRDFApprox(spec_color, roughness, ndotv);
}


vec3 getScreenCoord(vec3 world_pos)
{
	vec4 prj = mul(u_viewProj, vec4(world_pos, 1.0) );
	prj.y = -prj.y;
	prj /= prj.w;
	return prj.xyz;
}


float toLinearDepth(float ndc_depth)
{
	vec4 linear_depth_v = mul(u_invProj, vec4(0, 0, ndc_depth, 1));
	return linear_depth_v.z / linear_depth_v.w;
}


vec3 getViewPosition(sampler2D depth_buffer, mat4 inv_view_proj, vec2 tex_coord)
{
	float z = texture2D(depth_buffer, tex_coord).r;
	#if BGFX_SHADER_LANGUAGE_HLSL
		z = z;
	#else
		z = z * 2.0 - 1.0;
	#endif // BGFX_SHADER_LANGUAGE_HLSL
	vec4 pos_proj = vec4(tex_coord * 2 - 1, z, 1.0);
	#if BGFX_SHADER_LANGUAGE_HLSL
		pos_proj.y = -pos_proj.y;
	#endif // BGFX_SHADER_LANGUAGE_HLSL
	
	vec4 view_pos = mul(inv_view_proj, pos_proj);
	
	return view_pos.xyz / view_pos.w;
}

#endif