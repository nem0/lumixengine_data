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


class MyScript : public Lux::BaseScript
{
	public:
		virtual void create(Lux::ScriptSystem& ctx, Lux::Entity entity) override
		{
			m_e = entity;
			/*Lux::Component animable = m_e.getComponent(crc32("animable"));
			if(animable.isValid())
			{
				Lux::AnimationSystem* sys = static_cast<Lux::AnimationSystem*>(animable.system);
				sys->playAnimation(animable, "models/horse.ani");
			}*/
		}

		virtual void update(float dt) override
		{
			if(GetAsyncKeyState(VK_UP) >> 8)
				m_e.setPosition(m_e.getPosition() + Lux::Vec3(0, 0, -10 * dt));
			if(GetAsyncKeyState(VK_DOWN) >> 8)
				m_e.setPosition(m_e.getPosition() + Lux::Vec3(0, 0, 10 * dt));
			//Lux::Component renderable = m_e.getComponent(crc32("renderable"))
			/*Lux::Vec3 pos;
			static_cast<Lux::Renderer*>(m_renderables[0].system)->getBonePosition(m_renderables[0], "HRigPelvis", &pos);
			Lux::Matrix mtx;
			Lux::Matrix::setIdentity(mtx);
			
			Lux::Vec3 v(pos.x, pos.y - 10, pos.z);
			v.normalize();
			mtx.m31 = -v.x;
			mtx.m32 = -v.y;
			mtx.m33 = -v.z;
		
			Lux::Vec3 up(0, 1, 0); 
			Lux::Vec3 right = Lux::crossProduct(v, up);
			up = Lux::crossProduct(right, v);

			mtx.m21 = up.x;
			mtx.m22 = up.y;
			mtx.m23 = up.z;

			mtx.m11 = right.x;
			mtx.m12 = right.y;
			mtx.m13 = right.z;
			mtx.setTranslation(Lux::Vec3(0, 10, 0));

			static_cast<Lux::Renderer*>(m_renderables[0].system)->setCameraMatrix(mtx);
			*/
		}

		virtual void visit(Lux::ScriptVisitor& visitor) override
		{
		}

		Lux::Entity m_e;
};

extern "C" DLL_EXPORT Lux::BaseScript* createScript()
{
	return new MyScript();
}

extern "C" DLL_EXPORT void destroyScript(Lux::BaseScript* scr)
{
	delete scr;
}