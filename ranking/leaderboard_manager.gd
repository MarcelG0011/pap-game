extends Node

signal leaderboard_updated
signal score_submitted(rank: int, total_entries: int)

const MAX_LOCAL_ENTRIES = 100

var player_name: String = "Player"

func _ready() -> void:
	print("[LEADERBOARD] Sistema inicializado")
	
	if AccountManager:
		AccountManager.login_successful.connect(func(_u): update_player_name())
	
	update_player_name()

func update_player_name() -> void:
	if AccountManager.is_logged_in:
		player_name = AccountManager.get_username()
		print("[LEADERBOARD] Nome do jogador: ", player_name)
	else:
		player_name = "Guest"

func submit_score(time_ms: int, checkpoints: Dictionary = {}) -> void:
	if not AccountManager.is_logged_in:
		print("[LEADERBOARD] Usuario nao logado, score nao salvo")
		return
	
	var user_id = AccountManager.get_user_id()
	var username = AccountManager.get_username()
	var timestamp = Time.get_unix_time_from_system()
	
	var query = """
	INSERT INTO leaderboard (user_id, username, time_ms, completed_at)
	VALUES (?, ?, ?, ?);
	"""
	DatabaseManager.db.query_with_bindings(query, [user_id, username, time_ms, timestamp])
	
	var rank = get_player_rank(time_ms)
	
	score_submitted.emit(rank, get_total_entries())
	leaderboard_updated.emit()
	
	print("[LEADERBOARD] Score submetido! Rank: #", rank, " Tempo: ", time_ms, "ms")

func get_top_entries(count: int = 10) -> Array:
	var query = """
	SELECT username, time_ms, completed_at
	FROM leaderboard
	ORDER BY time_ms ASC
	LIMIT ?;
	"""
	DatabaseManager.db.query_with_bindings(query, [count])
	
	return DatabaseManager.db.query_result

func get_player_best_time() -> int:
	if not AccountManager.is_logged_in:
		return -1
	
	var user_id = AccountManager.get_user_id()
	
	var query = """
	SELECT MIN(time_ms) as best_time
	FROM leaderboard
	WHERE user_id = ?;
	"""
	DatabaseManager.db.query_with_bindings(query, [user_id])
	
	if not DatabaseManager.db.query_result.is_empty():
		var result = DatabaseManager.db.query_result[0]["best_time"]
		if result != null:
			return result
	
	return -1

func get_player_rank(time_ms: int) -> int:
	var query = """
	SELECT COUNT(*) + 1 as rank
	FROM leaderboard
	WHERE time_ms < ?;
	"""
	DatabaseManager.db.query_with_bindings(query, [time_ms])
	
	if not DatabaseManager.db.query_result.is_empty():
		return DatabaseManager.db.query_result[0]["rank"]
	
	return 1

func get_total_entries() -> int:
	var query = "SELECT COUNT(*) as total FROM leaderboard;"
	DatabaseManager.db.query(query)
	
	if not DatabaseManager.db.query_result.is_empty():
		return DatabaseManager.db.query_result[0]["total"]
	
	return 0

func clear_leaderboard() -> void:
	DatabaseManager.db.query("DELETE FROM leaderboard;")
	leaderboard_updated.emit()
	print("[LEADERBOARD] Ranking limpo!")

func set_player_name(new_name: String) -> void:
	player_name = new_name.strip_edges()
	if player_name.is_empty():
		player_name = "Player"
	print("[LEADERBOARD] Nome do jogador: ", player_name)

func get_player_name() -> String:
	return player_name
