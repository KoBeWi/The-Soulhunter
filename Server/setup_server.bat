mkdir .client
cd ../Client
godot --export "Windows Desktop" ../Server/.client/Test.exe
cd ../Server
npm install