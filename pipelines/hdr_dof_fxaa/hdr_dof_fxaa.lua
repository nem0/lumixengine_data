hdr_exposure = 4
dof_focal_distance = 0
dof_focal_range = 10
dof_enabled = true
film_grain_enabled = true
grain_amount = 0.02
grain_size = 1.6
enabled = true
max_dof_blur = 1
dof_clear_range = 75
dof_near_multiplier = 100
fxaa_enabled = true
vignette_radius = 0.5
vignette_softness = 0.35
vignette_enabled = true
bloom_enabled = false

local pipeline_env = nil

local current_lum1 = "lum1a"
local lum_uniforms = {}


function computeLumUniforms()
	local sizes = {64, 16, 4, 1 }
	for key,value in ipairs(sizes) do
		lum_uniforms[value] = {}
		for j = 0,3 do
			for i = 0,3 do
				local x = (i) / value; 
				local y = (j) / value; 
				lum_uniforms[value][1 + i + j * 4] = {x, y, 0, 0}
			end
		end
	end

	lum_uniforms[128] = {}
	for j = 0,1 do
		for i = 0,1 do
			local x = i / 128; 
			local y = j / 128; 
			lum_uniforms[128][1 + i + j * 4] = {x, y, 0, 0}
		end
	end
end
computeLumUniforms()

function initHDR(ctx)
	addFramebuffer(ctx.pipeline, "lum128", {
		width = 128,
		height = 128,
		renderbuffers = {
			{ format = "r32f" }
		}
	})

	addFramebuffer(ctx.pipeline,  "lum64", {
		width = 64,
		height = 64,
		renderbuffers = {
			{ format = "r32f" }
		}
	})

	addFramebuffer(ctx.pipeline,  "lum16", {
		width = 16,
		height = 16,
		renderbuffers = {
			{ format = "r32f" }
		}
	})

	addFramebuffer(ctx.pipeline,  "lum4", {
		width = 4,
		height = 4,
		renderbuffers = {
			{ format = "r32f" }
		}
	})

	addFramebuffer(ctx.pipeline,  "lum1a", {
		width = 1,
		height = 1,
		renderbuffers = {
			{ format = "r32f" }
		}
	})

	addFramebuffer(ctx.pipeline,  "lum1b", {
		width = 1,
		height = 1,
		renderbuffers = {
			{ format = "r32f" }
		}
	})
	
	addFramebuffer(ctx.pipeline,  "hdr", {
		width = 1024,
		height = 1024,
		screen_size = true,
		renderbuffers = {
			{ format = "rgba16f" },
			{ format = "depth24stencil8" }
		}
	})

	addFramebuffer(ctx.pipeline,  "dof", {
		width = 1024,
		height = 1024,
		size_ratio = { 0.5, 0.5},
		renderbuffers = {
			{ format = "rgba16f" },
		}
	})

	addFramebuffer(ctx.pipeline,  "dof_blur", {
		width = 1024,
		height = 1024,
		size_ratio = { 0.5, 0.5},
		renderbuffers = {
			{ format = "rgba8" },
		}
	})

	if fxaa_enabled then	
		addFramebuffer(ctx.pipeline, "fxaa", {
			width = 1024,
			height = 1024,
			size_ratio = {1, 1},
			renderbuffers = {
				{ format = "rgba8" },
			}
		})
	end
	
	ctx.avg_luminance_uniform = createUniform(ctx.pipeline, "u_avgLuminance")
	ctx.grain_amount_uniform = createUniform(ctx.pipeline, "u_grainAmount")
	ctx.grain_size_uniform = createUniform(ctx.pipeline, "u_grainSize")
	ctx.lum_material = Engine.loadResource(g_engine, "pipelines/hdr_dof_fxaa/hdrlum.mat", "material")
	ctx.hdr_material = Engine.loadResource(g_engine, "pipelines/hdr_dof_fxaa/hdr.mat", "material")
	ctx.fxaa_material = Engine.loadResource(g_engine, "pipelines/hdr_dof_fxaa/fxaa.mat", "material")
	ctx.hdr_buffer_uniform = createUniform(ctx.pipeline, "u_hdrBuffer")
	ctx.dof_buffer_uniform = createUniform(ctx.pipeline, "u_dofBuffer")
	ctx.fxaa_buffer_uniform = createUniform(ctx.pipeline, "u_fxaaBuffer")
	ctx.hdr_exposure_uniform = createVec4ArrayUniform(ctx.pipeline, "exposure", 1)
	ctx.dof_focal_distance_uniform = createUniform(ctx.pipeline, "focal_distance", 1)
	ctx.dof_focal_range_uniform = createUniform(ctx.pipeline, "focal_range", 1)
	ctx.max_dof_blur_uniform = createUniform(ctx.pipeline, "max_dof_blur", 1)
	ctx.dof_near_multiplier_uniform = createUniform(ctx.pipeline, "dof_near_multiplier", 100)
	ctx.dof_clear_range_uniform = createUniform(ctx.pipeline, "clear_range", 0)
	ctx.lum_size_uniform = createVec4ArrayUniform(ctx.pipeline, "u_offset", 16)
	ctx.vignette_uniform = createUniform(ctx.pipeline, "u_vignette")
