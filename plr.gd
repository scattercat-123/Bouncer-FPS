extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var MOUSE_SENSITIVITY = 0.01

var camimp : Vector2
var rot : Vector2

var kbstr = 25.0
var kbvelo = Vector3.ZERO

var wallstr = 12.0
var walldecay = 15.0
var wallvel = Vector3.ZERO

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
	var has_knockback = kbvelo != Vector3.ZERO
	velocity += kbvelo
	kbvelo = Vector3.ZERO
	if wallvel.length() > 0.5:
		velocity.x = wallvel.x
		velocity.z = wallvel.z
		wallvel = wallvel.move_toward(Vector3.ZERO, walldecay * delta)
		has_knockback = true
	else:
		wallvel = Vector3.ZERO
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		pass
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if not has_knockback:
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()
	detcol()


func detcol():
	for i in get_slide_collision_count():
		var normal = get_slide_collision(i).get_normal()
		if abs(normal.y) < 0.7:
			wallvel = Vector3(normal.x, 0, normal.z).normalized() * wallstr
			return
		bouncing = true
		kbvelo = normal * kbstr
