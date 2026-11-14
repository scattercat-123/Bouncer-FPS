extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var MOUSE_SENSITIVITY = 0.01

var camimp : Vector2
var rot : Vector2

var bouncing = false

func _input(event: InputEvent) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion:
		camimp = event.relative

func _process(delta: float) -> void:
	rot = rot.lerp(camimp * MOUSE_SENSITIVITY, delta * 10.0)
	rotation.y -= rot.x
	$Camera3D.rotation.x = clamp($Camera3D.rotation.x - rot.y, -1.5, 1.5)
	camimp = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction and !bouncing:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	elif !bouncing and !direction:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()

func detcol():
	if get_slide_collision_count() != 0:
		for i in get_slide_collision_count():
			bouncing = true
			velocity = velocity + (get_slide_collision(i).get_normal() * 10)