end

function hdr(ctx, camera_slot)
	bloom(ctx, ctx.pipeline)

	newView(ctx.pipeline, "hdr_luminance")
		setPass(ctx.pipeline, "HDR_LUMINANCE")
		setFramebuffer(ctx.pipeline, "lum128")
		disableDepthWrite(ctx.pipeline)
		disableBlending(ctx.pipeline)
		setUniform(ctx.pipeline, ctx.lum_size_uniform, lum_uniforms[128])
		bindFramebufferTexture(ctx.pipeline, "hdr", 0, ctx.hdr_buffer_uniform)
		drawQuad(ctx.pipeline, 0, 0, 1, 1, ctx.lum_material)
	
	newView(ctx.pipeline, "hdr_avg_luminance")
		setPass(ctx.pipeline, "HDR_AVG_LUMINANCE")
		setFramebuffer(ctx.pipeline, "lum64")
		setUniform(ctx.pipeline, ctx.lum_size_uniform, lum_uniforms[64])
		bindFramebufferTexture(ctx.pipeline, "lum128", 0, ctx.hdr_buffer_uniform)
		drawQuad(ctx.pipeline, 0, 0, 1, 1, ctx.lum_material)

	newView(ctx.pipeline, "lum16")
		setPass(ctx.pipeline, "HDR_AVG_LUMINANCE")
		setFramebuffer(ctx.pipeline, "lum16")
		setUniform(ctx.pipeline, ctx.lum_size_uniform, lum_uniforms[16])
		bindFramebufferTexture(ctx.pipeline, "lum64", 0, ctx.hdr_buffer_uniform)
		drawQuad(ctx.pipeline, 0, 0, 1, 1, ctx.lum_material)
	
	newView(ctx.pipeline, "lum4")
		setPass(ctx.pipeline, "HDR_AVG_LUMINANCE")
		setFramebuffer(ctx.pipeline, "lum4")
		setUniform(ctx.pipeline, ctx.lum_size_uniform, lum_uniforms[4])
		bindFramebufferTexture(ctx.pipeline, "lum16", 0, ctx.hdr_buffer_uniform)
		drawQuad(ctx.pipeline, 0, 0, 1, 1, ctx.lum_material)

	local old_lum1 = "lum1b"
	if ctx.current_lum1 == "lum1a" then 
		ctx.current_lum1 = "lum1b" 
		old_lum1 = "lum1a"
	else 
		ctx.current_lum1 = "lum1a" 
	end

	newView(ctx.pipeline, "lum1")
		setPass(ctx.pipeline, "LUM1")
		setFramebuffer(ctx.pipeline, ctx.current_lum1)
		setUniform(ctx.pipeline, ctx.lum_size_uniform, lum_uniforms[1])
		bindFramebufferTexture(ctx.pipeline, "lum4", 0, ctx.hdr_buffer_uniform)
		bindFramebufferTexture(ctx.pipeline, old_lum1, 0, ctx.avg_luminance_uniform)
		drawQuad(ctx.pipeline, 0, 0, 1, 1, ctx.lum_material)

	setMaterialDefine(ctx.pipeline, ctx.hdr_material, "FILM_GRAIN", film_grain_enabled)
	setMaterialDefine(ctx.pipeline, ctx.hdr_material, "DOF", dof_enabled)	
	setMaterialDefine(ctx.pipeline, ctx.hdr_material, "VIGNETTE", vignette_enabled)	
	if dof_enabled then
		newView(ctx.pipeline, "dof")
			disableDepthWrite(ctx.pipeline)
			setPass(ctx.pipeline, "MAIN")
			setFramebuffer(ctx.pipeline, "dof")
			bindFramebufferTexture(ctx.pipeline, "hdr", 0, ctx.texture_uniform)
			drawQuad(ctx.pipeline, 0, 0, 1, 1, ctx.screen_space_material)


		newView(ctx.pipeline, "blur_dof_h")
			setPass(ctx.pipeline, "BLUR_H")
			setFramebuffer(ctx.pipeline, "dof_blur")
			disableDepthWrite(ctx.pipeline)
			bindFramebufferTexture(ctx.pipeline, "dof", 0, ctx.shadowmap_uniform)
			drawQuad(ctx.pipeline, 0, 0, 1, 1, ctx.blur_material)
			enableDepthWrite(ctx.pipeline)

		newView(ctx.pipeline, "blur_dof_v")
			setPass(ctx.pipeline, "BLUR_V")
			setFramebuffer(ctx.pipeline, "dof")
			disableDepthWrite(ctx.pipeline)
			bindFramebufferTexture(ctx.pipeline, "dof_blur", 0, ctx.shadowmap_uniform)
			drawQuad(ctx.pipeline, 0, 0, 1, 1, ctx.blur_material);
			enableDepthWrite(ctx.pipeline)

		newView(ctx.pipeline, "hdr_dof")
			setPass(ctx.pipeline, "MAIN")
			if fxaa_enabled then
				setFramebuffer(ctx.pipeline, "fxaa")
			else
				setFramebuffer(ctx.pipeline, "default")
			end
			disableBlending(ctx.pipeline)
			applyCamera(ctx.pipeline, camera_slot)
			disableDepthWrite(ctx.pipeline)
			clear(ctx.pipeline, CLEAR_COLOR | CLEAR_DEPTH, 0x00000000)

			bindFramebufferTexture(ctx.pipeline, "hdr", 0, ctx.hdr_buffer_uniform)
			bindFramebufferTexture(ctx.pipeline, ctx.current_lum1, 0, ctx.avg_luminance_uniform)
			bindFramebufferTexture(ctx.pipeline, "dof", 0, ctx.dof_buffer_uniform)
			bindFramebufferTexture(ctx.pipeline, "hdr", 1, ctx.depth_buffer_uniform)

			setUniform(ctx.pipeline, ctx.dof_focal_distance_uniform, {{dof_focal_distance, 0, 0, 0}})
			setUniform(ctx.pipeline, ctx.dof_focal_range_uniform, {{dof_focal_range, 0, 0, 0}})
			setUniform(ctx.pipeline, ctx.max_dof_blur_uniform, {{max_dof_blur, 0, 0, 0}})
			setUniform(ctx.pipeline, ctx.dof_clear_range_uniform, {{dof_clear_range, 0, 0, 0}})
			setUniform(ctx.pipeline, ctx.dof_near_multiplier_uniform, {{dof_near_multiplier, 0, 0, 0}})
	else
		newView(ctx.pipeline, "hdr")
			setPass(ctx.pipeline, "MAIN")
			if fxaa_enabled then
				setFramebuffer(ctx.pipeline, "fxaa")
			else
				setFramebuffer(ctx.pipeline, "default")
			end
			disableBlending(ctx.pipeline)
			applyCamera(ctx.pipeline, camera_slot)
			disableDepthWrite(ctx.pipeline)
			clear(ctx.pipeline, CLEAR_COLOR | CLEAR_DEPTH, 0x00000000)
			bindFramebufferTexture(ctx.pipeline, "hdr", 0, ctx.hdr_buffer_uniform)
			bindFramebufferTexture(ctx.pipeline, ctx.current_lum1, 0, ctx.avg_luminance_uniform)
	end
	if vignette_enabled then 
		setUniform(ctx.pipeline, ctx.vignette_uniform, {{vignette_radius, vignette_softness, 0, 0}})
	end
	if film_grain_enabled then
		setUniform(ctx.pipeline, ctx.grain_amount_uniform, {{grain_amount, 0, 0, 0}})
		setUniform(ctx.pipeline, ctx.grain_size_uniform, {{grain_size, 0, 0, 0}})
	end
	setUniform(ctx.pipeline, ctx.hdr_exposure_uniform, {{hdr_exposure, 0, 0, 0}})
	drawQuad(ctx.pipeline, 0, 0, 1, 1, ctx.hdr_material)

	fxaa(ctx, camera_slot)
