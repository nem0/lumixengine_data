addFramebuffer(this, "default", {
	width = 1024,
	height = 1024,
	renderbuffers = {
		{ format = "rgba8" },
		{ format = "depth24" }
	}
})

function render()
	main_view = newView(this, "MAIN")
		setPass(this, "MAIN")
		enableDepthWrite(this)
		enableRGBWrite(this)
		clear(this, CLEAR_COLOR | CLEAR_DEPTH, 0x00000000)
		setFramebuffer(this, "default")
		applyCamera(this, "main")
		setActiveGlobalLightUniforms(this)
		renderModels(this, {main_view})
end

