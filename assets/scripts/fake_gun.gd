extends Node3D

var downward_offset: float = 0

func _ready() -> void:
	position.y += downward_offset