end


function initBloom(pipeline, env)
	env.ctx.extract_material = Engine.loadResource(g_engine, "pipelines/hdr_dof_fxaa/bloomextract.mat", "material")
	env.ctx.bloom_material = Engine.loadResource(g_engine, "pipelines/hdr_dof_fxaa/bloom.mat", "material")
	addFramebuffer(env.ctx.pipeline, "bloom_extract", {
		size_ratio = { 0.5, 0.5},
		renderbuffers = {
			{ format = "rgba16f" }
		}
	})

	addFramebuffer(env.ctx.pipeline, "bloom_blur", {
		size_ratio = { 0.5, 0.5},
		renderbuffers = {
			{ format = "rgba16f" }
		}
	})
end


function bloom(ctx, pipeline)
	if not bloom_enabled then return end
	newView(pipeline, "bloom_extract")
		setPass(pipeline, "MAIN")
		disableBlending(pipeline)
		disableDepthWrite(pipeline)
		setFramebuffer(pipeline, "bloom_extract")
		bindFramebufferTexture(pipeline, "hdr", 0, ctx.texture_uniform)
		drawQuad(pipeline, 0, 0, 1, 1, ctx.extract_material)
	
	newView(ctx.pipeline, "blur_bloom_h")
		setPass(ctx.pipeline, "BLUR_H")
		setFramebuffer(ctx.pipeline, "bloom_blur")
		disableDepthWrite(ctx.pipeline)
		bindFramebufferTexture(ctx.pipeline, "bloom_extract", 0, ctx.shadowmap_uniform)
		drawQuad(ctx.pipeline, 0, 0, 1, 1, ctx.blur_material)
		enableDepthWrite(ctx.pipeline)

	newView(ctx.pipeline, "blur_bloom_v")
		setPass(ctx.pipeline, "BLUR_V")
		setFramebuffer(ctx.pipeline, "bloom_extract")
		disableDepthWrite(ctx.pipeline)
		bindFramebufferTexture(ctx.pipeline, "bloom_blur", 0, ctx.shadowmap_uniform)
		drawQuad(ctx.pipeline, 0, 0, 1, 1, ctx.blur_material);
		enableDepthWrite(ctx.pipeline)
		
	newView(pipeline, "bloom")
		setPass(pipeline, "MAIN")
		enableBlending(pipeline, "add")
		disableDepthWrite(pipeline)
		setFramebuffer(pipeline, "hdr")
		bindFramebufferTexture(pipeline, "bloom_extract", 0, ctx.texture_uniform)
		drawQuad(pipeline, 0, 0, 1, 1, ctx.bloom_material)
