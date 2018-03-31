lut_texture = -1
Editor.setPropertyType("lut_texture", Editor.RESOURCE_PROPERTY, "texture")

_postprocess_slot = "post_tonemapping"

dof_near_blur = 0
dof_near_sharp = 1
dof_far_sharp = 5
dof_far_blur = 15
dof_enabled = true

film_grain_enabled = true
grain_amount = 0.02
grain_size = 1.6
enabled = true
fxaa_enabled = true
vignette_radius = 0.5
vignette_softness = 0.35
vignette_enabled = true
bloom_enabled = false
bloom_cutoff = 1.0


local pipeline_env = nil

local dof_near_debug = false
local dof_far_debug = false
local dof_debug_fullscreen = false
local bloom_debug = false
local bloom_debug_fullscreen = false
local bloom_blur = true

function initPostprocessBasic(pipeline, ctx)

	addFramebuffer(pipeline, "dof_far", {
		width = 1024,
		height = 1024,
		size_ratio = { 1, 1},
		renderbuffers = {
			{ format = "rgba8" },
		}
	})

	addFramebuffer(pipeline, "dof_near", {
		width = 1024,
		height = 1024,
		size_ratio = { 1, 1},
		renderbuffers = {
			{ format = "rgba8" },
		}
	})

	addFramebuffer(pipeline,  "dof_blur", {
		width = 1024,
		height = 1024,
		size_ratio = { 1,1},
		renderbuffers = {
			{ format = "rgba8" },
		}
	})

	addFramebuffer(pipeline, "postprocess_result", {
		width = 1024,
		height = 1024,
		size_ratio = {1, 1},
		renderbuffers = {
			{ format = "rgba8" },
		}
	})
	
	ctx.bloom_cutoff = createVec4ArrayUniform(pipeline, "u_bloomCutoff", 1)
	ctx.grain_amount_uniform = createVec4ArrayUniform(pipeline, "u_grainAmount", 1)
	ctx.lut_texture_uniform = createUniform(pipeline, "u_colorGradingLUT")
	ctx.grain_size_uniform = createVec4ArrayUniform(pipeline, "u_grainSize", 1)
	ctx.downsample_material = Engine.loadResource(g_engine, "pipelines/common/downsample.mat", "material")
	ctx.ppbasic_material = Engine.loadResource(g_engine, "pipelines/postprocess_basic/ppbasic.mat", "material")
	ctx.fxaa_material = Engine.loadResource(g_engine, "pipelines/postprocess_basic/fxaa.mat", "material")
	ctx.hdr_buffer_uniform = createUniform(pipeline, "u_hdrBuffer")
	ctx.fxaa_buffer_uniform = createUniform(pipeline, "u_fxaaBuffer")

	ctx.depth_buffer_uniform = createUniform(pipeline, "u_depthBuffer")
	ctx.dof_buffer_uniform = createUniform(pipeline, "u_dofBuffer")
	ctx.coc_uniform = createUniform(pipeline, "u_cocBuffer")
	ctx.dof_params_uniform = createVec4ArrayUniform(pipeline, "u_dofParams", 1)

	ctx.vignette_uniform = createVec4ArrayUniform(pipeline, "u_vignette", 1)
	ctx.dof_blur_material = Engine.loadResource(g_engine, "pipelines/postprocess_basic/dofblur.mat", "material")
end

