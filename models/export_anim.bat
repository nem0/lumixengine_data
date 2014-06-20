set blend_name=%1
set ani_name=%blend_name:.blend=.ani%
set base_path=%2
"C:\Program Files (x86)\Blender Foundation\Blender\blender.exe" "%blend_name%" --background -P "%base_path%\exporters\ani_export.py" -- "%ani_name%"