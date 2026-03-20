extends Node

var db: SQLite = null
var db_path: String = "user://game.db"

func _ready() -> void:
	print("[DATABASE] Inicializando banco de dados...")
	open_database()
	create_tables()
	print("[DATABASE] Banco de dados pronto!")

func open_database() -> void:
	db = SQLite.new()
	db.path = db_path
	db.open_db()
	print("[DATABASE] Banco aberto em: ", db_path)

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
	
	print("[DATABASE] Tabelas criadas/verificadas")

func close_database() -> void:
	if db:
		db.close_db()
		print("[DATABASE] Banco fechado")
