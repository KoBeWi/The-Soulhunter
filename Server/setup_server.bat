mkdir .client
cd ../Client
godot --export "Windows Desktop" ../Server/.client/Client.exe
cd ../Server
npm install