extends Node

signal soul_changed(new_amount: int)
signal gems_changed(new_amount: int)

var soul: int = 0
var gems: int = 0

func _ready() -> void:
	print("[CURRENCY] Sistema de moedas inicializado")
	
	# Conecta ao login para carregar moedas
	if AccountManager:
		AccountManager.login_successful.connect(_on_login_successful)
		AccountManager.logout_complete.connect(_on_logout_complete)

func _on_login_successful(_username: String) -> void:
	load_currency()

func _on_logout_complete() -> void:
	soul = 0
	gems = 0
	soul_changed.emit(0)
	gems_changed.emit(0)

# SOUL

func add_soul(amount: int) -> void:
	soul += amount
	soul_changed.emit(soul)
	save_currency()
	print("[CURRENCY] +", amount, " Soul. Total: ", soul)

func remove_soul(amount: int) -> bool:
	if soul >= amount:
		soul -= amount
		soul_changed.emit(soul)
		save_currency()
		print("[CURRENCY] -", amount, " Soul. Total: ", soul)
		return true
	else:
		print("[CURRENCY] Soul insuficiente! Tem: ", soul, " Precisa: ", amount)
		return false

func has_soul(amount: int) -> bool:
	return soul >= amount

func get_soul() -> int:
	return soul

# GEMS

func add_gems(amount: int) -> void:
	gems += amount
	gems_changed.emit(gems)
	save_currency()
	print("[CURRENCY] +", amount, " Gems. Total: ", gems)

func remove_gems(amount: int) -> bool:
	if gems >= amount:
		gems -= amount
		gems_changed.emit(gems)
		save_currency()
		print("[CURRENCY] -", amount, " Gems. Total: ", gems)
		return true
	else:
		print("[CURRENCY] Gems insuficientes! Tem: ", gems, " Precisa: ", amount)
		return false

func has_gems(amount: int) -> bool:
	return gems >= amount

func get_gems() -> int:
	return gems

# DATABASE

func load_currency() -> void:
	if not AccountManager.is_logged_in:
		print("[CURRENCY] Nenhum usuario logado")
		return
	
	var user_id = AccountManager.get_user_id()
	
	var query = "SELECT soul, gems FROM user_currency WHERE user_id = ?;"
	DatabaseManager.db.query_with_bindings(query, [user_id])
	
	if DatabaseManager.db.query_result.is_empty():
		# Usuario novo, cria entrada
		create_currency_entry(user_id)
	else:
		var data = DatabaseManager.db.query_result[0]
		soul = data["soul"]
		gems = data["gems"]
		
		print("[CURRENCY] Moedas carregadas - Soul: ", soul, " Gems: ", gems)
		
		soul_changed.emit(soul)
		gems_changed.emit(gems)

func create_currency_entry(user_id: int) -> void:
	var timestamp = Time.get_unix_time_from_system()
	
	var query = """
	INSERT INTO user_currency (user_id, soul, gems, updated_at)
	VALUES (?, 0, 0, ?);
	"""
	DatabaseManager.db.query_with_bindings(query, [user_id, timestamp])
	
	soul = 0
	gems = 0
	print("[CURRENCY] Entrada de moedas criada para user_id: ", user_id)

func save_currency() -> void:
	if not AccountManager.is_logged_in:
		return
	
	var user_id = AccountManager.get_user_id()
	var timestamp = Time.get_unix_time_from_system()
	
	var query = """
	UPDATE user_currency 
	SET soul = ?, gems = ?, updated_at = ?
	WHERE user_id = ?;
	"""
	DatabaseManager.db.query_with_bindings(query, [soul, gems, timestamp, user_id])

func reset_currency() -> void:
	soul = 0
	gems = 0
	soul_changed.emit(soul)
	gems_changed.emit(gems)
	save_currency()
	print("[CURRENCY] Moedas resetadas")
