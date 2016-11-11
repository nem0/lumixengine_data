Gui.enableCursor(Gui.instance, true)
Navigation.load(g_scene_navigation, "universes/navigation.nav")
speed = 5

function update()
	if Gui.isMouseClicked(Gui.instance, 0) then
		local x = Gui.getMouseX(Gui.instance)
		local y = Gui.getMouseY(Gui.instance)
		local is_hit, pos = Renderer.castCameraRay(g_scene_renderer, "main", x, y)
		if is_hit then
			Navigation.navigate(g_scene_navigation, this, pos, speed)
		end
	end
end