function postprocessBasic(pipeline, ctx, camera_slot)
	bloom(ctx, pipeline)
		
	setMaterialDefine(pipeline, ctx.ppbasic_material, "COLOR_GRADING", lut_texture ~= -1)
	setMaterialDefine(pipeline, ctx.ppbasic_material, "FILM_GRAIN", film_grain_enabled)
	setMaterialDefine(pipeline, ctx.ppbasic_material, "DOF", dof_enabled)
	setMaterialDefine(pipeline, ctx.ppbasic_material, "VIGNETTE", vignette_enabled)
	if dof_enabled then
		newView(pipeline, "blur_dof_near_h", "dof_blur")
			setPass(pipeline, "BLUR_H")
			disableDepthWrite(pipeline)
			bindFramebufferTexture(pipeline, "linear", 0, ctx.texture_uniform, TEXTURE_MAG_ANISOTROPIC | TEXTURE_MIN_ANISOTROPIC)
			bindFramebufferTexture(pipeline, "hdr", 1, ctx.depth_buffer_uniform, TEXTURE_MAG_ANISOTROPIC | TEXTURE_MIN_ANISOTROPIC)
			setMaterialDefine(pipeline, ctx.dof_blur_material, "NEAR", true)
			drawQuad(pipeline, 0, 0, 1, 1, ctx.dof_blur_material)
			setUniform(pipeline, ctx.dof_params_uniform, {{dof_near_blur, dof_near_sharp, dof_far_sharp, dof_far_blur}})
			enableDepthWrite(pipeline)

		newView(pipeline, "blur_dof_near_v", "dof_near")
			setPass(pipeline, "BLUR_V")
			disableDepthWrite(pipeline)
			bindFramebufferTexture(pipeline, "dof_blur", 0, ctx.texture_uniform, TEXTURE_MAG_ANISOTROPIC | TEXTURE_MIN_ANISOTROPIC)
			bindFramebufferTexture(pipeline, "hdr", 1, ctx.depth_buffer_uniform, TEXTURE_MAG_ANISOTROPIC | TEXTURE_MIN_ANISOTROPIC)
			setUniform(pipeline, ctx.dof_params_uniform, {{dof_near_blur, dof_near_sharp, dof_far_sharp, dof_far_blur}})
			setMaterialDefine(pipeline, ctx.dof_blur_material, "NEAR", true)
			drawQuad(pipeline, 0, 0, 1, 1, ctx.dof_blur_material);
			enableDepthWrite(pipeline)

		newView(pipeline, "blur_dof_far_h", "dof_blur")
			setPass(pipeline, "BLUR_H")
			disableDepthWrite(pipeline)
			bindFramebufferTexture(pipeline, "linear", 0, ctx.texture_uniform, TEXTURE_MAG_ANISOTROPIC | TEXTURE_MIN_ANISOTROPIC)
			bindFramebufferTexture(pipeline, "hdr", 1, ctx.depth_buffer_uniform, TEXTURE_MAG_ANISOTROPIC | TEXTURE_MIN_ANISOTROPIC)
			setMaterialDefine(pipeline, ctx.dof_blur_material, "NEAR", false)
			drawQuad(pipeline, 0, 0, 1, 1, ctx.dof_blur_material)
			setUniform(pipeline, ctx.dof_params_uniform, {{dof_near_blur, dof_near_sharp, dof_far_sharp, dof_far_blur}})
			enableDepthWrite(pipeline)

		newView(pipeline, "blur_dof_far_v", "dof_far")
			setPass(pipeline, "BLUR_V")
			disableDepthWrite(pipeline)
			bindFramebufferTexture(pipeline, "dof_blur", 0, ctx.texture_uniform, TEXTURE_MAG_ANISOTROPIC | TEXTURE_MIN_ANISOTROPIC)
			bindFramebufferTexture(pipeline, "hdr", 1, ctx.depth_buffer_uniform, TEXTURE_MAG_ANISOTROPIC | TEXTURE_MIN_ANISOTROPIC)
			setUniform(pipeline, ctx.dof_params_uniform, {{dof_near_blur, dof_near_sharp, dof_far_sharp, dof_far_blur}})
			setMaterialDefine(pipeline, ctx.dof_blur_material, "NEAR", false)
			drawQuad(pipeline, 0, 0, 1, 1, ctx.dof_blur_material);
			enableDepthWrite(pipeline)

		newView(pipeline, "dof_merge_near", "linear")
			setPass(pipeline, "MAIN")
			enableBlending(pipeline, "alpha")
			disableDepthWrite(pipeline)
			bindFramebufferTexture(pipeline, "dof_near", 0, ctx.texture_uniform, TEXTURE_MAG_ANISOTROPIC | TEXTURE_MIN_ANISOTROPIC)
			drawQuad(pipeline, 0, 0, 1, 1, ctx.screen_space_material)
			enableDepthWrite(pipeline)
			
		newView(pipeline, "dof_merge_far", "linear")
			setPass(pipeline, "MAIN")
			enableBlending(pipeline, "alpha")
			disableDepthWrite(pipeline)
			bindFramebufferTexture(pipeline, "dof_far", 0, ctx.texture_uniform, TEXTURE_MAG_ANISOTROPIC | TEXTURE_MIN_ANISOTROPIC)
			drawQuad(pipeline, 0, 0, 1, 1, ctx.screen_space_material)
			enableDepthWrite(pipeline)

		newView(pipeline, "ppbasic", "postprocess_result")
			setPass(pipeline, "MAIN")
			disableBlending(pipeline)
			applyCamera(pipeline, camera_slot)
			disableDepthWrite(pipeline)
			clear(pipeline, CLEAR_COLOR | CLEAR_DEPTH, 0x00000000)

			bindFramebufferTexture(pipeline, "linear", 0, ctx.texture_uniform)
	else
		newView(pipeline, "ppbasic", "postprocess_result")
			setPass(pipeline, "MAIN")
			disableBlending(pipeline)
			applyCamera(pipeline, camera_slot)
			disableDepthWrite(pipeline)
			clear(pipeline, CLEAR_COLOR | CLEAR_DEPTH, 0x00000000)
			bindFramebufferTexture(pipeline, "linear", 0, ctx.hdr_buffer_uniform)

	end
	if vignette_enabled then 
		setUniform(pipeline, ctx.vignette_uniform, {{vignette_radius, vignette_softness, 0, 0}})
	end
	if film_grain_enabled then
		setUniform(pipeline, ctx.grain_amount_uniform, {{grain_amount, 0, 0, 0}})
		setUniform(pipeline, ctx.grain_size_uniform, {{grain_size, 0, 0, 0}})
	end
	if lut_texture ~= -1 then
		bindTexture(pipeline, ctx.lut_texture_uniform, lut_texture)
	end
	drawQuad(pipeline, 0, 0, 1, 1, ctx.ppbasic_material)

	if fxaa_enabled then
		fxaa(pipeline, ctx, camera_slot)
	else
		newView(pipeline, "ppbasic_final_copy", "linear")
			copyRenderbuffer(pipeline, "postprocess_result", 0, "linear", 0)
	end
	
	renderDOFDebug(ctx, pipeline)
