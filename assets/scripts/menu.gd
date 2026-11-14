extends Node2D
@onready var bouncer: Label = $bouncer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _on_settings_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		pass

func _on_play_gui_input(event: InputEvent) -> void:
	animation_player.play("close")
	await animation_player.is_playing()
	get_tree().change_scene_to_file("res://assets/scenes/main.tscn")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(bouncer, "position:y", position.y - 20, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(bouncer, "position:y", position.y, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
