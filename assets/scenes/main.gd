extends Node3D

@export var player_scene: PackedScene # Drag plr.tscn into this Inspector slot!
var peer = ENetMultiplayerPeer.new()
const PORT = 9999
var connected = false

func _unhandled_input(event: InputEvent) -> void:
	if connected:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_H:
			host_game()
		elif event.keycode == KEY_J:
			join_game()
func host_game() -> void:
	connected = true
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_spawn_player)
	_spawn_player(1)
	print("Hosting game on port ", PORT)	
		
func join_game() -> void:
	connected = true
	peer.create_client("127.0.0.1", PORT)
	multiplayer.multiplayer_peer = peer
	print("Joining game...")
		
func _spawn_player(id: int) -> void:
	var plr = player_scene.instantiate()
	plr.name = str(id)
	add_child(plr)
	plr.global_position = Vector3(0, 5, 0)
