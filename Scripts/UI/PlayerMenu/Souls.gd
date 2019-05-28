extends VBoxContainer

export(NodePath) var main = @"../../.."
export(NodePath) var select_rect = @"../../../SoulSelect"

onready var slots = $Slots

var select = 0

func _ready():
	main = get_node(main)
	select_rect = get_node(select_rect)

func on_press_key(key):
	var old_select = select
	if key == Controls.RIGHT:
		select = min(select + 1, slots.get_child_count()-1)
	elif key == Controls.LEFT:
		select = max(select - 1, 0)
	elif key == Controls.DOWN:
		select = min(select + slots.columns, slots.get_child_count()-1)
	elif key == Controls.UP:
		select = max(select - slots.columns, 0)
	
	if select != old_select:
		select()

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if visible:
			select_rect.visible = true
			select()
		else:
			select_rect.visible = false

func select():
	var selected = slots.get_child(select)
	select_rect.rect_size = selected.rect_size
	select_rect.rect_position = selected.get_global_rect().position - main.get_global_rect().position