end

function fxaa(ctx, camera_slot)
		if not fxaa_enabled then return end
		
		newView(ctx.pipeline, "fxaa")
			setPass(ctx.pipeline, "MAIN")
			setFramebuffer(ctx.pipeline, "default")
			disableBlending(ctx.pipeline)
			applyCamera(ctx.pipeline, camera_slot)
			disableDepthWrite(ctx.pipeline)
			clear(ctx.pipeline, CLEAR_DEPTH, 0x00000000)
			bindFramebufferTexture(ctx.pipeline, "fxaa", 0, ctx.fxaa_buffer_uniform)
			drawQuad(ctx.pipeline, 0, 0, 1, 1, ctx.fxaa_material)
end

function onDestroy()
	if pipeline_env then
		removeFramebuffer(pipeline_env.ctx.pipeline, "lum128")
		removeFramebuffer(pipeline_env.ctx.pipeline, "lum64")
		removeFramebuffer(pipeline_env.ctx.pipeline, "lum16")
		removeFramebuffer(pipeline_env.ctx.pipeline, "lum4")
		removeFramebuffer(pipeline_env.ctx.pipeline, "lum1a")
		removeFramebuffer(pipeline_env.ctx.pipeline, "lum1b")
		removeFramebuffer(pipeline_env.ctx.pipeline, "hdr")
		removeFramebuffer(pipeline_env.ctx.pipeline, "dof")
		removeFramebuffer(pipeline_env.ctx.pipeline, "dof_blur")
		pipeline_env.ctx.main_framebuffer = original_framebuffer
		pipeline_env.do_gamma_mapping = true
	end
end

function initPostprocess(pipeline, env)
	pipeline_env = env
	initBloom(pipeline, env)
	initHDR(env.ctx)
	original_framebuffer = env.ctx.main_framebuffer
	env.ctx.main_framebuffer = "hdr"
	env.do_gamma_mapping = false
end

function postprocess(pipeline, env)
	
	if enabled then
		camera_cmp = Renderer.getCameraComponent(g_scene_renderer, this)
		slot = Renderer.getCameraSlot(g_scene_renderer, camera_cmp)
		env.ctx.main_framebuffer = "hdr"
		hdr(env.ctx, slot)
		env.do_gamma_mapping = false
	else
		env.ctx.main_framebuffer = original_framebuffer
		env.do_gamma_mapping = true
	end
end