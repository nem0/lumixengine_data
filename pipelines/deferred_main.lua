framebuffers = {
	{
		name = "default",
		width = 1024,
		height = 1024,
		renderbuffers = {
			{format="rgba8"},
			{format = "depth32"}
		}
	},

	{
		name = "g_buffer",
		width = 1024,
		height = 1024,
		screen_size = true,
		renderbuffers = {
			{format="rgba8"},
			{format="rgba8"},
			{format="rgba8"},
			{format = "depth32"}
		}
	},
	
	{
		name = "shadowmap",
		width = 2048,
		height = 2048,
		renderbuffers = {
			{format="r32f"},
			{format = "depth32"}
		}
	}
}


parameters = {
	debug_gbuffer0 = false,
	debug_gbuffer1 = false,
	debug_gbuffer2 = false
}


function init(pipeline)
	texture_uniform = createUniform(pipeline, "u_texture")
	gbuffer0_uniform = createUniform(pipeline, "u_gbuffer0")
	gbuffer1_uniform = createUniform(pipeline, "u_gbuffer1")
	gbuffer2_uniform = createUniform(pipeline, "u_gbuffer2")
	deferred_material = loadMaterial(pipeline, "models/deferred.mat")
	screen_space_material = loadMaterial(pipeline, "models/editor/screen_space.mat")
end



function shadowmap(pipeline)
	setPass(pipeline, "SHADOW")         
	applyCamera(pipeline, "editor")
	setFramebuffer(pipeline, "shadowmap")
	renderShadowmap(pipeline, 1, "editor") 
end


function deferred(pipeline)
	setPass(pipeline, "DEFERRED")
		setFramebuffer(pipeline, "g_buffer")
		applyCamera(pipeline, "editor")
		clear(pipeline, "all", 0xffffFFFF)
		renderModels(pipeline, 1, false)


	setPass(pipeline, "MAIN")
		setFramebuffer(pipeline, "default")
		clear(pipeline, "all", 0xbbd3edff)
		bindFramebufferTexture(pipeline, "g_buffer", 0, gbuffer0_uniform)
		bindFramebufferTexture(pipeline, "g_buffer", 1, gbuffer1_uniform)
		bindFramebufferTexture(pipeline, "g_buffer", 2, gbuffer2_uniform)
		drawQuad(pipeline, -1, -1, 2, 2, deferred_material);
end

function editor(pipeline)
	setPass(pipeline, "EDITOR")
		setFramebuffer(pipeline, "default")
		enableDepthWrite(pipeline)
		disableBlending(pipeline)
		clear(pipeline, "depth", 0)
		applyCamera(pipeline, "editor")
		renderGizmos(pipeline)
end

function debugDeferred(pipeline)
	setPass(pipeline, "SCREEN_SPACE")
	local x = 0.5
	if parameters.debug_gbuffer0 then
			setFramebuffer(pipeline, "default")
			bindFramebufferTexture(pipeline, "g_buffer", 0, texture_uniform)
			drawQuad(pipeline, x, 1.0, 0.5, -0.5, screen_space_material);
			x = x - 0.51
	end
	if parameters.debug_gbuffer1 then
		beginNewView(pipeline, "debug_gbuffer1")
			setFramebuffer(pipeline, "default")
			bindFramebufferTexture(pipeline, "g_buffer", 1, texture_uniform)
			drawQuad(pipeline, x, 1.0, 0.5, -0.5, screen_space_material);
			x = x - 0.51
	end
	if parameters.debug_gbuffer2 then
		beginNewView(pipeline, "debug_gbuffer2")
			setFramebuffer(pipeline, "default")
			bindFramebufferTexture(pipeline, "g_buffer", 2, texture_uniform)
			drawQuad(pipeline, x, 1.0, 0.5, -0.5, screen_space_material);
			x = x - 0.51
	end
end


function render(pipeline)
	shadowmap(pipeline)
	deferred(pipeline)
	
	editor(pipeline)
	debugDeferred(pipeline)
end
