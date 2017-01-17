enabled = true
local camera_cmp_type = Engine.getComponentType("camera")
exposure = 0.01
decay = 0.99
weight = 0.1

function initPostprocess(pipeline, env)
	env.ctx.godrays_material = Engine.loadResource(g_engine, "pipelines/godrays/godrays.mat", "material")
	env.ctx.godrays_params = createUniform(pipeline, "u_godrays_params")
end


function postprocess(pipeline, env)
	if not enabled then return end
	newView(pipeline, "godrays")
		local godrays_params = {exposure, decay, weight, 0}
		setActiveGlobalLightUniforms(pipeline)
		setUniform(pipeline, env.ctx.godrays_params, {godrays_params})
		setPass(pipeline, "MAIN")
		enableBlending(pipeline, "add")
		disableDepthWrite(pipeline)
		setFramebuffer(pipeline, env.ctx.main_framebuffer)
		bindFramebufferTexture(pipeline, "g_buffer", 3, env.ctx.texture_uniform)
		drawQuad(pipeline, 0, 0, 1, 1, env.ctx.godrays_material)
end