end


function initBloom(pipeline, env)
	env.extract_material = Engine.loadResource(g_engine, "pipelines/postprocess_basic/bloomextract.mat", "material")
	env.loom_material = Engine.loadResource(g_engine, "pipelines/postprocess_basic/bloom.mat", "material")
	addFramebuffer(pipeline, "bloom_extract", {
		size_ratio = { 1, 1},
		renderbuffers = {
			{ format = "rgba16f" }
		}
	})

	addFramebuffer(pipeline, "bloom_blur2", {
		size_ratio = { 0.5, 0.5 },
		renderbuffers = {
			{ format = "rgba16f" }
		}
	})
	addFramebuffer(pipeline, "bloom_blur4", {
		size_ratio = { 0.25, 0.25 },
		renderbuffers = {
			{ format = "rgba16f" }
		}
	})
	addFramebuffer(pipeline, "bloom_blur8", {
		size_ratio = { 0.125, 0.125 },
		renderbuffers = {
			{ format = "rgba16f" }
		}
	})
end


function bloom(ctx, pipeline)
	if not bloom_enabled then return end
	
	newView(pipeline, "bloom_extract", "bloom_extract")
		setPass(pipeline, "MAIN")
		disableBlending(pipeline)
		disableDepthWrite(pipeline)
		setUniform(pipeline, ctx.bloom_cutoff, {{bloom_cutoff, 0, 0, 0}})
		bindFramebufferTexture(pipeline, "hdr", 0, ctx.texture_uniform)
		drawQuad(pipeline, 0, 0, 1, 1, ctx.extract_material)
	
	if bloom_blur then
		newView(pipeline, "blur_bloom2_downsample", "bloom_blur2")
			setPass(pipeline, "MAIN")
			disableDepthWrite(pipeline)
			bindFramebufferTexture(pipeline, "bloom_extract", 0, ctx.shadowmap_uniform)
			drawQuad(pipeline, 0, 0, 1, 1, ctx.downsample_material)
			enableDepthWrite(pipeline)

		newView(pipeline, "blur_bloom2_h", "bloom_extract")
			setPass(pipeline, "BLUR_H")
			disableDepthWrite(pipeline)
			bindFramebufferTexture(pipeline, "bloom_blur2", 0, ctx.shadowmap_uniform)
			drawQuad(pipeline, 0, 0, 0.5, 0.5, ctx.blur_material)
			enableDepthWrite(pipeline)

		newView(pipeline, "blur_bloom2_v", "linear")
			setPass(pipeline, "BLUR_V")
			enableBlending(pipeline, "add")
			disableDepthWrite(pipeline)
			bindFramebufferTexture(pipeline, "bloom_extract", 0, ctx.shadowmap_uniform)
			drawQuadEx(pipeline, 0, 0, 1, 1, 0, 0.5, 0.5, 0, ctx.blur_material);
			enableDepthWrite(pipeline)
			
		newView(pipeline, "blur_bloom4_downsample", "bloom_blur4")
			setPass(pipeline, "MAIN")
			disableDepthWrite(pipeline)
			bindFramebufferTexture(pipeline, "bloom_blur2", 0, ctx.shadowmap_uniform)
			drawQuad(pipeline, 0, 0, 1, 1, ctx.downsample_material)
			enableDepthWrite(pipeline)
			
		newView(pipeline, "blur_bloom4_h", "bloom_extract")
			setPass(pipeline, "BLUR_H")
			disableDepthWrite(pipeline)
			bindFramebufferTexture(pipeline, "bloom_blur4", 0, ctx.shadowmap_uniform)
			drawQuad(pipeline, 0, 0, 0.25, 0.25, ctx.blur_material)
			enableDepthWrite(pipeline)

		newView(pipeline, "blur_bloom4_v", "linear")
			setPass(pipeline, "BLUR_V")
			enableBlending(pipeline, "add")
			disableDepthWrite(pipeline)
			bindFramebufferTexture(pipeline, "bloom_extract", 0, ctx.shadowmap_uniform, TEXTURE_MAG_ANISOTROPIC | TEXTURE_MIN_ANISOTROPIC)
			drawQuadEx(pipeline, 0, 0, 1, 1, 0, 0, 0.25, 0.25, ctx.blur_material);
			enableDepthWrite(pipeline)

	end
			
	renderBloomDebug(ctx, pipeline)
