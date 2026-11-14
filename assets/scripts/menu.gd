extends Node2D
@onready var bouncer: Label = $bouncer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

const MAIN = preload("res://assets/scenes/main.tscn")

func _ready() -> void:
	if Global.debug_mode:
		get_tree().change_scene_to_packed(MAIN)

func _on_settings_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		pass

func _on_play_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		animation_player.play("close")
		$butttons.visible = false
		$bouncer.visible = false
		await animation_player.animation_finished
		get_tree().change_scene_to_packed(MAIN)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(bouncer, "position:y", -40, 0.5).as_relative().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(bouncer, "position:y", 40, 0.5).as_relative().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
