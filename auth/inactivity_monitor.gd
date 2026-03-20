extends Node

var is_locked: bool = false
var is_enabled: bool = true
var inactivity_timeout: float = 120.0
var last_input_time: float = 0.0

var lockscreen_instance: Node = null

func _ready() -> void:
	print("[INACTIVITY] Sistema inicializado")
	
	last_input_time = Time.get_ticks_msec() / 1000.0
	
	if AccountManager:
		AccountManager.login_successful.connect(func(_u): load_settings())

func _input(event: InputEvent) -> void:
	if is_locked:
		return
	
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		last_input_time = Time.get_ticks_msec() / 1000.0

func _process(_delta: float) -> void:
	if is_locked or not is_enabled or not AccountManager.is_logged_in:
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var inactive_time = current_time - last_input_time
	
	if inactive_time >= inactivity_timeout:
		activate_lockscreen()

func activate_lockscreen() -> void:
	if is_locked:
		return
	
	print("[INACTIVITY] Ativando lockscreen...")
	
	is_locked = true
	
	if get_tree().get_first_node_in_group("Player"):
		AutosaveManager.trigger_autosave("inatividade")
		await get_tree().create_timer(0.5).timeout
	
	get_tree().paused = true
	
	var lockscreen = load("res://auth/ui/lockscreen.tscn").instantiate()
	get_tree().root.add_child(lockscreen)
	lockscreen_instance = lockscreen
	
	lockscreen.unlock_requested.connect(_on_unlock_requested)

func _on_unlock_requested(password: String) -> void:
	var password_hash = AccountManager.hash_password(password)
	var correct_hash = AccountManager.current_user.get("password_hash", "")
	
	if password_hash == correct_hash:
		deactivate_lockscreen()
	else:
		print("[INACTIVITY] Senha incorreta")

func deactivate_lockscreen() -> void:
	print("[INACTIVITY] Desbloqueando...")
	
	is_locked = false
	last_input_time = Time.get_ticks_msec() / 1000.0
	
	get_tree().paused = false
	
	if lockscreen_instance:
		lockscreen_instance.queue_free()
		lockscreen_instance = null

func reset() -> void:
	print("[INACTIVITY] Resetando monitor...")
	
	is_locked = false
	is_enabled = false
	last_input_time = Time.get_ticks_msec() / 1000.0
	
	if lockscreen_instance:
		lockscreen_instance.queue_free()
		lockscreen_instance = null
	
	if get_tree().paused:
		get_tree().paused = false
	
	print("[INACTIVITY] Monitor resetado")

func load_settings() -> void:
	if not AccountManager.is_logged_in:
		return
	
	var user_id = AccountManager.get_user_id()
	
	var query = "SELECT * FROM user_settings WHERE user_id = ?;"
	DatabaseManager.db.query_with_bindings(query, [user_id])
	
	if DatabaseManager.db.query_result.is_empty():
		create_default_settings(user_id)
	else:
		var settings = DatabaseManager.db.query_result[0]
		is_enabled = settings["inactivity_enabled"] == 1
		inactivity_timeout = settings["inactivity_timeout"]
		print("[INACTIVITY] Configuracoes carregadas")

func create_default_settings(user_id: int) -> void:
	var timestamp = Time.get_unix_time_from_system()
	
	var query = """
	INSERT INTO user_settings (user_id, inactivity_enabled, inactivity_timeout, autosave_enabled, autosave_interval, updated_at)
	VALUES (?, 1, 120, 1, 180, ?);
	"""
	DatabaseManager.db.query_with_bindings(query, [user_id, timestamp])
	
	print("[INACTIVITY] Configuracoes padrao criadas")

func save_settings() -> void:
	if not AccountManager.is_logged_in:
		return
	
	var user_id = AccountManager.get_user_id()
	var timestamp = Time.get_unix_time_from_system()
	
	var query = """
	UPDATE user_settings
	SET inactivity_enabled = ?, inactivity_timeout = ?, updated_at = ?
	WHERE user_id = ?;
	"""
	DatabaseManager.db.query_with_bindings(query, [
		1 if is_enabled else 0,
		int(inactivity_timeout),
		timestamp,
		user_id
	])
	
	print("[INACTIVITY] Configuracoes salvas")

func set_enabled(enabled: bool) -> void:
	is_enabled = enabled
	save_settings()
	print("[INACTIVITY] Monitor ", "ativado" if enabled else "desativado")

func set_timeout(minutes: float) -> void:
	inactivity_timeout = minutes * 60
	save_settings()
	print("[INACTIVITY] Timeout: ", minutes, " minutos")
