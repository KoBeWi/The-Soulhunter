class_name Data
extends Object

enum TYPE {
	U8,
    U16,
    STRING
}

enum CHATS {
	SYSTEM,
	GLOBAL,
	LOCAL,
	WHISPER
}

const NODES = [
	"Player",
	"Enemies/Skeleton",
	"Enemies/Bone"
]

const binary = [1, 2, 4, 8, 16, 32, 64, 128]

static func apply_state_vector(unpacker, node, diff_vector):
	var final_vector = node.get_state_vector()
	var data_types = node.state_vector_types()
	
	for i in data_types.size():
		if (diff_vector & binary[i]) > 0:
			match data_types[i]:
				TYPE.U8:
					final_vector[i] = unpacker.get_u8()
				TYPE.U16:
					final_vector[i] = unpacker.get_u16()
				TYPE.STRING:
					final_vector[i] = unpacker.get_string()
	
	node.apply_state_vector(final_vector)
	if !node.has_meta("initalized"):
		node.on_initialized()
		node.set_meta("initialized", true)