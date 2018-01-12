_postprocess_slot = "pre_transparent"
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
		newView(pipeline, "ssao_debug", "hdr")
			setPass(pipeline, "MAIN")
			disableBlending(pipeline)
			disableDepthWrite(pipeline)
			bindFramebufferTexture(pipeline, "SSAO", 0, env.texture_uniform)
			if SSAO_debug_fullscreen then
				drawQuad(pipeline, 0, 0, 1, 1, env.screen_space_material)
			else
				drawQuad(pipeline, 0.48, 0.48, 0.5, 0.5, env.screen_space_material)
			end
	end
end


local pipeline_env = nil

function initPostprocess(pipeline, env)
	pipeline_env = env
	env.ssao_material = Engine.loadResource(g_engine, "pipelines/ssao/ssao.mat", "material")
	env.normal_buffer_uniform = createUniform(pipeline, "u_normal_buffer")
	env.ssao_intensity_uniform = createVec4ArrayUniform(pipeline, "u_intensity", 1);
	env.ssao_radius_uniform = createVec4ArrayUniform(pipeline, "u_radius", 1)
	
	addFramebuffer(pipeline,  "SSAO", {
		width = 512,
		height = 512,
		size_ratio = {1, 1},
		renderbuffers = {
			{format="rgba8"}
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
		removeFramebuffer(pipeline_env.pipeline, "SSAO")
		removeFramebuffer(pipeline_env.pipeline, "blur_rgba8")
	end
end


function postprocess(pipeline, env)
	if not enabled then return end
	
	newView(pipeline, "ssao", "SSAO")
		setPass(pipeline, "MAIN")
		disableBlending(pipeline)
		disableDepthWrite(pipeline)
		bindFramebufferTexture(pipeline, "g_buffer", 1, env.normal_buffer_uniform)
		bindFramebufferTexture(pipeline, "g_buffer", 3, env.texture_uniform)
		setUniform(pipeline, env.ssao_radius_uniform, {{radius, 0, 0, 0}})
		setUniform(pipeline, env.ssao_intensity_uniform, {{intensity, 0, 0, 0}})
		drawQuad(pipeline, 0, 0, 1, 1, env.ssao_material)

	if blur_enabled then
		newView(pipeline, "ssao_blur_h", "blur_rgba8")
			setPass(pipeline, "BLUR_H")
			disableDepthWrite(pipeline)
			bindFramebufferTexture(pipeline, "SSAO", 0, env.texture_uniform)
			drawQuad(pipeline, 0, 0, 1, 1, env.blur_material)
			enableDepthWrite(pipeline)
		
		newView(pipeline, "ssao_blur_v", "SSAO")
			setPass(pipeline, "BLUR_V")
			disableDepthWrite(pipeline)
			bindFramebufferTexture(pipeline, "blur_rgba8", 0, env.texture_uniform)
			drawQuad(pipeline, 0, 0, 1, 1, env.blur_material)
			enableDepthWrite(pipeline)		
			
		newView(pipeline, "ssao_postprocess", "hdr")
			setPass(pipeline, "MAIN")
			enableBlending(pipeline, "multiply")
			disableDepthWrite(pipeline)
			bindFramebufferTexture(pipeline, "SSAO", 0, env.texture_uniform)
			drawQuad(pipeline, 0, 0, 1, 1, env.screen_space_material)
	end
	
	renderSSAODDebug(pipeline, env)
end