framebuffers = {
	{
		name = "shadowmap",
		width = 2048,
		height = 2048,
		renderbuffers = {
			{format = "depth32"}
		}
	}
}

function init(pipeline)
	shadowmap_uniform = createUniform(pipeline, "u_texShadowmap")
end

function render(pipeline)
	if not cameraExists(pipeline, "main") then
		setPass(pipeline, "MAIN")
			setFramebuffer(pipeline, "default")
			clear(pipeline, "all")
		return
	end

	setPass(pipeline, "SHADOW")         
		setFramebuffer(pipeline, "shadowmap")
		renderShadowmap(pipeline, 1, "main") 
		bindFramebufferTexture(pipeline, "shadowmap", 0, shadowmap_uniform)

	setPass(pipeline, "MAIN")
		setFramebuffer(pipeline, "default")
		clear(pipeline, "all")
		applyCamera(pipeline, "main")
		renderModels(pipeline, 1, false)
		--renderDebugLines(pipeline)

	setPass(pipeline, "POINT_LIGHT")
		enableBlending(pipeline)
		applyCamera(pipeline, "main")
		renderModels(pipeline, 1, true)
		disableBlending(pipeline)
	
	setPass(pipeline, "IMGUI")
	
end
