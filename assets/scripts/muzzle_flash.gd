extends Node3D

@onready var is_light: OmniLight3D = $OmniLight3D
@onready var is_particles: GPUParticles3D = $GPUParticles3D
@onready var timer: Timer = $FlashTimer

func _ready() -> void:
	is_light.light_energy = 0.0

func shoot() -> void:
	$AudioStreamPlayer.play()
	is_particles.restart()
	is_particles.emitting = true

	is_light.light_energy = 5.0

	var tween = create_tween()
	tween.tween_property(is_light, "light_energy", 0.0, 0.08)
