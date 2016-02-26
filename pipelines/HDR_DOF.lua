hdr_exposure = 1
dof_focal_distance = 0
dof_focal_range = 10
dof_enabled = true
enabled = true

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
			{ format = "depth32" }
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
	
	ctx.avg_luminance_uniform = createUniform(ctx.pipeline, "u_avgLuminance")
	ctx.lum_material = loadMaterial(ctx.pipeline, "shaders/hdrlum.mat")
	ctx.hdr_material = loadMaterial(ctx.pipeline, "shaders/hdr.mat")
	ctx.hdr_buffer_uniform = createUniform(ctx.pipeline, "u_hdrBuffer")
	ctx.dof_buffer_uniform = createUniform(ctx.pipeline, "u_dofBuffer")
	ctx.hdr_exposure_uniform = createVec4ArrayUniform(ctx.pipeline, "exposure", 1)
	ctx.dof_focal_distance_uniform = createUniform(ctx.pipeline, "focal_distance", 1)
	ctx.dof_focal_range_uniform = createUniform(ctx.pipeline, "focal_range", 1)
	ctx.lum_size_uniform = createVec4ArrayUniform(ctx.pipeline, "u_offset", 16)
	computeLumUniforms()
end

function hdr(ctx, camera_slot)
	newView(ctx.pipeline, "hdr_luminance")
		setPass(ctx.pipeline, "HDR_LUMINANCE")
		setFramebuffer(ctx.pipeline, "lum128")
		disableDepthWrite(ctx.pipeline)
		disableBlending(ctx.pipeline)
		setUniform(ctx.pipeline, ctx.lum_size_uniform, lum_uniforms[128])
		bindFramebufferTexture(ctx.pipeline, "hdr", 0, ctx.hdr_buffer_uniform)
		drawQuad(ctx.pipeline, -1, -1, 2, 2, ctx.lum_material)
	
	newView(ctx.pipeline, "hdr_avg_luminance")
		setPass(ctx.pipeline, "HDR_AVG_LUMINANCE")
		setFramebuffer(ctx.pipeline, "lum64")
		setUniform(ctx.pipeline, ctx.lum_size_uniform, lum_uniforms[64])
		bindFramebufferTexture(ctx.pipeline, "lum128", 0, ctx.hdr_buffer_uniform)
		drawQuad(ctx.pipeline, -1, -1, 2, 2, ctx.lum_material)

	newView(ctx.pipeline, "lum16")
		setPass(ctx.pipeline, "HDR_AVG_LUMINANCE")
		setFramebuffer(ctx.pipeline, "lum16")
		setUniform(ctx.pipeline, ctx.lum_size_uniform, lum_uniforms[16])
		bindFramebufferTexture(ctx.pipeline, "lum64", 0, ctx.hdr_buffer_uniform)
		drawQuad(ctx.pipeline, -1, -1, 2, 2, ctx.lum_material)
	
	newView(ctx.pipeline, "lum4")
		setPass(ctx.pipeline, "HDR_AVG_LUMINANCE")
		setFramebuffer(ctx.pipeline, "lum4")
		setUniform(ctx.pipeline, ctx.lum_size_uniform, lum_uniforms[4])
		bindFramebufferTexture(ctx.pipeline, "lum16", 0, ctx.hdr_buffer_uniform)
		drawQuad(ctx.pipeline, -1, -1, 2, 2, ctx.lum_material)

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
		drawQuad(ctx.pipeline, -1, -1, 2, 2, ctx.lum_material)

	if dof_enabled then
		newView(ctx.pipeline, "dof")
			disableDepthWrite(ctx.pipeline)
			setPass(ctx.pipeline, "SCREEN_SPACE")
			setFramebuffer(ctx.pipeline, "dof")
			bindFramebufferTexture(ctx.pipeline, "hdr", 0, ctx.texture_uniform)
			drawQuad(ctx.pipeline, -1, 1.0, 2, -2, ctx.screen_space_material)


		newView(ctx.pipeline, "blur_dof_h")
			setPass(ctx.pipeline, "BLUR_H")
			setFramebuffer(ctx.pipeline, "dof_blur")
			disableDepthWrite(ctx.pipeline)
			bindFramebufferTexture(ctx.pipeline, "dof", 0, ctx.shadowmap_uniform)
			drawQuad(ctx.pipeline, -1, -1, 2, 2, ctx.blur_material)
			enableDepthWrite(ctx.pipeline)

		newView(ctx.pipeline, "blur_dof_v")
			setPass(ctx.pipeline, "BLUR_V")
			setFramebuffer(ctx.pipeline, "dof")
			disableDepthWrite(ctx.pipeline)
			bindFramebufferTexture(ctx.pipeline, "dof_blur", 0, ctx.shadowmap_uniform)
			drawQuad(ctx.pipeline, -1, -1, 2, 2, ctx.blur_material);
			enableDepthWrite(ctx.pipeline)

		newView(ctx.pipeline, "hdr_dof")
			setPass(ctx.pipeline, "HDR_DOF")
			setFramebuffer(ctx.pipeline, "default")
			disableBlending(ctx.pipeline)
			applyCamera(ctx.pipeline, camera_slot)
			disableDepthWrite(ctx.pipeline)
			clear(ctx.pipeline, CLEAR_COLOR | CLEAR_DEPTH, 0x00000000)

			bindFramebufferTexture(ctx.pipeline, "hdr", 0, ctx.hdr_buffer_uniform)
			bindFramebufferTexture(ctx.pipeline, ctx.current_lum1, 0, ctx.avg_luminance_uniform)
			bindFramebufferTexture(ctx.pipeline, "dof", 0, ctx.dof_buffer_uniform)
			bindFramebufferTexture(ctx.pipeline, "hdr", 1, ctx.depth_buffer_uniform)

			setUniform(ctx.pipeline, ctx.hdr_exposure_uniform, {{hdr_exposure, 0, 0, 0}})
			setUniform(ctx.pipeline, ctx.dof_focal_distance_uniform, {{dof_focal_distance, 0, 0, 0}})
			setUniform(ctx.pipeline, ctx.dof_focal_range_uniform, {{dof_focal_range, 0, 0, 0}})
			
			drawQuad(ctx.pipeline, -1, 1, 2, -2, ctx.hdr_material)

	else
		newView(ctx.pipeline, "hdr")
			setPass(ctx.pipeline, "HDR")
			setFramebuffer(ctx.pipeline, "default")
			disableBlending(ctx.pipeline)
			applyCamera(ctx.pipeline, camera_slot)
			disableDepthWrite(ctx.pipeline)
			clear(ctx.pipeline, CLEAR_COLOR | CLEAR_DEPTH, 0x00000000)
			bindFramebufferTexture(ctx.pipeline, "hdr", 0, ctx.hdr_buffer_uniform)
			bindFramebufferTexture(ctx.pipeline, ctx.current_lum1, 0, ctx.avg_luminance_uniform)

			setUniform(ctx.pipeline, ctx.hdr_exposure_uniform, {{hdr_exposure, 0, 0, 0}})
			
			drawQuad(ctx.pipeline, -1, 1, 2, -2, ctx.hdr_material)
	end
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