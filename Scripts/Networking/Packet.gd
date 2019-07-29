class_name Packet
extends Reference

enum TYPE {
	HELLO,
	LOGIN,
    LOGOUT,
	REGISTER,
	ENTER_ROOM,
	KEY_PRESS,
	KEY_RELEASE,
	ADD_ENTITY,
	REMOVE_ENTITY,
	TICK,
	SPECIAL_DATA,
	INITIALIZER,
	CHAT,
	DAMAGE,
	STATS,
	INVENTORY,
	EQUIPMENT,
	SOULS,
	SOUL_EQUIPMENT,
	ABILITIES,
	MAP,
    CONSUME,
	EQUIP,
	EQUIP_SOUL,
	ITEM_GET,
	SOUL_GET,
	SAVE,
	GAME_OVER
}

const stat_list = ["level", "exp", "hp", "max_hp", "mp", "max_mp", "attack", "defense", "magic_attack", "magic_defense", "luck"]

var data : PoolByteArray

func _init(command) -> void:
	data = PoolByteArray()
	data.append(1)
	add_u8(command)

func add_string(string : String) -> Packet:
	data.append_array(string.to_ascii())
	data.append(0)
	data[0] += string.length() + 1
	return self

func add_string_unicode(string : String) -> Packet:
	data.append_array(string.to_utf8())
	data.append(0)
	data[0] += string.length() + 1
	return self

func add_u8(i : int) -> Packet:
	data.append(i % 256)
	data[0] += 1
	return self

func add_u16(i : int) -> Packet:
	data.append(i / 256)
	data.append(i % 256)
	data[0] += 2
	return self

func send() -> void:
#	print("Sending: ", TYPE.keys()[data[1]])
	Network.send_data(self)