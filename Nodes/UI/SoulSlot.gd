tool
extends HBoxContainer

export var type = ""
export var soul = ""
export var color = Color.red
export var no_select = false

func _ready():
	if !Engine.editor_hint:
		set_process(false)

func _process(delta):
	$Type.text = type
	$Name.text = soul
	$Icon/LeftRect.rect_size.x = $Type.rect_size.x + 30
	$Name/RightRect.rect_size.x = $Name.rect_size.x + 18
	$Icon.self_modulate = color
	$Icon/LeftRect.modulate = color.darkened(0.4)
	$Name/RightRect.modulate = color.darkened(0.8)
	
	$Name.visible = !no_select