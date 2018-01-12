function render()
	newView(this, "imgui", "default")
		setPass(this, "MAIN")
		clear(this, CLEAR_COLOR | CLEAR_DEPTH, 0x303030ff)
		setViewMode(this, VIEW_MODE_SEQUENTIAL)
end
