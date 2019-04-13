extends Resource
class_name ItemData

enum TYPE {GENERIC, CONSUMABLE, WEAPON, ARMOR}

export(TYPE) var type = 0
export var id = 0
export var item_name = ""

##tymczasowo, bo bug
export var attack = 0
export var defense = 0