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

#define DLL_EXPORT  __declspec(dllexport)
#include <Windows.h>


class MyScript : public Lumix::BaseScript
{
	public:
		virtual void create(Lumix::ScriptSystem& ctx, Lumix::Entity entity) override
		{
			m_e = entity;
			/*Lumix::Component animable = m_e.getComponent(crc32("animable"));
			if(animable.isValid())
			{
				Lumix::AnimationSystem* sys = static_cast<Lumix::AnimationSystem*>(animable.system);
				sys->playAnimation(animable, "models/horse.ani");
			}*/
		}

		virtual void update(float dt) override
		{
			if(GetAsyncKeyState(VK_UP) >> 8)
				m_e.setPosition(m_e.getPosition() + Lumix::Vec3(0, 0, -10 * dt));
			if(GetAsyncKeyState(VK_DOWN) >> 8)
				m_e.setPosition(m_e.getPosition() + Lumix::Vec3(0, 0, 10 * dt));
			//Lumix::Component renderable = m_e.getComponent(crc32("renderable"))
			/*Lumix::Vec3 pos;
			static_cast<Lumix::Renderer*>(m_renderables[0].system)->getBonePosition(m_renderables[0], "HRigPelvis", &pos);
			Lumix::Matrix mtx;
			Lumix::Matrix::setIdentity(mtx);
			
			Lumix::Vec3 v(pos.x, pos.y - 10, pos.z);
			v.normalize();
			mtx.m31 = -v.x;
			mtx.m32 = -v.y;
			mtx.m33 = -v.z;
		
			Lumix::Vec3 up(0, 1, 0); 
			Lumix::Vec3 right = Lumix::crossProduct(v, up);
			up = Lumix::crossProduct(right, v);

			mtx.m21 = up.x;
			mtx.m22 = up.y;
			mtx.m23 = up.z;

			mtx.m11 = right.x;
			mtx.m12 = right.y;
			mtx.m13 = right.z;
			mtx.setTranslation(Lumix::Vec3(0, 10, 0));

			static_cast<Lumix::Renderer*>(m_renderables[0].system)->setCameraMatrix(mtx);
			*/
		}

		virtual void visit(Lumix::ScriptVisitor& visitor) override
		{
		}

		Lumix::Entity m_e;
};

extern "C" DLL_EXPORT Lumix::BaseScript* createScript()
{
	return new MyScript();
}

extern "C" DLL_EXPORT void destroyScript(Lumix::BaseScript* scr)
{
	delete scr;
}