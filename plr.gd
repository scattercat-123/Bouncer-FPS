extends CharacterBody3D
# THIS Game is good?
@onready var gun_animation_player: AnimationPlayer = $Camera3D/fake_gun/AnimationPlayer
@onready var muzzle_flash: Node3D = $"muzzle flash"
@onready var fake_gun: Node3D = $Camera3D/fake_gun
@onready var gun_line: RayCast3D = $Camera3D/gun_line
@onready var knife_model: Node3D = get_node_or_null("Camera3D/knife")
@onready var knife_area: Area3D = get_node_or_null("Camera3D/knife/Area3D")

const BASE_SENSITIVITY = 0.005
const AIM_SENSITIVITY = 0.0005
var MOUSE_SENSITIVITY = BASE_SENSITIVITY
var camimp : Vector2
var rot : Vector2
	
var basefov = 75.0
var maxfov = 120.0
var fovkick = 0.0
var swingaccel = 20
var health = 100
var spawnpoint = Vector3(0, 2, 0)
var weapon = "s"
var has_shot = false
var decaltex : Texture2D = preload("res://assets/images/32x32_Impact_13.png")
		
var shooting = false
var can_shot = true
var dspd = 120.0
var ddur = 0.3
var dtim = 0.0
	
var kbstr = 25.0
var kbvelo = Vector3.ZERO
var wallaccel = 30.0
var wallduration = 0.25
var walltime = 0.0
var walldir = Vector3.ZERO
var max_speed = 80.0
var ground_accel = 20.0
var air_accel = 15.0
var ground_turn = 20.0	
var air_turn = 14.0
var ground_friction = 20.0
var air_friction = 10.0
var stop_speed = 8.0
var overspeed_drag = 25.0
var bouncing = false
	
var canboost = false
var nomarala
			
var grappling = false
var grapoint = Vector3.ZERO
var ropel = 0	
var curopel = 0
var offset	
var relspd = 10.0
	
var rope : MeshInstance3D
		
func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	
func _ready() -> void:
	scale = Vector3(10, 10, 10)
	add_to_group("sh")
	$Camera3D.current = is_multiplayer_authority()
	$Camera3D/RayCast3D.add_exception(self)
	gun_line.add_exception(self)
		
	if is_multiplayer_authority():
		$"player mesh/Node/Skeleton3D/Alpha_Surface".visible = false
		$"player mesh/Node/Skeleton3D/Alpha_Joints".visible = false
		global_position = spawnpoint + Vector3(randf_range(-70, 70), 70, randf_range(-70, 70))
		
	rope = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.1, 0.1, 1.0)
	rope.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.BLACK
	rope.material_override = mat
	rope.top_level = true
	rope.visible = false
	add_child(rope)
		
	if knife_area:
		knife_area.monitoring = true
		knife_area.body_entered.connect(_on_knife_body_entered)	
	
	set_weapon(weapon)
	
func set_weapon(w: String) -> void:
	weapon = w
	fake_gun.visible = (w == "s")
	if knife_model:
		knife_model.visible = (w == "k")
		
func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion:
		camimp = event.relative
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			set_weapon("s")
		elif event.keycode == KEY_2:
			set_weapon("k")
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			if weapon == "s":
				shoot()
			elif weapon == "k":
				knifeslice()
	
func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	var is_aiming: bool = weapon == "s" and Input.is_action_pressed("right")
	MOUSE_SENSITIVITY = AIM_SENSITIVITY if is_aiming else BASE_SENSITIVITY
	$SubViewport/scope.visible = is_aiming
	fake_gun.visible = (weapon == "s") and not is_aiming
		
	$SubViewport/HSlider.value = health
	
	rot = rot.lerp(camimp * MOUSE_SENSITIVITY, delta * 10.0)
	rotation.y -= rot.x	
	$Camera3D.rotation.x = clamp($Camera3D.rotation.x - rot.y, -1.5, 1.5)
	camimp = Vector2.ZERO	
	
	var target: float
	if is_aiming:
		target = 20.0
		$Camera3D.fov = lerpf($Camera3D.fov, target, 1.0 - exp(-12.0 * delta))
	else:
		var hspeed = Vector2(velocity.x, velocity.z).length()
		target = basefov + clamp(hspeed * 1.2, 0.0, 30.0)
		if grappling:
			target += 10.0
		target = clamp(target + fovkick, 50.0, maxfov)
		fovkick = lerp(fovkick, 0.0, delta * 8.0)
		$Camera3D.fov = lerp($Camera3D.fov, target, delta * 8.0)
	
