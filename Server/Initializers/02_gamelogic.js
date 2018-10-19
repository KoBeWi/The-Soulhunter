module.exports = GameLogic = {
    levelExp: function(level) {
		return level * 10
	},
	
    levelExpTotal: function(level) {
		return level * (level + 1) * 5
	},
	
	equipment_slots: ["head", "torso", "feet", "left_hand", "right_hand", "accessory1", "accessory2", "body"],
	slot_types: {head: ["helmet", "hat", "cap"],
				torso: ["armor", "vest", "clothing"],
				feet: ["shoes", "boots", "socks"],
				left_hand: ["weapon", "shield"],
				right_hand: ["weapon", "shield"],
				accessory1: ["accessory"],
				accessory2: ["accessory"],
				body: ["cape", "cloak", "aura"]}
}