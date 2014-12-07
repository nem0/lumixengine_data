set blend_name=%1
set msh_name=%blend_name:.blend=.msh%
set base_path=%2
if exist "C:\Program Files (x86)\Blender Foundation\Blender\blender.exe" (
	"C:\Program Files (x86)\Blender Foundation\Blender\blender.exe" "%blend_name%" --background -P "%base_path%\exporters\msh_export.py" -- "%msh_name%"
) else (
	"C:\Program Files\Blender Foundation\Blender\blender.exe" "%blend_name%" --background -P "%base_path%\exporters\msh_export.py" -- "%msh_name%"
)