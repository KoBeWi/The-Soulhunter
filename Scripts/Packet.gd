class_name Packet
extends Reference

enum TYPE {
	HELLO,
	LOGIN,
	REGISTER,
	ENTER_ROOM,
	PLAYER_ENTER,
	PLAYER_EXIT,
	KEYPRESS,
	KEYRELEASE
}

var data

func _init(command):
	data = PoolByteArray()
	data.append(1)
	add_u8(command)

func add_string(string):
	data.append_array(string.to_ascii())
	data.append(0)
	data[0] += string.length() + 1
	return self

func add_u8(i):
	data.append(i % 256)
	data[0] += 1
	return self

func add_u16(i):
	data.append(i / 256)
	data.append(i % 256)
	data[0] += 2
	return self