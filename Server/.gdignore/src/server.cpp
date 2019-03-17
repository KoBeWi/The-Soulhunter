#include "server.hpp"

void Server::_register_methods() {
	register_method("_process", &Server::_process);
	register_method("_ready", &Server::_ready);
	// register_method("listen", &Server::listen);
	// // register_method("handle_connection", &Server::handle_connection);
	// register_property<Server, float>("amplitude", &Server::amplitude, 10.0);
	// register_property<Server, float>("speed", &Server::set_speed, &Server::get_speed, 1.0);

	// register_signal<Server>((char *)"position_changed", "node", GODOT_VARIANT_TYPE_OBJECT, "new_pos", GODOT_VARIANT_TYPE_VECTOR2);
}

Server::Server() {
	Database::initialize();
}

Server::~Server() {
	// add your cleanup here
}

void Server::_init() {
	// initialize any variables here
	// time_passed = 0.0;
	// amplitude = 10.0;
	// speed = 1.0;
}

void Server::_ready() {

	server = TCP_Server::_new();
	server->listen(2412);
}

void Server::_process(float delta) {
	if (server->is_connection_available()) {
		Ref<StreamPeerTCP> peer = server->take_connection();
		Godot::print("New player connected");

		peer->put_data(Packet().add_str("HELLO"));
		peers.push_back(peer);
	}

	for (Ref<StreamPeerTCP> peer : peers) {
		Array packet_size = peer->get_partial_data(1);
		int error = (int)packet_size[0];
		PoolByteArray data = (PoolByteArray)packet_size[1];

		if (error == GODOT_FAILED) continue;

		if (error == GODOT_ERR_FILE_EOF) {
			// peers.erase(peer);
			continue;
		}

		// Godot::print((int)packet_size.size());
		if (data.size() == 0) continue;
		data = (PoolByteArray)peer->get_partial_data((int)data[0])[1];

		string command = Packet::get_str(data, 0);

		Unpacker::unpack(data, command, peer);
	}

	// time_passed += speed * delta;

	// Vector2 new_position = Vector2(
	// 	amplitude + (amplitude * sin(time_passed * 2.0)),
	// 	amplitude + (amplitude * cos(time_passed * 1.5))
	// );

	// // set_position(new_position);

	// time_emit += delta;
	// if (time_emit > 1.0) {
	// 	// emit_signal("position_changed", this, new_position);

	// 	time_emit = 0.0;
	// }

	// // if (server->is_connection_available()) {
	// // 	Godot::print("connection");
	// // }
}

// void Server::set_speed(float p_speed) {
// 	speed = p_speed;
// }

// float Server::get_speed() {
// 	return speed;
// }