set blend_name=%1
set msh_name=%2
set base_path=%3
if exist "C:\Program Files (x86)\Blender Foundation\Blender\blender.exe" (
	"C:\Program Files (x86)\Blender Foundation\Blender\blender.exe" "%blend_name%" --background -P "%base_path%\exporters\msh_export.py" -- "%msh_name%"
) else (
	"C:\Program Files\Blender Foundation\Blender\blender.exe" "%blend_name%" --background -P "%base_path%\exporters\msh_export.py" -- "%msh_name%"
)