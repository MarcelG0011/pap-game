extends Node

signal time_updated(time_ms: int)
signal run_completed(time_ms: int)
signal checkpoint_reached(checkpoint_name: String, time_ms: int)

var is_running: bool = false
var start_time: int = 0
var elapsed_time: int = 0
var accumulated_pause_time: int = 0
var pause_start_time: int = 0
var is_paused: bool = false

var checkpoints: Dictionary = {}

func _ready() -> void:
	print("[SPEEDRUN TIMER] Sistema inicializado")

func _process(_delta: float) -> void:
	if is_running and not is_paused:
		elapsed_time = Time.get_ticks_msec() - start_time - accumulated_pause_time
		time_updated.emit(elapsed_time)

func start_run() -> void:
	is_running = true
	is_paused = false
	start_time = Time.get_ticks_msec()
	elapsed_time = 0
	accumulated_pause_time = 0
	checkpoints.clear()
	
	print("[SPEEDRUN TIMER] Run iniciada!")

func pause_run() -> void:
	if is_running and not is_paused:
		is_paused = true
		pause_start_time = Time.get_ticks_msec()
		print("[SPEEDRUN TIMER] Pausada")

func resume_run() -> void:
	if is_running and is_paused:
		is_paused = false
		accumulated_pause_time += Time.get_ticks_msec() - pause_start_time
		print("[SPEEDRUN TIMER] Retomada")

func complete_run() -> void:
	if not is_running:
		return
	
	is_running = false
	is_paused = false
	var final_time = elapsed_time
	
	print("[SPEEDRUN TIMER] Run completada! Tempo: ", format_time(final_time))
	run_completed.emit(final_time)
	
	# Salva no ranking
	LeaderboardManager.submit_score(final_time, checkpoints)

func cancel_run() -> void:
	if not is_running:
		return
	
	is_running = false
	is_paused = false
	elapsed_time = 0
	checkpoints.clear()
	print("[SPEEDRUN TIMER] Run cancelada")

func add_checkpoint(checkpoint_name: String) -> void:
	if not is_running:
		return
	
	checkpoints[checkpoint_name] = elapsed_time
	checkpoint_reached.emit(checkpoint_name, elapsed_time)
	print("[SPEEDRUN TIMER] Checkpoint: ", checkpoint_name, " - ", format_time(elapsed_time))

func format_time(time_ms: int) -> String:
	var total_seconds = int(time_ms / 1000.0)
	var hours = int(total_seconds / 3600.0)
	var minutes = int((total_seconds % 3600) / 60.0)
	var seconds = int(total_seconds % 60)
	var ms = int((time_ms % 1000) / 10.0)
	
	if hours > 0:
		return "%02d:%02d:%02d.%02d" % [hours, minutes, seconds, ms]
	else:
		return "%02d:%02d.%02d" % [minutes, seconds, ms]

func get_current_time_formatted() -> String:
	return format_time(elapsed_time)

func get_elapsed_time() -> int:
	return elapsed_time

func get_checkpoints() -> Dictionary:
	return checkpoints.duplicate()
