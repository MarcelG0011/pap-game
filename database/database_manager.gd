# res://00_global/database_manager.gd
extends Node

var db: SQLite = null
var db_path: String = "user://game.db"

func _ready() -> void:
	open_database()
	create_tables()

func open_database() -> void:
	db = SQLite.new()
	db.path = db_path
	db.open_db()

func create_tables() -> void:
	# Tabela de usuarios
	var users_table = """
	CREATE TABLE IF NOT EXISTS users (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		username TEXT UNIQUE NOT NULL,
		email TEXT UNIQUE NOT NULL,
		password_hash TEXT NOT NULL,
		security_question TEXT,
		security_answer_hash TEXT,
		created_at INTEGER NOT NULL,
		last_login INTEGER
	);
	"""
	db.query(users_table)
	
	# Tabela de moedas
	var currency_table = """
	CREATE TABLE IF NOT EXISTS user_currency (
		user_id INTEGER PRIMARY KEY,
		soul INTEGER DEFAULT 0,
		gems INTEGER DEFAULT 0,
		updated_at INTEGER NOT NULL,
		FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
	);
	"""
	db.query(currency_table)
	
	# Tabela de saves
	var saves_table = """
	CREATE TABLE IF NOT EXISTS user_saves (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		user_id INTEGER NOT NULL,
		slot INTEGER NOT NULL,
		scene_path TEXT NOT NULL,
		position_x REAL NOT NULL,
		position_y REAL NOT NULL,
		hp INTEGER NOT NULL,
		max_hp INTEGER NOT NULL,
		dash INTEGER DEFAULT 0,
		double_jump INTEGER DEFAULT 0,
		ground_slam INTEGER DEFAULT 0,
		morph_roll INTEGER DEFAULT 0,
		discovered_areas TEXT,
		persistent_data TEXT,
		created_at INTEGER NOT NULL,
		updated_at INTEGER NOT NULL,
		UNIQUE(user_id, slot),
		FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
	);
	"""
	db.query(saves_table)
	
	# Tabela de cosmeticos
	var cosmetics_table = """
	CREATE TABLE IF NOT EXISTS user_cosmetics (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		user_id INTEGER NOT NULL,
		cosmetic_id TEXT NOT NULL,
		unlocked_at INTEGER NOT NULL,
		UNIQUE(user_id, cosmetic_id),
		FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
	);
	"""
	db.query(cosmetics_table)
	
	# Tabela de upgrades
	var upgrades_table = """
	CREATE TABLE IF NOT EXISTS user_upgrades (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		user_id INTEGER NOT NULL,
		upgrade_id TEXT NOT NULL,
		level INTEGER DEFAULT 1,
		purchased_at INTEGER NOT NULL,
		FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
	);
	"""
	db.query(upgrades_table)
	
	# Tabela de leaderboard
	var leaderboard_table = """
	CREATE TABLE IF NOT EXISTS leaderboard (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		user_id INTEGER NOT NULL,
		username TEXT NOT NULL,
		time_ms INTEGER NOT NULL,
		completed_at INTEGER NOT NULL,
		FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
	);
	"""
	db.query(leaderboard_table)
	
	# Tabela de sessoes
	var sessions_table = """
	CREATE TABLE IF NOT EXISTS sessions (
		user_id INTEGER PRIMARY KEY,
		session_token TEXT NOT NULL,
		expires_at INTEGER NOT NULL,
		FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
	);
	"""
	db.query(sessions_table)
	
	# Tabela de configuracoes de usuario
	var user_settings_table = """
	CREATE TABLE IF NOT EXISTS user_settings (
		user_id INTEGER PRIMARY KEY,
		inactivity_enabled INTEGER DEFAULT 1,
		inactivity_timeout INTEGER DEFAULT 120,
		autosave_enabled INTEGER DEFAULT 1,
		autosave_interval INTEGER DEFAULT 180,
		updated_at INTEGER NOT NULL,
		FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
	);
	"""
	db.query(user_settings_table)
	
	# Tabela para tutoriais vistos
	var create_user_tutorials = """
	CREATE TABLE IF NOT EXISTS user_tutorials (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		user_id INTEGER NOT NULL,
		tutorial_id TEXT NOT NULL,
		seen_at INTEGER NOT NULL,
		UNIQUE(user_id, tutorial_id),
		FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
	);
	"""
	db.query(create_user_tutorials)

func create_index() -> void:
	var idx_leaderboard = """ 
	CREATE INDEX IF NOT EXISTS idx_leaderboard_time 
		ON leaderboard(time_ms ASC);
	"""
	db.query(idx_leaderboard)

# ========================================
# FUNÇÕES DE USUÁRIO
# ========================================

# Busca usuário por username
func get_user_by_username(username: String) -> Dictionary:
	var query = "SELECT * FROM users WHERE username = ?;"
	db.query_with_bindings(query, [username])
	
	if db.query_result.is_empty():
		return {}
	
	return db.query_result[0]

# Busca usuário por email
func get_user_by_email(email: String) -> Dictionary:
	var query = "SELECT * FROM users WHERE email = ?;"
	db.query_with_bindings(query, [email])
	
	if db.query_result.is_empty():
		return {}
	
	return db.query_result[0]

# Busca usuário por ID
func get_user_by_id(user_id: int) -> Dictionary:
	var query = "SELECT * FROM users WHERE id = ?;"
	db.query_with_bindings(query, [user_id])
	
	if db.query_result.is_empty():
		return {}
	
	return db.query_result[0]

# Atualiza password
func update_password(user_id: int, password_hash: String) -> bool:
	var query = "UPDATE users SET password_hash = ? WHERE id = ?;"
	db.query_with_bindings(query, [password_hash, user_id])
	print("[DATABASE] Password atualizada para user_id: ", user_id)
	return true

# ========================================
# FUNÇÕES DE TUTORIAIS
# ========================================

# Verifica se tutorial foi visto
func has_seen_tutorial(user_id: int, tutorial_id: String) -> bool:
	var query = "SELECT id FROM user_tutorials WHERE user_id = ? AND tutorial_id = ?;"
	db.query_with_bindings(query, [user_id, tutorial_id])
	return not db.query_result.is_empty()

# Marca tutorial como visto
func mark_tutorial_as_seen(user_id: int, tutorial_id: String) -> void:
	var timestamp = Time.get_unix_time_from_system()
	var query = """
	INSERT OR IGNORE INTO user_tutorials (user_id, tutorial_id, seen_at)
	VALUES (?, ?, ?);
	"""
	db.query_with_bindings(query, [user_id, tutorial_id, timestamp])
	print("[DATABASE] Tutorial '", tutorial_id, "' marcado como visto")

# Reseta tutoriais (para testes)
func reset_tutorials(user_id: int) -> void:
	var query = "DELETE FROM user_tutorials WHERE user_id = ?;"
	db.query_with_bindings(query, [user_id])
	print("[DATABASE] Tutoriais resetados para user_id: ", user_id)

# ========================================
# FECHAR DATABASE
# ========================================

func close_database() -> void:
	if db:
		db.close_db()
