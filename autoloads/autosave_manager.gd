extends Node

var autosave_enabled: bool = true
var autosave_interval: float = 180.0
var time_since_last_save: float = 0.0
var last_save_timestamp: int = 0

signal autosave_triggered(reason: String)

func _ready() -> void:
	print("[AUTOSAVE] Sistema inicializado")
	
	if SceneManager:
		SceneManager.scene_entered.connect(_on_scene_changed)
	
	if SpeedrunTimer:
		SpeedrunTimer.checkpoint_reached.connect(_on_checkpoint_reached)
	
	if AccountManager:
		AccountManager.login_successful.connect(func(_u): load_settings())

func _process(delta: float) -> void:
	if not autosave_enabled:
		return
	
	if not AccountManager.is_logged_in:
		return
	
	if not get_tree().get_first_node_in_group("Player"):
		return
	
	time_since_last_save += delta
	
	if time_since_last_save >= autosave_interval:
		trigger_autosave("intervalo de tempo")

func trigger_autosave(reason: String) -> void:
	if not autosave_enabled:
		return
	
	print("[AUTOSAVE] Tentando salvar - Razao: ", reason)
	
	var success = SaveManager.save_game()
	
	if success:
		time_since_last_save = 0.0
		last_save_timestamp = Time.get_unix_time_from_system()
		autosave_triggered.emit(reason)
		print("[AUTOSAVE] Autosave completo!")
	else:
		print("[AUTOSAVE] Autosave falhou")

func _on_scene_changed(scene_path: String) -> void:
	if scene_path.is_empty():
		return
	
	if scene_path.contains("title_screen") or scene_path.contains("auth/"):
		return
	
	# Espera player estar pronto
	await get_tree().create_timer(0.5).timeout
	
	if get_tree().get_first_node_in_group("Player"):
		trigger_autosave("mudanca de area")
	else:
		print("[AUTOSAVE] Player nao encontrado, autosave cancelado")

func _on_checkpoint_reached(_checkpoint_name: String, _time_ms: int) -> void:
	trigger_autosave("checkpoint alcancado")

func load_settings() -> void:
	if not AccountManager.is_logged_in:
		return
	
	var user_id = AccountManager.get_user_id()
	
	var query = "SELECT * FROM user_settings WHERE user_id = ?;"
	DatabaseManager.db.query_with_bindings(query, [user_id])
	
	if not DatabaseManager.db.query_result.is_empty():
		var settings = DatabaseManager.db.query_result[0]
		autosave_enabled = settings["autosave_enabled"] == 1
		autosave_interval = float(settings["autosave_interval"])
		print("[AUTOSAVE] Configuracoes carregadas - Intervalo: ", autosave_interval, "s")

func save_settings() -> void:
	if not AccountManager.is_logged_in:
		return
	
	var user_id = AccountManager.get_user_id()
	var timestamp = Time.get_unix_time_from_system()
	
	var query = """
	UPDATE user_settings
	SET autosave_enabled = ?, autosave_interval = ?, updated_at = ?
	WHERE user_id = ?;
	"""
	DatabaseManager.db.query_with_bindings(query, [
		1 if autosave_enabled else 0,
		int(autosave_interval),
		timestamp,
		user_id
	])
	
	print("[AUTOSAVE] Configuracoes salvas")

func set_autosave_enabled(enabled: bool) -> void:
	autosave_enabled = enabled
	save_settings()
	print("[AUTOSAVE] Autosave ", "ativado" if enabled else "desativado")

func set_autosave_interval(minutes: float) -> void:
	autosave_interval = minutes * 60.0
	save_settings()
	print("[AUTOSAVE] Intervalo de autosave: ", minutes, " minutos")

func force_autosave() -> void:
	trigger_autosave("manual/forcado")
