#Save_Manager.gd
extends Node

const CONFIG_FILE_PATH = "user://settings.cfg"

signal save_completed(slot: int)
signal save_failed(reason: String)
signal load_completed(slot: int)
signal load_failed(reason: String)

const DEFAULT_SPAWN_POSITION: Vector2 = Vector2(40.0, 258.0)
const FIRST_LEVEL_PATH: String = "res://levels/00_prison/01.tscn"
const MAX_SLOTS: int = 3
const PLAYER_WAIT_TIMEOUT: float = 5.0

var current_slot: int = 0
var save_data: Dictionary = {}
var discovered_areas: Array[String] = []
var persistent_data: Dictionary = {}
var is_loading: bool = false
var is_saving: bool = false

func _ready() -> void:
	load_configuration()
	print("[SAVE MANAGER] Sistema inicializado")
	_connect_signals()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	
	if is_loading or is_saving:
		return
	
	match event.keycode:
		KEY_F5:
			save_game()
		KEY_F7:
			load_game(current_slot)
		KEY_1:
			current_slot = 0
		KEY_2:
			current_slot = 1
		KEY_3:
			current_slot = 2

func create_new_game_save(slot: int) -> bool:
	if not _validate_slot(slot):
		return false
	
	if not _validate_user_logged_in():
		return false
	
	if is_saving:
		push_warning("[SAVE MANAGER] Save em progresso, aguarde")
		return false
	
	is_saving = true
	current_slot = slot
	
	_reset_game_state()
	discovered_areas.append(FIRST_LEVEL_PATH)
	
	var success = _write_save_to_database(
		FIRST_LEVEL_PATH,
		DEFAULT_SPAWN_POSITION,
		_get_default_player_stats()
	)
	
	is_saving = false
	
	if success:
		print("[SAVE MANAGER] Novo jogo criado - Slot: ", slot)
		save_completed.emit(slot)
	else:
		push_error("[SAVE MANAGER] Falha ao criar novo jogo")
		save_failed.emit("Database write failed")
	
	return success

func save_game() -> bool:
	if not _validate_user_logged_in():
		save_failed.emit("User not logged in")
		return false
	
	if is_saving:
		push_warning("[SAVE MANAGER] Save ja em progresso")
		return false
	
	var player = _get_player()
	if not player:
		push_warning("[SAVE MANAGER] Player nao encontrado - save cancelado")
		save_failed.emit("Player not found")
		return false
	
	var scene_path = _get_current_scene_path()
	if not _validate_scene_path(scene_path):
		save_failed.emit("Invalid scene path")
		return false
	
	is_saving = true
	
	var player_stats = _extract_player_stats(player)
	var success = _write_save_to_database(scene_path, player.global_position, player_stats)
	
	is_saving = false
	
	if success:
		print("[SAVE MANAGER] Jogo salvo - Slot: ", current_slot, " Cena: ", scene_path)
		save_completed.emit(current_slot)
	else:
		push_error("[SAVE MANAGER] Falha ao salvar")
		save_failed.emit("Database write failed")
	
	return success

func load_game(slot: int) -> bool:
	if not _validate_slot(slot):
		load_failed.emit("Invalid slot")
		return false
	
	if not _validate_user_logged_in():
		load_failed.emit("User not logged in")
		return false
	
	if is_loading:
		push_warning("[SAVE MANAGER] Load ja em progresso")
		return false
	
	is_loading = true
	current_slot = slot
	
	if not _load_save_data_from_database(slot):
		is_loading = false
		push_error("[SAVE MANAGER] Falha ao carregar save do slot ", slot)
		load_failed.emit("Save data not found")
		return false
	
	var scene_path: String = save_data.get("scene_path", "")
	if not _validate_scene_path(scene_path):
		is_loading = false
		load_failed.emit("Invalid scene in save")
		return false
	
	print("[SAVE MANAGER] Carregando jogo - Slot: ", slot, " Cena: ", scene_path)
	
	_pause_game_systems()
	
	var load_success = await _load_scene_and_setup(scene_path)
	
	is_loading = false
	
	if load_success:
		print("[SAVE MANAGER] Jogo carregado com sucesso")
		load_completed.emit(slot)
	else:
		push_error("[SAVE MANAGER] Falha ao carregar jogo")
		load_failed.emit("Scene load failed")
		_return_to_title()
	
	return load_success

func save_file_exists(slot: int) -> bool:
	if not _validate_slot(slot):
		return false
	
	if not _validate_user_logged_in():
		return false
	
	var user_id = AccountManager.get_user_id()
	var query = "SELECT id FROM user_saves WHERE user_id = ? AND slot = ?;"
	DatabaseManager.db.query_with_bindings(query, [user_id, slot])
	
	return not DatabaseManager.db.query_result.is_empty()

