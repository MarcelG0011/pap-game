extends Node

signal login_successful(username: String)
signal login_failed(reason: String)
signal signup_successful(username: String)
signal signup_failed(reason: String)
signal logout_complete()

var current_user: Dictionary = {}
var is_logged_in: bool = false

func _ready() -> void:
	print("[ACCOUNT MANAGER] Sistema de contas inicializado")
	check_saved_session()

# SIGNUP

func signup(username: String, email: String, password: String, confirm_password: String) -> void:
	# Valida dados
	var validation_error = validate_signup(username, email, password, confirm_password)
	
	if validation_error != "":
		signup_failed.emit(validation_error)
		return
	
	# Cria conta
	var success = create_account(username, email, password)
	
	if success:
		signup_successful.emit(username)
		
		# Auto-login apos criar conta
		login(username, password, true)
	else:
		signup_failed.emit("Erro ao criar conta. Username ou email ja existe.")

func create_account(username: String, email: String, password: String) -> bool:
	var password_hash = hash_password(password)
	var timestamp = Time.get_unix_time_from_system()
	
	var query = """
	INSERT INTO users (username, email, password_hash, created_at)
	VALUES (?, ?, ?, ?);
	"""
	
	DatabaseManager.db.query_with_bindings(query, [username, email, password_hash, timestamp])
	
	# Verifica se inseriu com sucesso
	var get_id = "SELECT id FROM users WHERE username = ?;"
	DatabaseManager.db.query_with_bindings(get_id, [username])
	
	if not DatabaseManager.db.query_result.is_empty():
		var user_id = DatabaseManager.db.query_result[0]["id"]
		
		print("[ACCOUNT] Conta criada: ", username, " (ID: ", user_id, ")")
		
		# Cria entrada de moedas
		var currency_query = """
		INSERT INTO user_currency (user_id, soul, gems, updated_at)
		VALUES (?, 0, 0, ?);
		"""
		DatabaseManager.db.query_with_bindings(currency_query, [user_id, timestamp])
		
		return true
	else:
		print("[ACCOUNT] Erro ao criar conta")
		return false

# LOGIN

func login(username_or_email: String, password: String, remember: bool = false) -> bool:
	var password_hash = hash_password(password)
	
	var query = """
	SELECT * FROM users 
	WHERE (username = ? OR email = ?) AND password_hash = ?;
	"""
	
	DatabaseManager.db.query_with_bindings(query, [username_or_email, username_or_email, password_hash])
	
	if DatabaseManager.db.query_result.is_empty():
		login_failed.emit("Usuario ou senha incorretos")
		return false
	
	var user = DatabaseManager.db.query_result[0]
	current_user = user
	is_logged_in = true
	
	# Atualiza last_login
	var update_login = "UPDATE users SET last_login = ? WHERE id = ?;"
	DatabaseManager.db.query_with_bindings(update_login, [Time.get_unix_time_from_system(), user["id"]])
	
	# Remember me
	if remember:
		save_session(user["id"])
	
	login_successful.emit(user["username"])
	print("[ACCOUNT] Login bem-sucedido: ", user["username"])
	return true

func logout() -> void:
	if is_logged_in:
		clear_session()
	
	current_user.clear()
	is_logged_in = false
	logout_complete.emit()
	print("[ACCOUNT] Logout completo")

func get_username() -> String:
	return current_user.get("username", "")

func get_user_id() -> int:
	return current_user.get("id", -1)

func get_email() -> String:
	return current_user.get("email", "")

# SESSIONS

func save_session(user_id: int) -> void:
	var session_token = generate_session_token()
	var expires_at = Time.get_unix_time_from_system() + (30 * 24 * 60 * 60)
	
	var delete_old = "DELETE FROM sessions WHERE user_id = ?;"
	DatabaseManager.db.query_with_bindings(delete_old, [user_id])
	
	var insert_session = """
	INSERT INTO sessions (user_id, session_token, expires_at)
	VALUES (?, ?, ?);
	"""
	DatabaseManager.db.query_with_bindings(insert_session, [user_id, session_token, expires_at])
	
	print("[ACCOUNT] Sessao salva para user_id: ", user_id)

