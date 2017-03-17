_G["spawn_points"] = {} -- list of all spawn points
local to_spawn = 1 -- time to next spawn
local creatures = {} -- list of all spawned creatures
local prefab = nil
player = -1
Editor.setPropertyType("player", Editor.ENTITY_PROPERTY)
local to_despawn = {}

function init()
    prefab = Engine.loadResource(g_engine, "prefabs/tutorial/creature.fab", "prefab") -- TODO clean up in onDestroy
end

function getRandomSpawnPos()
    local t = _G["spawn_points"]
    local spawn_point = t[math.random(1, #t)]
    return Engine.getEntityPosition(g_universe, spawn_point)
end

function processDespawn(time_delta)
    for i,v in ipairs(to_despawn) do
        v.time = v.time - time_delta
        if v.time < 0 then
            Engine.destroyEntity(g_universe, v.entity)
            table.remove(to_despawn, i)
            break -- despawn max 1 per frame
        end
    end
end

function update(time_delta)
    processDespawn(time_delta)

    to_spawn = to_spawn - time_delta
    if to_spawn > 0 then return end

    to_spawn = 5 -- next spawn in 5 seconds

    if #creatures > 9 then return end -- spawn max 10 creatures

    local pos = getRandomSpawnPos()
    local instance = Engine.instantiatePrefab(g_engine, g_universe, pos, prefab)[1]

    local env = LuaScript.getEnvironment(g_scene_lua_script, instance, 0)
    env.followed_entity = player
    env.spawner = this

    table.insert(creatures, instance)
end

function despawn(entity)
    for i,v in ipairs(creatures) do
        if creatures[i] == entity then
            table.remove(creatures, i)
            table.insert(to_despawn, {entity = entity, time = 3.0})
            break
        end
    end
end