func is_discovered_area(scene_path: String) -> bool:
	return discovered_areas.has(scene_path)

func get_discovered_area_count() -> int:
	return discovered_areas.size()

func get_current_slot() -> int:
	return current_slot

func _write_save_to_database(scene_path: String, position: Vector2, player_stats: Dictionary) -> bool:
	var user_id = AccountManager.get_user_id()
	var timestamp = Time.get_unix_time_from_system()
	
	var delete_query = "DELETE FROM user_saves WHERE user_id = ? AND slot = ?;"
	DatabaseManager.db.query_with_bindings(delete_query, [user_id, current_slot])
	
	var insert_query = """
	INSERT INTO user_saves (
		user_id, slot, scene_path, position_x, position_y,
		hp, max_hp, dash, double_jump, ground_slam, morph_roll,
		discovered_areas, persistent_data, created_at, updated_at
	)
	VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
	"""
	
	var areas_json = JSON.stringify(discovered_areas)
	var persistent_json = JSON.stringify(persistent_data)
	
	DatabaseManager.db.query_with_bindings(insert_query, [
		user_id, current_slot, scene_path,
		position.x, position.y,
		player_stats.hp, player_stats.max_hp,
		1 if player_stats.dash else 0,
		1 if player_stats.double_jump else 0,
		1 if player_stats.ground_slam else 0,
		1 if player_stats.morph_roll else 0,
		areas_json, persistent_json, timestamp, timestamp
	])
	
	return true

func _load_save_data_from_database(slot: int) -> bool:
	var user_id = AccountManager.get_user_id()
	var query = "SELECT * FROM user_saves WHERE user_id = ? AND slot = ?;"
	DatabaseManager.db.query_with_bindings(query, [user_id, slot])
	
	if DatabaseManager.db.query_result.is_empty():
		return false
	
	save_data = DatabaseManager.db.query_result[0]
	
	var json_areas = JSON.new()
	if json_areas.parse(save_data.get("discovered_areas", "[]")) == OK:
		var temp_array = json_areas.data
		discovered_areas.clear()
		for item in temp_array:
			if item is String:
				discovered_areas.append(item)
	else:
		discovered_areas.clear()
	
	var json_persistent = JSON.new()
	if json_persistent.parse(save_data.get("persistent_data", "{}")) == OK:
		persistent_data = json_persistent.data
	else:
		persistent_data = {}
	
	return true

func _load_scene_and_setup(scene_path: String) -> bool:
	if not SceneManager:
		push_error("[SAVE MANAGER] SceneManager nao encontrado")
		return false
	
	SceneManager.transition_scene(scene_path, "", Vector2.ZERO, "up")
	await SceneManager.new_scene_ready
	
	await _wait_for_scene_ready()
	
	if not await _setup_player():
		return false
	
	_show_game_huds()
	_on_scene_entered(scene_path)
	_resume_game_systems()
	
	return true

func _setup_player() -> bool:
	var player = await _wait_for_player(PLAYER_WAIT_TIMEOUT)
	
	if not player:
		push_error("[SAVE MANAGER] Player nao encontrado apos timeout")
		return false
	
	print("[SAVE MANAGER] ===== SETUP PLAYER DEBUG =====")
	print("[SAVE MANAGER] Save data completo: ", save_data)
	print("[SAVE MANAGER] HP no save: ", save_data.get("hp"), "/", save_data.get("max_hp"))
	print("[SAVE MANAGER] Position no save: (", save_data.get("position_x"), ", ", save_data.get("position_y"), ")")
	print("[SAVE MANAGER] Scene no save: ", save_data.get("scene_path"))
	
	player.max_hp = save_data.get("max_hp", 20)
	player.hp = save_data.get("hp", 20)
	player.dash = save_data.get("dash", 0) == 1
	player.double_jump = save_data.get("double_jump", 0) == 1
	player.ground_slam = save_data.get("ground_slam", 0) == 1
	player.morph_roll = save_data.get("morph_roll", 0) == 1
	
	print("[SAVE MANAGER] Player HP configurado: ", player.hp, "/", player.max_hp)
	print("[SAVE MANAGER] Player posição ANTES: ", player.global_position)
	
	await get_tree().process_frame
	
	var spawn_pos = Vector2(
		save_data.get("position_x", DEFAULT_SPAWN_POSITION.x),
		save_data.get("position_y", DEFAULT_SPAWN_POSITION.y)
	)
	
	print("[SAVE MANAGER] Spawn pos calculado: ", spawn_pos)
	
	player.global_position = spawn_pos
	
	print("[SAVE MANAGER] Player posição DEPOIS: ", player.global_position)
	print("[SAVE MANAGER] ===== FIM DEBUG =====")
	
	return true