end

function fxaa(pipeline, ctx, camera_slot)
	if not fxaa_enabled then return end
	
	newView(pipeline, "fxaa", "linear")
		setPass(pipeline, "MAIN")
		disableBlending(pipeline)
		applyCamera(pipeline, camera_slot)
		disableDepthWrite(pipeline)
		clear(pipeline, CLEAR_DEPTH, 0x00000000)
		bindFramebufferTexture(pipeline, "postprocess_result", 0, ctx.fxaa_buffer_uniform, TEXTURE_MAG_ANISOTROPIC | TEXTURE_MIN_ANISOTROPIC)
		drawQuad(pipeline, 0, 0, 1, 1, ctx.fxaa_material)
end

function onDestroy()
	if pipeline_env then
		removeFramebuffer(pipeline_env.pipeline, "postprocess_result")
		removeFramebuffer(pipeline_env.pipeline, "dof_near")
		removeFramebuffer(pipeline_env.pipeline, "dof_far")
		removeFramebuffer(pipeline_env.pipeline, "dof_blur")
		removeFramebuffer(pipeline_env.pipeline, "bloom_extract")
		removeFramebuffer(pipeline_env.pipeline, "bloom_blur2")
		removeFramebuffer(pipeline_env.pipeline, "bloom_blur4")
		removeFramebuffer(pipeline_env.pipeline, "bloom_blur8")
	end
