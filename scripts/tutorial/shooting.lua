local prefab = -1
local particles = {}

muzzle = -1
Editor.setPropertyType("muzzle", Editor.ENTITY_PROPERTY)

function init()
    prefab = Engine.loadResource(g_engine, "prefabs/tutorial/particle.fab", "prefab") -- clean up in onDestroy
end

local actions = {
	shoot = false
}

function onInputEvent(event)
	if event.type == Engine.INPUT_EVENT_BUTTON then
		if event.device.type == Engine.INPUT_DEVICE_MOUSE then
			actions.shoot = true
		end
	end
end


function update(time_delta)
    -- if left mouse button is pressed
    if actions.shoot then
		actions.shoot = false
		local muzzle_pos = Engine.getEntityPosition(g_universe, muzzle)
        local muzzle_rot = Engine.getEntityRotation(g_universe, muzzle)
        local muzzle_dir = Engine.multVecQuat({0, 0, 1}, muzzle_rot)

        -- raycast to detect what was hit
        is_hit, hit_entity, hit_position = Physics.raycast(g_scene_physics, muzzle_pos, muzzle_dir)
        if is_hit then
            -- spawn particle
            local instance = Engine.instantiatePrefab(g_engine, g_universe, hit_position, prefab)
            -- remember particles so we can destroy them later
            local particle = { entity = instance, life = 1 }
            table.insert(particles, particle)
        
            -- if a creature is hit
            local env = LuaScript.getEnvironment(g_scene_lua_script, hit_entity, 0)
            if env ~= nil and env.kill ~= nil then
				env.kill()
            end
        end
    end

    -- find particle which is too old
    local to_remove = -1
    for idx, particle in ipairs(particles) do
        particle.life = particle.life - time_delta
        if particle.life < 0 then
            to_remove = idx
        end
    end

    -- remove the old particle
    if to_remove > 0 then
        Engine.destroyEntity(g_universe, particles[to_remove].entity)
        table.remove(particles, to_remove)
    end
end