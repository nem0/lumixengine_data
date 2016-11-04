enabled = true
blur_enabled = true
radius = 0.03
intensity = 1
local SSAO_debug = false
local SSAO_debug_fullscreen = false

function onGUI()
	local changed
	changed, SSAO_debug = ImGui.Checkbox("Debug", SSAO_debug)
	if SSAO_debug then
		ImGui.SameLine()
		changed, SSAO_debug_fullscreen = ImGui.Checkbox("Fullscreen", SSAO_debug_fullscreen)
	end
end


function renderSSAODDebug(pipeline, env)
	if SSAO_debug then
		newView(pipeline, "ssao_debug")
			setPass(pipeline, "MAIN")
			disableBlending(pipeline)
			disableDepthWrite(pipeline)
			setFramebuffer(pipeline, env.ctx.main_framebuffer)
			bindFramebufferTexture(pipeline, "SSAO", 0, env.ctx.texture_uniform)
			if SSAO_debug_fullscreen then
				drawQuad(pipeline, 0, 0, 1, 1, env.ctx.screen_space_material)
			else
				drawQuad(pipeline, 0.48, 0.48, 0.5, 0.5, env.ctx.screen_space_material)
			end
	end
end


local pipeline_env = nil

function initPostprocess(pipeline, env)
	pipeline_env = env
	env.ctx.ssao_material = Engine.loadResource(g_engine, "pipelines/ssao/ssao.mat", "material")
	env.ctx.normal_buffer_uniform = createUniform(pipeline, "u_normal_buffer")
	env.ctx.ssao_intensity_uniform = createUniform(pipeline, "u_intensity");
	env.ctx.ssao_radius_uniform = createUniform(pipeline, "u_radius")
	
	addFramebuffer(pipeline,  "SSAO", {
		width = 512,
		height = 512,
		size_ratio = {1, 1},
		renderbuffers = {
			{format="rgba8"},
			{format = "depth24"}
		}
	})
		
	addFramebuffer(pipeline, "blur_rgba8", {
		width = 2048,
		height = 2048,
		size_ratio = {1, 1},
		renderbuffers = {
			{ format = "rgba8" }
		}
	})
end


function onDestroy()
	if pipeline_env then
		removeFramebuffer(pipeline_env.ctx.pipeline, "SSAO")
		removeFramebuffer(pipeline_env.ctx.pipeline, "blur_rgba8")
	end
end


function postprocess(pipeline, env)
	if not enabled then return end
	
	newView(pipeline, "ssao")
		setPass(pipeline, "MAIN")
		disableBlending(pipeline)
		disableDepthWrite(pipeline)
		setFramebuffer(pipeline, "SSAO")
		bindFramebufferTexture(pipeline, "g_buffer", 1, env.ctx.normal_buffer_uniform)
		bindFramebufferTexture(pipeline, env.ctx.main_framebuffer, 1, env.ctx.texture_uniform)
		setUniform(pipeline, env.ctx.ssao_radius_uniform, {{radius, 0, 0, 0}})
		setUniform(pipeline, env.ctx.ssao_intensity_uniform, {{intensity, 0, 0, 0}})
		drawQuad(pipeline, 0, 0, 1, 1, env.ctx.ssao_material)

	if blur_enabled then
		newView(pipeline, "ssao_blur_h")
			setPass(pipeline, "BLUR_H")
			setFramebuffer(pipeline, "blur_rgba8")
			disableDepthWrite(pipeline)
			bindFramebufferTexture(pipeline, "SSAO", 0, env.ctx.texture_uniform)
			drawQuad(pipeline, 0, 0, 1, 1, env.ctx.blur_material)
			enableDepthWrite(pipeline)
		
		newView(pipeline, "ssao_blur_v")
			setPass(pipeline, "BLUR_V")
			setFramebuffer(pipeline, "SSAO")
			disableDepthWrite(pipeline)
			bindFramebufferTexture(pipeline, "blur_rgba8", 0, env.ctx.texture_uniform)
			drawQuad(pipeline, 0, 0, 1, 1, env.ctx.blur_material)
			enableDepthWrite(pipeline)		
			
		newView(pipeline, "ssao_postprocess")
			setPass(pipeline, "MAIN")
			enableBlending(pipeline, "multiply")
			disableDepthWrite(pipeline)
			setFramebuffer(pipeline, env.ctx.main_framebuffer)
			bindFramebufferTexture(pipeline, "SSAO", 0, env.ctx.texture_uniform)
			drawQuad(pipeline, 0, 0, 1, 1, env.ctx.screen_space_material)
	end
	
	renderSSAODDebug(pipeline, env)
end