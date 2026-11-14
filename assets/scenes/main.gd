extends Node3D

@export var player_scene: PackedScene

const PORT = 9999
const MAX_CLIENTS = 8

var peer: WebSocketMultiplayerPeer
var connected = false

var ui: CanvasLayer
var menu: VBoxContainer
var ip_input: LineEdit
var host_button: Button
var status: Label

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_ui()
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)

	menu = VBoxContainer.new()
	menu.position = Vector2(20, 20)
	menu.custom_minimum_size = Vector2(320, 0)
	ui.add_child(menu)

	ip_input = LineEdit.new()
	ip_input.placeholder_text = "Host IP, e.g. 192.168.1.20"
	ip_input.text = "127.0.0.1"
	menu.add_child(ip_input)

	host_button = Button.new()
	host_button.text = "Host"
	host_button.pressed.connect(host_game)
	menu.add_child(host_button)

	var join_button = Button.new()
	join_button.text = "Join"
	join_button.pressed.connect(join_game)
	menu.add_child(join_button)

	status = Label.new()
	status.position = Vector2(20, 150)
	ui.add_child(status)

	if OS.has_feature("web"):
		host_button.disabled = true
		status.text = "Browsers can't host. Join a game hosted from the desktop build."

func host_game() -> void:
	if connected or OS.has_feature("web"):
		return
	peer = WebSocketMultiplayerPeer.new()
	var err = peer.create_server(PORT)
	if err != OK:
		status.text = "Could not host (error %d). Is port %d already in use?" % [err, PORT]
		return
	connected = true
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_spawn_player)
	_spawn_player(1)
	menu.hide()
	var lines = ["Hosting on port %d" % PORT]
	for a in _lan_addresses():
		lines.append("Join with: %s" % a)
	status.text = "\n".join(lines)

func join_game() -> void:
	if connected:
		return
	var addr = ip_input.text.strip_edges()
	if addr == "":
		return
	var url = addr
	if not (addr.begins_with("ws://") or addr.begins_with("wss://")):
		url = "ws://%s:%d" % [addr, PORT]
	peer = WebSocketMultiplayerPeer.new()
	var err = peer.create_client(url)
	if err != OK:
		status.text = "Could not start connection (error %d)" % err
		return
	connected = true
	multiplayer.multiplayer_peer = peer
	menu.hide()
	status.text = "Joining %s ..." % url

func _lan_addresses() -> Array:
	var out = []
	for a in IP.get_local_addresses():
		if a.count(".") == 3 and not a.begins_with("127.") and not a.begins_with("169.254."):
			out.append(a)
	return out

func _spawn_player(id: int) -> void:
	var plr = player_scene.instantiate()
	plr.name = str(id)
	add_child(plr)
	plr.global_position = Vector3(0, 5, 0)

func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server():
		return
	var plr = get_node_or_null(str(id))
	if plr:
		plr.queue_free()

func _on_connected_to_server() -> void:
	status.text = ""

func _on_connection_failed() -> void:
	connected = false
	multiplayer.multiplayer_peer = null
	menu.show()
	status.text = "Connection failed. Check the IP, that the host is running, and that port %d is open." % PORT

func _on_server_disconnected() -> void:
	multiplayer.multiplayer_peer = null
	get_tree().reload_current_scene()