end

function initPostprocess(pipeline, env)
	pipeline_env = env
	env.pipeline = pipeline
	initBloom(pipeline, env)
	initPostprocessBasic(pipeline, env)
end

function renderBloomDebug(ctx, pipeline)
	if bloom_debug then
		newView(pipeline, "bloom_debug", "linear")
			setPass(pipeline, "MAIN")
			disableBlending(pipeline)
			disableDepthWrite(pipeline)
			bindFramebufferTexture(pipeline, "bloom_extract", 0, ctx.texture_uniform)
			if bloom_debug_fullscreen then
				drawQuad(pipeline, 0, 0, 1, 1, ctx.screen_space_material)
			else
				drawQuad(pipeline, 0.48, 0.48, 0.5, 0.5, ctx.screen_space_material)
			end
	end
end

function renderDOFDebug(ctx, pipeline)
	setMaterialDefine(pipeline, ctx.screen_space_debug_material, "ALPHA_TO_BLACK", true)
	if dof_near_debug then
		newView(pipeline, "dof_near_debug", "linear")
			setPass(pipeline, "MAIN")
			disableBlending(pipeline)
			disableDepthWrite(pipeline)
			bindFramebufferTexture(pipeline, "dof_near", 0, ctx.texture_uniform)
			if dof_debug_fullscreen then
				drawQuad(pipeline, 0, 0, 1, 1, ctx.screen_space_debug_material)
			else
				drawQuad(pipeline, 0.48, 0.48, 0.5, 0.5, ctx.screen_space_debug_material)
			end
	end
	if dof_far_debug then
		newView(pipeline, "dof_far_debug", "linear")
			setPass(pipeline, "MAIN")
			disableBlending(pipeline)
			disableDepthWrite(pipeline)
			bindFramebufferTexture(pipeline, "dof_far", 0, ctx.texture_uniform)
			if dof_debug_fullscreen then
				drawQuad(pipeline, 0, 0, 1, 1, ctx.screen_space_debug_material)
			else
				drawQuad(pipeline, 0.48, 0.48, 0.5, 0.5, ctx.screen_space_debug_material)
			end
	end
	setMaterialDefine(pipeline, ctx.screen_space_debug_material, "ALPHA_TO_BLACK", false)
end

function postprocess(pipeline, env)
	if enabled then
		slot = Renderer.getCameraSlot(g_scene_renderer, this)
		postprocessBasic(pipeline, env, slot)
	end
end


function onGUI()
	local changed
	changed, dof_far_debug = ImGui.Checkbox("DOF far debug", dof_far_debug)
	if dof_far_debug then
		ImGui.SameLine()
		changed, dof_debug_fullscreen = ImGui.Checkbox("Fullscreen", dof_debug_fullscreen)
	end
	changed, dof_near_debug = ImGui.Checkbox("DOF near debug", dof_near_debug)
	if dof_near_debug then
		ImGui.SameLine()
		changed, dof_debug_fullscreen = ImGui.Checkbox("Fullscreen", dof_debug_fullscreen)
	end
	changed, bloom_debug = ImGui.Checkbox("Bloom debug", bloom_debug)
	if bloom_debug then
		changed, bloom_blur = ImGui.Checkbox("Bloom blur", bloom_blur)
		ImGui.SameLine()
		changed, bloom_debug_fullscreen = ImGui.Checkbox("Fullscreen", bloom_debug_fullscreen)
	end
end
