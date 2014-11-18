#include "script\base_script.h"
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

#define DLL_EXPORT  __declspec(dllexport)
#include <Windows.h>


class MyScript : public Lumix::BaseScript
{

	public:
		virtual void create(Lumix::ScriptScene& ctx, Lumix::Entity entity) override
		{
			m_scene = &ctx;
			m_e = entity;
			Lumix::IPlugin* physics = ctx.getEngine().getPluginManager().getPlugin("physics");
			m_phy_scene = static_cast<Lumix::PhysicsScene*>(ctx.getEngine().getScene(crc32("physics")));
			m_phy_controller = m_phy_scene->getController(entity);
			ctx.getEngine().getInputSystem().addAction(crc32("left-right"), Lumix::InputSystem::MOUSE_X, 0);
			ctx.getEngine().getInputSystem().addAction(crc32("forward"), Lumix::InputSystem::PRESSED, VK_UP);
			ctx.getEngine().getInputSystem().addAction(crc32("back"), Lumix::InputSystem::PRESSED, VK_DOWN);
			ctx.getEngine().getInputSystem().addAction(crc32("sprint"), Lumix::InputSystem::PRESSED, VK_SHIFT);
		}
		
		virtual void update(float dt) override
		{
			Lumix::Vec3 forward = m_e.getMatrix().getZVector();
			float speed = 1;
			if (m_scene->getEngine().getInputSystem().getActionValue(crc32("sprint")) > 0)
				speed = 10;
			if (m_scene->getEngine().getInputSystem().getActionValue(crc32("forward")) > 0)
				m_phy_scene->moveController(m_phy_controller, forward * -dt * speed, dt);
			if (m_scene->getEngine().getInputSystem().getActionValue(crc32("back")) > 0)
				m_phy_scene->moveController(m_phy_controller, forward * dt * speed, dt);
			Lumix::Quat q = m_e.getRotation();
			q = q * Lumix::Quat(Lumix::Vec3(0, 1, 0), dt * -m_scene->getEngine().getInputSystem().getActionValue(crc32("left-right")));
			m_e.setRotation(q);
		}

		virtual void visit(Lumix::ScriptVisitor& visitor) override
		{
		}
		
		Lumix::Entity m_e;
		Lumix::Component m_phy_controller;
		Lumix::PhysicsScene* m_phy_scene;
		Lumix::ScriptScene* m_scene;
};

extern "C" DLL_EXPORT Lumix::BaseScript* createScript()
{
	return new MyScript();
}

extern "C" DLL_EXPORT void destroyScript(Lumix::BaseScript* scr)
{
	delete scr;
}