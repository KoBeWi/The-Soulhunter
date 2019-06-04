tool
extends HBoxContainer

export var type = ""
export var soul = ""
export var color = Color.red
export var no_select = false

func _process(delta):
	if Engine.editor_hint:
		$Type.text = type
		$Name.text = soul
		$Icon.self_modulate = color
		$Icon/LeftRect.modulate = color.darkened(0.4)
		$Name/RightRect.modulate = color.darkened(0.8)
	
		$Name.visible = !no_select
	
	$Icon/LeftRect.rect_size.x = $Type.rect_size.x + 30
	$Name/RightRect.rect_size.x = $Name.rect_size.x + 18

func set_soul(soul):
	$Name.text = soul

func clear_soul():
	$Name.text = "  ---  "

func empty():
	return $Name.text == "  ---  "