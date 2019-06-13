extends Control

func _ready():
	if OS.get_name() == 'HTML5':
		$connect/server.hide()
	# Called every time the node is added to the scene.
	gamestate.connect("connection_failed", self, "_on_connection_failed")
	gamestate.connect("connection_succeeded", self, "_on_connection_success")
	gamestate.connect("player_list_changed", self, "refresh_lobby")
	gamestate.connect("lobby_joined", self, "_update_lobby")
	gamestate.connect("game_ended", self, "_on_game_ended")
	gamestate.connect("game_error", self, "_on_game_error")
	if OS.get_name() == 'HTML5':
		var data = JavaScript.eval("(new URLSearchParams(window.location.hash.replace('#', '', 1))).get('lobby')")
		if typeof(data) == TYPE_STRING:
			$connect/lobby.text = data

func _update_lobby(text):
	if OS.get_name() == 'HTML5':
		JavaScript.eval("var x = new URLSearchParams(window.location.hash.replace('#', '', 1)); x.set('lobby', '" + text + "'); window.location.hash = x.toString()")
	$players/lobby.text = text

func _on_host_pressed():
	if get_node("connect/name").text == "":
		get_node("connect/error_label").text = "Invalid name!"
		return

	get_node("connect").hide()
	get_node("players").show()
	get_node("connect/error_label").text = ""

	var player_name = get_node("connect/name").text
	var ip = get_node("connect/ip").text
	gamestate.host_game(player_name, ip)
	# refresh_lobby() gets called by the player_list_changed signal, emitted when host is ready

func _on_join_pressed():
	if get_node("connect/name").text == "":
		get_node("connect/error_label").text = "Invalid name!"
		return

	var ip = get_node("connect/ip").text
	var lobby = get_node("connect/lobby").text
	if lobby == '':
		get_node("connect/error_label").text = "Must specify a lobby when joining!"
		return
	get_node("connect/error_label").text=""
	get_node("connect/host").disabled = true
	get_node("connect/join").disabled = true

	var player_name = get_node("connect/name").text
	gamestate.join_game(ip, player_name, lobby)
	# refresh_lobby() gets called by the player_list_changed signal

func _on_connection_success():
	get_node("connect").hide()
	get_node("players").show()

func _on_connection_failed():
	get_node("connect/host").disabled = false
	get_node("connect/join").disabled = false
	get_node("connect/error_label").set_text("Connection failed.")

func _on_game_ended():
	show()
	get_node("connect").show()
	get_node("players").hide()
	get_node("connect/host").disabled = false
	get_node("connect/join").disabled = false
	if OS.get_name() == 'HTML5':
		JavaScript.eval("var x = new URLSearchParams(window.location.hash.replace('#', '', 1)); x.delete('lobby'); window.location.hash = x.toString()")
	$players/lobby.text = ''
	$connect/lobby.text = ''

func _on_game_error(errtxt):
	get_node("error").dialog_text = errtxt
	get_node("error").popup_centered_minsize()

func refresh_lobby():
	var players = gamestate.get_player_list()
	players.sort()
	get_node("players/list").clear()
	get_node("players/list").add_item(gamestate.get_player_name() + " (You)")
	for p in players:
		get_node("players/list").add_item(p)

	get_node("players/start").disabled = not get_tree().is_network_server()

func _on_start_pressed():
	gamestate.begin_game()

func _on_server_toggled(button_pressed):
	if button_pressed:
		Server.listen(9080)
		$connect/server.text = "Stop"
	else:
		Server.stop()
		$connect/server.text = "Listen"