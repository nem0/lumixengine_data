common_fragment = [[

	float getFogFactor(float fFogCoord, float fog_density) 
	{ 
		float fResult = exp(-pow(fog_density * fFogCoord, 2.0)); 
		fResult = 1.0-clamp(fResult, 0.0, 1.0); 
		return fResult;
	}
	
	float VSM(sampler2D depths, vec2 uv, float compare)
	{
		return smoothstep(compare-0.0001, compare, texture2D(depths, uv).x);
	}
	
	vec3 computeNormal(vec3 tangent, vec3 normal, vec2 tex_coords, sampler2D normalmap)
	{
		#ifdef NORMAL_MAPPING
			mat3 tangent_space_mtx = (mat3(
				normalize(tangent),
				normalize(normal),
				cross(normalize(tangent), normalize(normal))
			));
			vec3 local_normal = texture2D(normalmap, tex_coords).rbg * 2 - 1;
			return normalize(tangent_space_mtx * local_normal);
		#else
			return normal;
		#endif
	}
		
		
						
	float getShadowmapValue(
		vec4 position,
		mat4 shadowmap_matrix0,
		mat4 shadowmap_matrix1, 
		mat4 shadowmap_matrix2, 
		mat4 shadowmap_matrix3, 
		sampler2D shadowmap)
	{
		#ifdef SHADOW_RECEIVER
			vec3 shadow_coord[4] = vec3[](
				vec3(shadowmap_matrix0 * position),
				vec3(shadowmap_matrix1 * position),
				vec3(shadowmap_matrix2 * position),
				vec3(shadowmap_matrix3 * position)
			);
			vec2 tt[4] = vec2[](
				vec2(shadow_coord[0].x * 0.5, shadow_coord[0].y * 0.5),
				vec2(0.5 + shadow_coord[1].x * 0.5, shadow_coord[1].y * 0.5),
				vec2(shadow_coord[2].x * 0.5, 0.50 + shadow_coord[2].y * 0.5),
				vec2(0.5 + shadow_coord[3].x * 0.5, 0.5 + shadow_coord[3].y * 0.5)
			);

			int split_index = 3;
			if(step(shadow_coord[0].x, 0.99) * step(shadow_coord[0].y, 0.99)
				* step(0.01, shadow_coord[0].x)	* step(0.01, shadow_coord[0].y) > 0)
				split_index = 0;
			else if(step(shadow_coord[1].x, 0.99) * step(shadow_coord[1].y, 0.99)
				* step(0.01, shadow_coord[1].x)	* step(0.01, shadow_coord[1].y) > 0)
				split_index = 1;
			else if(step(shadow_coord[2].x, 0.99) * step(shadow_coord[2].y, 0.99)
				* step(0.01, shadow_coord[2].x)	* step(0.01, shadow_coord[2].y) > 0)
				split_index = 2;

			return step(shadow_coord[split_index].z, 1) * VSM(shadowmap, tt[split_index], shadow_coord[split_index].z);
		#else
			return 1;
		#endif
	}
	
]]
base_fragment_shader = common_fragment .. [[
	in vec4 			position;
	in vec3				normals;
	in vec3				tangents;
	in vec2 			tex_coords;
	out vec4			out_color;
	uniform sampler2D	tDiffuse;
	
	#ifdef SHADOW_PASS

		void main( void )
		{
			#ifdef ALPHA_CUTOUT
				vec4 surface = texture2D(tDiffuse, tex_coords).rgba;
				if(surface.a < 0.3)
					discard;
				out_color = vec4(1, 1, 1, normals.x + tangents.x);
			#else
				out_color = vec4(tex_coords, 1, normals.x + tangents.x); // if I remove tex_coords, normals from here, it also does not work correctly in #ifdef ALPHA_CUTOUT
				out_color = vec4(1, 0, 0, 1);
			#endif
		}

	#else
		uniform sampler2D	shadowmap;
		#ifdef NORMAL_MAPPING
			uniform sampler2D	normalmap;
		#endif
		uniform mat4 shadowmap_matrix0;
		uniform mat4 shadowmap_matrix1;
		uniform mat4 shadowmap_matrix2;
		uniform mat4 shadowmap_matrix3;
		uniform mat4 view_matrix;
		uniform vec3 light_dir;
		uniform vec4 ambient_color;
		uniform float ambient_intensity;
		uniform vec4 diffuse_color;
		uniform float diffuse_intensity;
		uniform vec4 fog_color;
		uniform float fog_density;
		#ifdef POINT_LIGHT_PASS
			uniform float light_fov;
			uniform vec3 light_pos;
			uniform float light_range;
		#endif
		
		void main( void )
		{
			vec4 surface = texture2D(tDiffuse, tex_coords).rgba;
			#ifdef ALPHA_CUTOUT
				if(surface.a < 0.30)
					discard;
			#endif
			#ifdef NORMAL_MAPPING
				vec3 normal = computeNormal(tangents, normals, tex_coords, normalmap);
			#else
				vec3 normal = normals;
			#endif
			vec4 p = view_matrix * position;
			float attenuation;
			float shadow;
			vec3 to_light_dir;
			
			#ifdef POINT_LIGHT_PASS
				vec4 ambient = vec4(0.0, 0.0, 0.0, 0.0);
				to_light_dir = position.xyz - light_pos;
				attenuation = 1.0 - clamp((length(to_light_dir) / light_range), 0.0, 1.0);
				to_light_dir = normalize(to_light_dir);
				attenuation *= 1 - clamp(acos(dot(to_light_dir, light_dir)) / light_fov, 0, 1);
				shadow = 1;
			#else
				attenuation = 1;
				shadow = getShadowmapValue(position, shadowmap_matrix0, shadowmap_matrix1, shadowmap_matrix2, shadowmap_matrix3, shadowmap);
				to_light_dir = light_dir; 
				vec4 ambient = ambient_intensity * surface * ambient_color;
			#endif // if POINT_LIGHT_PASS else

			shadow *=  max(0.0, dot(normal, -to_light_dir));
			vec4 diffuse = shadow * diffuse_intensity * surface * diffuse_color;
			out_color = mix(attenuation * (diffuse + ambient), fog_color, getFogFactor(p.z / p.w, fog_density));
		}
		
	#endif // if SHADOW_PASS else
]]
