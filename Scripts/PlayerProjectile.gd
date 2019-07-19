extends KinematicBody2D
class_name PlayerProjectile

var player

func _dispose():
	Com.dispose_node(self)