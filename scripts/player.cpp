#include "universe\universe.h"
#include "core/matrix.h"
#include <cmath>
#include "core/vec3.h"
#include "script/script_visitor.h"
#include "animation/animation_system.h"
#include "core/crc32.h"
#include <cstdio>
#include "graphics/renderer.h"
#include "universe/universe.h"
#include "physics/physics_scene.h"
#include "script/script_system.h"
#include "engine/engine.h"
#include "engine/plugin_manager.h"
#include "core/input_system.h"

#define DLL_EXPORT  extern "C" __declspec(dllexport)
#define UPDATE DLL_EXPORT void update(float time_delta)
#define INIT DLL_EXPORT void init(ScriptScene* scene) 
#define DONE DLL_EXPORT void done() 

using namespace Lumix;

Entity g_e;
ScriptScene* g_scene;


INIT
{
	auto u = scene->getEngine().getUniverse();
	g_e = Entity(u, 5);
	auto render_scene = (RenderScene*)scene->getEngine().getScene(crc32("renderer"));
	auto physics_scene = (PhysicsScene*)scene->getEngine().getScene(crc32("physics"));
	for (int i = 0; i < 10; ++i)
	{
		for (int j = 0; j < 10; ++j)
		{
			auto e = u->createEntity();
			e.setPosition(30 + i * 4, j * 4, 30);
			auto cmp = render_scene->createComponent(crc32("renderable"), e);
			render_scene->setRenderablePath(cmp, string("models/utils/cube/cube.msh", scene->getEngine().getAllocator()));
			cmp = physics_scene->createComponent(crc32("box_rigid_actor"), e);
			physics_scene->setIsDynamic(cmp, true);
			physics_scene->setHalfExtents(cmp, Vec3(0.5f, 0.5f, 0.5f));
		}
	}
}

UPDATE
{
	static float f;
	f += time_delta;
	//if (g_scene->getEngine().getInputSystem().getActionValue(crc32("")) > 0)
	{
		g_e.setPosition(50 + cos(f) * 10, g_e.getPosition().y, 30 + sin(f) * 10);
	}
}

DONE
{
	
}
