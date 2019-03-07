#include <Godot.hpp>
#include <Node.hpp>
// #include <iostream>

using namespace godot;
// using namespace std;

class Server : public Node {
	GODOT_CLASS(Server, Node)

private:
	float time_passed;
	float time_emit;
	float amplitude;
	float speed;

public:
	static void _register_methods();

	Server();
	~Server();

	void _init(); // our initializer called by Godot

	void _process(float delta);
	void set_speed(float p_speed);
	float get_speed();
};