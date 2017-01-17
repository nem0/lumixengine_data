addFramebuffer(this, "default", {
	width = 512,
	height = 512,
	renderbuffers = {
		{ format = "rgba8" },
		{ format = "depth24" }
	}
})

local DEFAULT_RENDER_MASK = 1
function render()
	main_view = newView(this, "MAIN", DEFAULT_RENDER_MASK)
		setPass(this, "MAIN")
		enableDepthWrite(this)
		enableRGBWrite(this)
		clear(this, CLEAR_COLOR | CLEAR_DEPTH, 0xff00ff00)
		setFramebuffer(this, "default")
		applyCamera(this, "main")
		setActiveGlobalLightUniforms(this)
		renderModels(this, DEFAULT_RENDER_MASK)
end

