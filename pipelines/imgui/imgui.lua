function render()
	newView(this, "imgui")
		setPass(this, "MAIN")
		setFramebuffer(this, "default")
		clear(this, CLEAR_COLOR | CLEAR_DEPTH, 0x303030ff)
		setViewSeq(this)
end
