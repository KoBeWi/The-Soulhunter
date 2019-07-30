extends CanvasLayer

var prev_state

func _ready():
	Network.connect("stats", self, "update_HUD")
	Network.connect("game_over", self, "on_over")
	$PlayerMenu.connect("visibility_changed", self, "toggle_help", [$PlayerMenu])
	$Map.connect("visibility_changed", self, "toggle_help", [$Map])
	Com.controls.connect("key_press", self, "on_key_press")

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		$Exit.visible = true
		prev_state = Com.controls.state
		Com.controls.state = Controls.State.QUIT

func on_key_press(p_id, key, state):
	if state == Controls.State.QUIT:
		if key == Controls.ACCEPT:
			Packet.new(Packet.TYPE.LOGOUT).send()
			get_tree().quit()
		elif key == Controls.CANCEL:
			$Exit.visible = false
			Com.controls.state = prev_state
		elif key == Controls.SOUL:
			Packet.new(Packet.TYPE.LOGOUT).send()
			get_tree().change_scene("res://Scenes/Title.tscn")

func update_bar(bar):
	var bar_node = get_node("HUD/" + bar + "Bar")
	var label = get_node("HUD/" + bar + "Label")
	
	label.set_text(str(bar_node.value, "/", bar_node.max_value))
	if bar_node.value < bar_node.max_value / 8:
		label.modulate = Color.red
	elif bar_node.value < bar_node.max_value / 4:
		label.modulate = Color.yellow
	else:
		label.modulate = Color.white

func update_HUD(data):
	if "max_hp" in data:
		$HUD/HPBar.max_value = data.max_hp
		update_bar("HP")
	
	if "hp" in data:
		$HUD/HPBar.value = data.hp
		update_bar("HP")
	
	if "max_mp" in data:
		$HUD/MPBar.max_value = data.max_mp
		update_bar("MP")
	
	if "mp" in data:
		$HUD/MPBar.value = data.mp
		update_bar("MP")
	
	if "level" in data:
		$HUD/LvLabel.text = str(data.level)
	
	if "exp" in data:
		var lv = int($HUD/LvLabel.text)
		$HUD/ExpBar.max_value = Com.exp_for_level(lv)
		$HUD/ExpBar.value = data.exp - Com.total_exp_for_level(lv-1)

func reg_mp():
	update_HUD({mp = min($HUD/MPBar.value+1, $HUD/MPBar.max_value)})

func toggle_help(menu):
	if menu == $Map:
		if menu.visible:
			$Help/Key.visible = false
			$Help/Key2.set_text("Close")
		else:
			$Help/Key.visible = true
			$Help/Key2.set_text("Map")
	else:
		$Help.visible = !menu.visible

func on_over(whatever):
	$HUD/HPBar.value = 0
	update_bar("HP")
	$Help.visible = false