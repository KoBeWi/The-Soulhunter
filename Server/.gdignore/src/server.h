#include <Godot.hpp>
#include <Node.hpp>
#include <thread>
#include <core/>

using namespace godot;
using namespace std;

class Server : public Node {
	GODOT_CLASS(Server, Node)

private:
	float time_passed;
	float time_emit;
	float amplitude;
	float speed;

	TCP_Server* server;
	thread main_thread;

public:
	static void _register_methods();

	Server();
	~Server();

	void _init();
	void _ready();

	void _process(float delta);
	void set_speed(float p_speed);
	float get_speed();
	void listen();
};