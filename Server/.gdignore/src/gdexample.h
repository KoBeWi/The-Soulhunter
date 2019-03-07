#ifndef GDEXAMPLE_H
#define GDEXAMPLE_H

#include <Godot.hpp>
#include <Sprite.hpp>

namespace godot {

class GDExample : public Sprite {
	GODOT_CLASS(GDExample, Sprite)

private:
	float time_passed;
	float time_emit;
	float amplitude;
	float speed;

public:
	static void _register_methods();

	GDExample();
	~GDExample();

	void _init(); // our initializer called by Godot

	void _process(float delta);
	void set_speed(float p_speed);
	float get_speed();
};

}

#endif
