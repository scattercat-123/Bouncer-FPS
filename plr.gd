extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var MOUSE_SENSITIVITY = 0.01

var camimp : Vector2
var rot : Vector2

var kbstr = 10.0
var kbvelo = Vector3.ZERO

var wallaccel = 100.0
var wallduration = 0.25
var walltime = 0.0
var walldir = Vector3.ZERO

var grip = 60.0
var brake = 150.0
var accel = 12.0
var decel = 1000.0
var aircontrol = 0.4

var bouncing = false

var canboost = false
var nomarala 

var grappling = false
var grapoint
var ropel = 0
var curopel = 0

var offset
var relspd = 10.0
var swingaccel = 30.0

var rope : MeshInstance3D

func _ready() -> void:
	rope = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.03, 0.03, 1.0)
	rope.mesh = box
	rope.top_level = true
	rope.visible = false
	add_child(rope)

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
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("ui_accept") and canboost:
		velocity.y = 20.0
		canboost = false
	if walltime > 0.0:
		walltime -= delta
		has_knockback = true
		velocity.x += walldir.x * wallaccel * delta
		velocity.z += walldir.z * wallaccel * delta
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if not has_knockback and not grappling:
		var rate = accel
		var gripr = grip
		var braker = brake
		if not is_on_floor():
			rate *= aircontrol
			gripr *= aircontrol
			braker *= aircontrol
		var hvel = Vector2(velocity.x, velocity.z)
		if direction:
			var dir2 = Vector2(direction.x, direction.z)
			var along = hvel.dot(dir2)
			var side = hvel - dir2 * along
			side = side.move_toward(Vector2.ZERO, gripr * delta)
			if along < 0.0:
				along = move_toward(along, 0.0, braker * delta)
			hvel = dir2 * along + side
			hvel += dir2 * rate * delta
		else:
			hvel = hvel.move_toward(Vector2.ZERO, decel * delta)
		velocity.x = hvel.x
		velocity.z = hvel.y
	if grappling:
		var start = global_position
		rope.visible = true
		rope.global_position = (start + grapoint) / 2.0
		rope.look_at(grapoint)
		rope.scale = Vector3(1, 1, start.distance_to(grapoint))
		
		
		ropel = move_toward(ropel, 2.0, relspd * delta)
		offset = global_position - grapoint
		curopel = offset.length()
		if curopel > ropel:
			var dir = offset.normalized()
			var away = velocity.dot(dir)
			if away > 0.0:
				velocity -= dir * away
			velocity -= dir * (curopel - ropel) * 1.0
	if Input.is_action_just_pressed("grapple"):
		grapel()
	if Input.is_action_just_released("grapple"):
		grappling = false
	move_and_slide()
	detcol()

func detcol():
	for i in get_slide_collision_count():
		var normal = get_slide_collision(i).get_normal()
		if abs(normal.y) < 0.7:
			if walltime <= 0.0:
				walldir = Vector3(normal.x, 0, normal.z).normalized()
				walltime = wallduration
				kbvelo = walldir * kbstr
				canboost = true
				$Timer.start()
				nomarala = normal
			return
		bouncing = true
		kbvelo = normal * kbstr

func _on_timer_timeout() -> void:
	canboost = false

func grapel():
	if $Camera3D/RayCast3D.get_collider() == null:
		return
	grapoint = $Camera3D/RayCast3D.get_collision_point()
	grappling = true
	ropel = global_position.distance_to(grapoint)
	
	
	
