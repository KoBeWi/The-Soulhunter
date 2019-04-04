class_name Unpacker
extends Reference

var data
var command
var offset = 0
var size = 0

func _init(_data, _size):
	data = _data
	size = _size
	command = get_u8()

func get_string():
	var string = PoolByteArray()
	
	while data[offset] > 0:
		string.append(data[offset])
		offset += 1
	
	offset += 1
	
	return string.get_string_from_ascii()

func get_u16():
#	print("u16 ", data[offset] * 256 + data[offset+1])
	offset += 2
	return data[offset-2] * 256 + data[offset-1]

func get_u8():
#	print("u8 ", data[offset])
	offset += 1
	return data[offset-1]

func get_position():
	var mode = get_u8()
	var offset
	
	if mode != 4:
		offset = get_u16()
	
	match mode:
		0: return Vector2(offset * 1920, 0)
		1: return Vector2(Com.game.map.width * 1920 - 30, offset * 1080 + 540)
		2: return Vector2(offset * 1920, Com.game.map.height * 1080 - 1)
		3: return Vector2(30, offset * 1080 + 540)
		4: return Com.game.map.get_node("SavePoint/PlayerSpot").global_position ##niebezpieczne
		5: return Vector2(offset, get_u16())