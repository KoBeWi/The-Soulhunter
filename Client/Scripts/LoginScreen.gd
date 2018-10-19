extends Node2D

var error

func _process(delta):
	if $"/root/Network".account:
		get_tree().change_scene("Scenes/InGame.tscn")
	
	if error:
		$Label.text = "Failed to log in: " + ["user doesn't exist", "wrong password", "user already online"][error-1]

func _on_Login_pressed():
	$"/root/Network".send_data(["login", $Login.text, $Password.text])

func _on_Register_pressed():
	$"/root/Network".send_data(["register", $Login.text, $Password.text])