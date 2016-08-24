local MIXER_TYPE = Engine.getComponentType("animation_mixer")
t = 0


function createState(anim)
	local state = {}
	state.anim = anim
	state.time = 0
	state.out = {}
	state.enter = function (state)
		state.time = 0
	end
	state.update = function (time_delta, state)
		state.time = state.time + time_delta * 30
		for _, out in ipairs(state.out) do
			if out.canGo(out) then return out end
		end
		return state
	end
	state.mix = function(mixer, state, slot, weight)
		Animation.mixAnimation(g_scene_animation, mixer, state.anim, slot, state.time, weight)
		return slot + 1
	end
	return state
end

function createTransition(from, to, length)
	local trans = {}
	trans.length = length
	trans.from = from
	table.insert(trans.from.out, trans)
	trans.to = to
	trans.time = 0
	trans.canGo = function (trans)
		return trans.from.time > 30
	end
	trans.enter = function (trans)
		trans.time = 0
	end
	trans.update = function (time_delta, trans)
		trans.time = trans.time + time_delta
		trans.from.update(time_delta, trans.from)
		trans.to.update(time_delta, trans.to)
		if trans.time > trans.length then return trans.to end
		return trans
	end
	trans.mix = function(mixer, trans, slot, weight)
		local w1 = weight * (trans.time / trans.length) 
		local w0 = weight - w1
		local next_slot = trans.from.mix(mixer, trans.from, slot, w0)
		return trans.to.mix(mixer, trans.to, next_slot, w1)
	end
	return trans
end

function createSimpleState(path)
	local anim = Engine.loadResource(g_engine, path, "animation")
	return createState(anim)
end

local state0 = createSimpleState("models/creatures/deer/run.ani")
local state1 = createSimpleState("models/creatures/deer/deer1Armature_Eat_001.ani")
local state2 = createSimpleState("models/creatures/deer/deer1Armature_LookAround_000.ani")
local transition0 = createTransition(state0, state1, 1.0)
local transition1 = createTransition(state1, state2, 1.0)
local transition2 = createTransition(state2, state0, 1.0)
local current = state0

state0.name = "state0"
state1.name = "state1"
state2.name = "state2"
transition0.name = "trans0"
transition1.name = "trans1"
transition1.name = "trans2"


function onGUI()
	ImGui.Text(tostring(current.name))
	if ImGui.Button("on") then
		transition1.canGo = function(trans) return true end 
	end
	if ImGui.Button("off") then
		transition1.canGo = function(trans) return false end 
	end
end


function update(time_delta)
	local mixer = Engine.getComponent(g_universe, this, MIXER_TYPE)
	if mixer < 0 then return end

	local old = current
	current = current.update(time_delta, current)
	if old ~= current then current.enter(current) end
	slot = current.mix(mixer, current, 0, 1.0)
	Animation.mixAnimation(g_scene_animation, mixer, -1, slot, 0, 0)
end