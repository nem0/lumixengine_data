function render()
	newView(this, "imgui", "default")
		setPass(this, "MAIN")
		clear(this, CLEAR_COLOR | CLEAR_DEPTH, 0x303030ff)
		setViewSeq(this)
end
