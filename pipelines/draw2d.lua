addFramebuffer(this, "default", {
	width = 1024,
	height = 1024,
	renderbuffers = {
		{ format = "rgba8" },
	}
})


function render()
	newView(this, "draw2d", "default")
		clear(this, CLEAR_ALL, 0x00000000)
		setPass(this, "MAIN")
		render2D(this)
end

