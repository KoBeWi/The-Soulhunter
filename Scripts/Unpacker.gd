class_name Unpacker
extends Node

var data
var command
var offset = 1

func _init(_data):
	data = _data
	command = get_string()

func get_string():
	var string = PoolByteArray()
	
	while data[offset] > 0:
		string.append(data[offset])
		offset += 1
	
	offset += 1
	
	return string.get_string_from_ascii()

func get_u16():
    offset += 2
    return data[offset-2] * 256 + data[offset-1]

func get_u8():
    offset += 1
    return data[offset-1]