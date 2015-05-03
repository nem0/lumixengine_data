set blend_name=%1
set ani_name=%2
set base_path=%3
if exist "C:\Program Files (x86)\Blender Foundation\Blender\blender.exe" (
	"C:\Program Files (x86)\Blender Foundation\Blender\blender.exe" "%blend_name%" --background -P "%base_path%\exporters\ani_export.py" -- "%ani_name%"
) else (
	"C:\Program Files\Blender Foundation\Blender\blender.exe" "%blend_name%" --background -P "%base_path%\exporters\ani_export.py" -- "%ani_name%"
)