extends Control

@onready var h_slider: HSlider = $HSlider

func _ready() -> void:
	if not is_multiplayer_authority():
		hide()
func _process(delta: float) -> void:
	if is_multiplayer_authority():
		h_slider.value = owner.health