func _wait_for_scene_ready() -> void:
	for i in range(60):
		await get_tree().process_frame
		
		if i % 10 == 0 and _get_player():
			return

func _wait_for_player(timeout_seconds: float) -> Player:
	var start_time = Time.get_ticks_msec()
	var timeout_ms = timeout_seconds * 1000
	
	while Time.get_ticks_msec() - start_time < timeout_ms:
		var player = _get_player()
		if player:
			return player
		await get_tree().process_frame
	
	return null

func _show_game_huds() -> void:
	var hud_configs = [
		{"name": "PlayerHub", "condition": true},
		{"name": "SpeedrunHub", "condition": SpeedrunTimer and SpeedrunTimer.is_running}
	]
	
	for config in hud_configs:
		if not config.condition:
			continue
		
		var hud = get_node_or_null("/root/" + config.name)
		if hud and "visible" in hud:
			hud.visible = true

func _pause_game_systems() -> void:
	if SpeedrunTimer and SpeedrunTimer.is_running:
		SpeedrunTimer.pause_run()

func _resume_game_systems() -> void:
	if SpeedrunTimer and SpeedrunTimer.is_running:
		SpeedrunTimer.resume_run()

func _on_scene_entered(scene_path: String) -> void:
	if scene_path.is_empty() or _is_menu_scene(scene_path):
		return
	
	if not is_loading and not discovered_areas.has(scene_path):
		discovered_areas.append(scene_path)
		print("[SAVE MANAGER] Nova area descoberta: ", scene_path, " (", discovered_areas.size(), " total)")
		
		if _get_player() and not is_loading and not is_saving:
			save_game()

func _connect_signals() -> void:
	if SceneManager:
		SceneManager.scene_entered.connect(_on_scene_entered)

func _validate_slot(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		push_error("[SAVE MANAGER] Slot invalido: ", slot)
		return false
	return true

func _validate_user_logged_in() -> bool:
	if not AccountManager or not AccountManager.is_logged_in:
		push_warning("[SAVE MANAGER] Usuario nao logado")
		return false
	return true

func _validate_scene_path(scene_path: String) -> bool:
	if scene_path.is_empty():
		return false
	
	if not ResourceLoader.exists(scene_path):
		push_error("[SAVE MANAGER] Cena nao existe: ", scene_path)
		return false
	
	return true

func _get_player() -> Player:
	return get_tree().get_first_node_in_group("Player") as Player

func _get_current_scene_path() -> String:
	var current_scene = get_tree().current_scene
	return current_scene.scene_file_path if current_scene else ""

func _is_menu_scene(scene_path: String) -> bool:
	var menu_keywords = ["title_screen", "auth/", "menu", "splash", "intro/"]
	for keyword in menu_keywords:
		if scene_path.contains(keyword):
			return true
	return false

func _reset_game_state() -> void:
	discovered_areas.clear()
	persistent_data.clear()
	save_data.clear()

func _get_default_player_stats() -> Dictionary:
	return {
		"hp": 20,
		"max_hp": 20,
		"dash": false,
		"double_jump": false,
		"ground_slam": false,
		"morph_roll": false
	}

func _extract_player_stats(player: Player) -> Dictionary:
	return {
		"hp": player.hp,
		"max_hp": player.max_hp,
		"dash": player.dash,
		"double_jump": player.double_jump,
		"ground_slam": player.ground_slam,
		"morph_roll": player.morph_roll
	}

func _return_to_title() -> void:
	print("[SAVE MANAGER] Retornando ao title screen")
	get_tree().change_scene_to_file("res://title_screen/title_screen.tscn")


#region Configuration Settings

func save_configuration() -> void:
	var config := ConfigFile.new()
	config.set_value( "audio", "music", AudioServer.get_bus_volume_linear( 2 ) )
	config.set_value( "audio", "sfx", AudioServer.get_bus_volume_linear( 3 ) )
	config.set_value( "audio", "ui", AudioServer.get_bus_volume_linear( 4 ) )
	config.save( CONFIG_FILE_PATH )
	pass
	
func load_configuration() -> void:
	var config := ConfigFile.new()
	var err = config.load( CONFIG_FILE_PATH )
	
	if err != OK:
		AudioServer.set_bus_volume_linear( 2, 0.8 )
		AudioServer.set_bus_volume_linear( 3, 1.0 ) 
		AudioServer.set_bus_volume_linear( 4, 1.0 ) 
		save_configuration()
		return
		
	AudioServer.set_bus_volume_linear( 2, config.get_value( "audio", "music", 0.8 ) )
	AudioServer.set_bus_volume_linear( 3, config.get_value( "audio", "sfx", 1.0 ) )
	AudioServer.set_bus_volume_linear( 4, config.get_value( "audio", "ui", 1.0 ) )

	pass

#endregion
