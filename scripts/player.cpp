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

#define DLL_EXPORT  __declspec(dllexport)
#include <Windows.h>


class MyScript : public Lumix::BaseScript
{
	public:
		virtual void create(Lumix::ScriptScene& ctx, Lumix::Entity entity) override
		{
			m_e = entity;
			m_phy_controller = entity.getComponent(crc32("physical_controller"));
			m_phy_scene = static_cast<Lumix::PhysicsScene*>(m_phy_controller.scene);
		}
		
		virtual void update(float dt) override
		{
			Lumix::Vec3 forward = m_e.getMatrix().getZVector();
			float speed = 1;
			if (GetAsyncKeyState(VK_SHIFT) >> 8)
				speed = 10;
			if (GetAsyncKeyState(VK_UP) >> 8)
				m_phy_scene->moveController(m_phy_controller, forward * -0.01f * speed, dt);
			if (GetAsyncKeyState(VK_DOWN) >> 8)
				m_phy_scene->moveController(m_phy_controller, forward * 0.01f * speed, dt);
			Lumix::Quat q = m_e.getRotation();
			if (GetAsyncKeyState(VK_LEFT) >> 8)
			{
				q = q * Lumix::Quat(Lumix::Vec3(0, 1, 0), dt * 1.0f);
				m_e.setRotation(q);
			}
			else if (GetAsyncKeyState(VK_RIGHT) >> 8)
			{
				q = q * Lumix::Quat(Lumix::Vec3(0, 1, 0), dt * -1.0f);
				m_e.setRotation(q);
			}
		}

		virtual void visit(Lumix::ScriptVisitor& visitor) override
		{
		}
		
		Lumix::Entity m_e;
		Lumix::Component m_phy_controller;
		Lumix::PhysicsScene* m_phy_scene;
};

extern "C" DLL_EXPORT Lumix::BaseScript* createScript()
{
	return new MyScript();
}

extern "C" DLL_EXPORT void destroyScript(Lumix::BaseScript* scr)
{
	delete scr;
}