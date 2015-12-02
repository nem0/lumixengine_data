-- LUMIX PROPERTY VOLUME float

function onContact(entity)
	local s = API_playSound(g_scene_audio, this, "hit_sound", false)
	API_setSoundVolume(g_scene_audio, s, VOLUME)
end