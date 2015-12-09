-- LUMIX PROPERTY VOLUME float

function onContact(entity)
	local s = Audio.playSound(g_scene_audio, this, "hit_sound", false)
	Audio.setSoundVolume(g_scene_audio, s, VOLUME)
end