func check_saved_session() -> void:
	var current_time = Time.get_unix_time_from_system()
	
	var cleanup = "DELETE FROM sessions WHERE expires_at < ?;"
	DatabaseManager.db.query_with_bindings(cleanup, [current_time])
	
	var query = """
	SELECT users.* FROM sessions
	JOIN users ON sessions.user_id = users.id
	WHERE sessions.expires_at > ?
	LIMIT 1;
	"""
	DatabaseManager.db.query_with_bindings(query, [current_time])
	
	if not DatabaseManager.db.query_result.is_empty():
		var user = DatabaseManager.db.query_result[0]
		current_user = user
		is_logged_in = true
		print("[ACCOUNT] Sessao restaurada: ", user["username"])

func clear_session() -> void:
	if current_user.has("id"):
		var delete_session = "DELETE FROM sessions WHERE user_id = ?;"
		DatabaseManager.db.query_with_bindings(delete_session, [current_user["id"]])

func generate_session_token() -> String:
	var chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var token = ""
	for i in range(32):
		token += chars[randi() % chars.length()]
	return token

# SECURITY

func set_security_question(question: String, answer: String) -> void:
	if not is_logged_in:
		return
	
	var answer_hash = hash_password(answer.to_lower())
	
	var query = """
	UPDATE users 
	SET security_question = ?, security_answer_hash = ?
	WHERE id = ?;
	"""
	DatabaseManager.db.query_with_bindings(query, [question, answer_hash, current_user["id"]])
	
	print("[ACCOUNT] Pergunta de seguranca configurada")

func verify_security_answer(username: String, answer: String) -> bool:
	var answer_hash = hash_password(answer.to_lower())
	
	var query = """
	SELECT * FROM users 
	WHERE username = ? AND security_answer_hash = ?;
	"""
	DatabaseManager.db.query_with_bindings(query, [username, answer_hash])
	
	return not DatabaseManager.db.query_result.is_empty()

func reset_password(username: String, new_password: String) -> bool:
	var password_hash = hash_password(new_password)
	
	var query = "UPDATE users SET password_hash = ? WHERE username = ?;"
	DatabaseManager.db.query_with_bindings(query, [password_hash, username])
	
	print("[ACCOUNT] Senha resetada para: ", username)
	return true

func get_security_question(username: String) -> String:
	var query = "SELECT security_question FROM users WHERE username = ?;"
	DatabaseManager.db.query_with_bindings(query, [username])
	
	if DatabaseManager.db.query_result.is_empty():
		return ""
	
	return DatabaseManager.db.query_result[0].get("security_question", "")

# VALIDATION

func validate_signup(username: String, email: String, password: String, confirm_password: String) -> String:
	if username.length() < 3 or username.length() > 20:
		return "Username deve ter entre 3 e 20 caracteres"
	
	if not is_valid_email(email):
		return "Email invalido"
	
	if password.length() < 6:
		return "Senha deve ter no minimo 6 caracteres"
	
	if password != confirm_password:
		return "Senhas nao coincidem"
	
	var check_username = "SELECT id FROM users WHERE username = ?;"
	DatabaseManager.db.query_with_bindings(check_username, [username])
	if not DatabaseManager.db.query_result.is_empty():
		return "Username ja existe"
	
	var check_email = "SELECT id FROM users WHERE email = ?;"
	DatabaseManager.db.query_with_bindings(check_email, [email])
	if not DatabaseManager.db.query_result.is_empty():
		return "Email ja cadastrado"
	
	return ""

func is_valid_email(email: String) -> bool:
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
	return regex.search(email) != null

func hash_password(password: String) -> String:
	return password.sha256_text()
