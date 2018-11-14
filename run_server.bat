echo "---------------------------------------------------------------------------"
cargo build
if %errorlevel% neq 0 exit /b %errorlevel%
copy target\debug\main.dll Server\server.dll
godot --s Scenes/Server.tscn