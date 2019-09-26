# The Soulhunter

This is a repository of the project made for my master thesis. It was originally private, but I defended the thesis and thought there's no reason it's not public. The thesis itself is public too, you can read it here: https://www.ap.uj.edu.pl/diplomas/135570
(keep in mind that it's in Polish, but Google Translate might help understand the important parts)

It's an MMORPG game made in Godot engine. The project is discontinued. It might be revived eventually, but not as MMORPG. It's just too much work to develop it further. Read the thesis if you want to know the inner workings.

# Running

To run the game, you need the server running first. The easy way to run is download the build from [here](https://ufile.io/bols560h) (Windows only) and follow the instructions.

If you want to run from source, you need Mono version of Godot engine 3.1.x (available [here](https://godotengine.org/download)) and installed MongoDB.

First run the database:
```
mkdir .database
mongod --dbpath ".\.database"
```
Then server:
```
godot --s Server/Nodes/Server.tscn
```
And finally the game:
F5 in the editor is fine.

You can use `.bat` scripts included in the source, but you need Godot and Godot Mono available in your PATH (as `godot.exe` and `godot_mono.exe` respectively).

The exported build (aside from the one linked above) will try to connect via Serveo instead of localhost. Use `forward_server.bat` if you want to host the server globally.
