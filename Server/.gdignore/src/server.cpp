#include "server.h"

void Server::_register_methods() {
	register_method("_process", &Server::_process);
	register_method("_ready", &Server::_ready);
	register_method("listen", &Server::listen);
	register_method("handle_connection", &Server::handle_connection);
	register_property<Server, float>("amplitude", &Server::amplitude, 10.0);
	register_property<Server, float>("speed", &Server::set_speed, &Server::get_speed, 1.0);

	register_signal<Server>((char *)"position_changed", "node", GODOT_VARIANT_TYPE_OBJECT, "new_pos", GODOT_VARIANT_TYPE_VECTOR2);
}

Server::Server() {
}

Server::~Server() {
	// add your cleanup here
}

void Server::listen() {
	server = new TCP_Server();
	server->listen(2412);
}

void Server::_init() {
	// initialize any variables here
	time_passed = 0.0;
	amplitude = 10.0;
	speed = 1.0;
}

void Server::_ready() {
	// main_thread = thread(&Server::listen, this);
	listen();
}

void Server::_process(float delta) {
	time_passed += speed * delta;

	Vector2 new_position = Vector2(
		amplitude + (amplitude * sin(time_passed * 2.0)),
		amplitude + (amplitude * cos(time_passed * 1.5))
	);

	// set_position(new_position);

	time_emit += delta;
	if (time_emit > 1.0) {
		// emit_signal("position_changed", this, new_position);

		time_emit = 0.0;
	}

	// if (server->is_connection_available()) {
	// 	Godot::print("connection");
	// }
}

void Server::set_speed(float p_speed) {
	speed = p_speed;
}

float Server::get_speed() {
	return speed;
}