func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
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

	if dtim > 0.0:
		dtim -= delta
		has_knockback = true
		if dtim <= 0.0:
			shooting = false

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if not has_knockback and not grappling:
		var on_floor = is_on_floor()
		var hvel = Vector2(velocity.x, velocity.z)
		var speed = hvel.length()
		if direction:
			var dir2 = Vector2(direction.x, direction.z)
			if speed > 0.01:
				var turn = ground_turn if on_floor else air_turn
				hvel = hvel.lerp(dir2 * speed, clampf(turn * delta, 0.0, 1.0))
			var along = hvel.dot(dir2)
			if along < max_speed:
				var rate = ground_accel if on_floor else air_accel
				hvel += dir2 * minf(rate * delta, max_speed - along)
			elif speed > max_speed:
				hvel = hvel.move_toward(hvel.normalized() * max_speed, overspeed_drag * delta)
		else:
			var fric = ground_friction if on_floor else air_friction
			hvel = hvel.move_toward(Vector2.ZERO, maxf(speed, stop_speed) * fric * delta)
		velocity.x = hvel.x
		velocity.z = hvel.y
		
	if grappling:
		
		sync_rope.rpc(global_position, grapoint, true)
		
		var pull_dir = (grapoint - global_position).normalized()
		velocity += pull_dir * swingaccel * delta
	
		ropel = move_toward(ropel, 2.0, relspd * delta)
		offset = global_position - grapoint
		curopel = offset.length()
		if curopel > ropel:
			var dir = offset.normalized()
			var away = velocity.dot(dir)
			if away > 0.0:
				velocity -= dir * away
			velocity -= dir * (curopel - ropel) * 10.0
	
	if Input.is_action_just_pressed("grapple"):
		grapel()	
		
	if Input.is_action_just_released("grapple"):
		grappling = false
		sync_rope.rpc(Vector3.ZERO, Vector3.ZERO, false)
			
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
	
@rpc("any_peer", "call_local", "unreliable")
func sync_rope(start: Vector3, point: Vector3, is_vis: bool) -> void:
	rope.visible = is_vis
	if is_vis:
		rope.global_position = (start + point) / 2.0
		rope.look_at(point)
		rope.scale = Vector3(1, 1, start.distance_to(point))
	
func shoot() -> void:
	if gun_animation_player.is_playing():
		return
	if not has_shot:
		gun_line.force_raycast_update()
		if gun_line.is_colliding():
			var col = gun_line.get_collider()
			if col.is_in_group("sh"):
				col.dmged.rpc_id(col.get_multiplayer_authority(), 50)
			else:
				make_decal(gun_line.get_collision_point(), gun_line.get_collision_normal())
		play_shoot_effects.rpc()
		has_shot = true
	else:	
		play_reload_effects.rpc()
		has_shot = false
	
@rpc("any_peer", "call_local")
func play_shoot_effects() -> void:
	gun_animation_player.play("shoot")
		
	muzzle_flash.shoot()
	gun_line.enabled = true
	await get_tree().create_timer(0.1).timeout
	gun_line.enabled = false
		
@rpc("any_peer", "call_local")
func play_reload_effects() -> void:
	gun_animation_player.play("reload")
		
func make_decal(pos: Vector3, normal: Vector3):
	var d = Decal.new()
	d.size = Vector3(4, 4, 4)
	d.texture_albedo = decaltex
	d.texture_emission = decaltex
	d.emission_energy = 8.0
	d.albedo_mix = 1.0
	d.modulate = Color(1, 1, 1, 1)
	d.upper_fade = 0.0
	d.lower_fade = 0.0
	d.cull_mask = 0xFFFFF
	get_tree().current_scene.add_child(d)
	d.global_position = pos
	var up = Vector3.UP
	if abs(normal.dot(up)) > 0.99:
		up = Vector3.RIGHT
	d.look_at(pos + normal, up)
	d.rotate_object_local(Vector3.RIGHT, -PI / 2)
	get_tree().create_timer(10.0).timeout.connect(d.queue_free)
		
func knifeslice():
	if not can_shot:
		return
		
	shooting = true
	velocity = -$Camera3D.global_transform.basis.z * dspd
	dtim = ddur
	can_shot = false
	get_tree().create_timer(2.0).timeout.connect(func(): can_shot = true)
	
func _on_knife_body_entered(body: Node3D) -> void:
	if shooting and body != self and body.is_in_group("sh"):
		
		body.dmged.rpc_id(body.get_multiplayer_authority(), 20)
		
@rpc("any_peer", "call_local", "reliable")
func dmged(dmg):
	if not is_multiplayer_authority():
		return
	health -= dmg
	if health <= 0:
		
		respawn()
	
func respawn():
	health = 100
	velocity = Vector3.ZERO
	global_position = spawnpoint
		
		
		
	
