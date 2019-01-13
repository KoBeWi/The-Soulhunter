echo "---------------------------------------------------------------------------"
cd Server
cargo build
if %errorlevel% neq 0 exit /b %errorlevel%
cd ..
copy Server\target\debug\server.dll Server\server.dll
godot --s Scenes/Server.tscn