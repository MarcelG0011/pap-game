extends Node

var is_locked: bool = false
var is_enabled: bool = true
var inactivity_timeout: float = 120.0
var last_input_time: float = 0.0

var lockscreen: CanvasLayer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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

func is_lockscreen_active() -> bool:
	return is_locked and lockscreen != null

func activate_lockscreen() -> void:
	if is_locked:
		return
		
	is_locked = true
	
	# Autosave antes do bloqueio
	if get_tree().get_first_node_in_group("Player"):
		if has_node("/root/AutosaveManager"):
			get_node("/root/AutosaveManager").trigger_autosave("inatividade")
	
	get_tree().paused = true
	
	var lockscreen_scene = load("res://auth/ui/lockscreen.tscn")
	if not lockscreen_scene:
		push_error("[INACTIVITY] Cena lockscreen não encontrada no caminho especificado!")
		return
		
	lockscreen = lockscreen_scene.instantiate()
	get_tree().root.add_child(lockscreen)
	
	# Conexão segura do sinal
	if lockscreen.has_signal("unlock_requested"):
		lockscreen.unlock_requested.connect(_on_unlock_requested)
	
	print("[INACTIVITY] Lockscreen Ativado")

func _on_unlock_requested(password: String) -> void:
	if not AccountManager.is_logged_in:
		return

	# Obtemos o username do utilizador que está atualmente logado
	var username = AccountManager.get_username()
	
	# Agora a função verify_password já existe no AccountManager!
	if AccountManager.verify_password(username, password):
		print("[INACTIVITY] Desbloqueio autorizado.")
		_unlock_screen()
	else:
		print("[INACTIVITY] Senha falhou.")
		if lockscreen:
			lockscreen.show_error("Senha Incorreta")

func _unlock_screen() -> void:
	if lockscreen:
		lockscreen.close()
		lockscreen = null
	
	is_locked = false
	last_input_time = Time.get_ticks_msec() / 1000.0
	
	# Só despausa o jogo se o Menu de Pausa não estiver aberto
	var pause_menu = get_tree().get_first_node_in_group("PauseMenu")
	if pause_menu and pause_menu.visible:
		get_tree().paused = true
		print("[INACTIVITY] Desbloqueado, mas mantendo pausa devido ao Menu.")
	else:
		get_tree().paused = false
		print("[INACTIVITY] Desbloqueado e Retomado.")
	

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

func create_default_settings(user_id: int) -> void:
	var timestamp = Time.get_unix_time_from_system()
	
	var query = """
	INSERT INTO user_settings (user_id, inactivity_enabled, inactivity_timeout, autosave_enabled, autosave_interval, updated_at)
	VALUES (?, 1, 120, 1, 180, ?);
	"""
	DatabaseManager.db.query_with_bindings(query, [user_id, timestamp])
	

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
	

func set_enabled(enabled: bool) -> void:
	is_enabled = enabled
	save_settings()

func set_timeout(minutes: float) -> void:
	inactivity_timeout = minutes * 60
	save_settings()
