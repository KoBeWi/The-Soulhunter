cargo build
copy target\debug\main.dll Server\server.dll
godot --s Scenes/Server.tscn