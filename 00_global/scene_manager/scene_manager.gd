extends CanvasLayer

signal load_scene_started
signal new_scene_ready(target_name: String, offset: Vector2)
signal load_scene_finished
signal scene_entered(scene_path: String)

const FADE_DURATION: float = 0.1
const VIEWPORT_SIZE: Vector2 = Vector2(480, 270)
const FADE_MULTIPLIER: int = 2

@onready var fade: Control = $Fade

var current_scene_path: String = ""
var is_transitioning: bool = false

func _ready() -> void:
	fade.visible = false
	await get_tree().process_frame
	load_scene_finished.emit()

func transition_scene(new_scene: String, target_area: String, player_offset: Vector2, dir: String) -> bool:
	if not _validate_transition_request(new_scene):
		return false
	
	if is_transitioning:
		push_warning("[SCENE MANAGER] Transicao ja em progresso")
		return false
	
	is_transitioning = true
	
	var scene_path = _resolve_scene_path(new_scene)
	
	if not _validate_scene_exists(scene_path):
		push_error("[SCENE MANAGER] Cena nao existe: ", scene_path)
		is_transitioning = false
		return false
	
	await _execute_transition(scene_path, target_area, player_offset, dir)
	
	is_transitioning = false
	return true

func get_current_scene_path() -> String:
	return current_scene_path

func is_busy() -> bool:
	return is_transitioning

func _execute_transition(scene_path: String, target_area: String, player_offset: Vector2, dir: String) -> void:
	print("[SCENE MANAGER] Iniciando transicao para: ", scene_path)
	
	var fade_pos = _calculate_fade_position(dir)
	
	_prepare_transition()
	load_scene_started.emit()
	
	await _fade_screen(fade_pos, Vector2.ZERO)
	
	_change_scene(scene_path)
	
	await get_tree().scene_changed
	
	_finalize_transition(target_area, player_offset, fade_pos)
	
	print("[SCENE MANAGER] Transicao completa")

func _prepare_transition() -> void:
	get_tree().paused = true
	fade.visible = true

func _change_scene(scene_path: String) -> void:
	print("[SCENE MANAGER] Carregando: ", scene_path)
	get_tree().change_scene_to_file(scene_path)
	current_scene_path = scene_path
	scene_entered.emit(scene_path)

func _finalize_transition(target_area: String, player_offset: Vector2, fade_pos: Vector2) -> void:
	new_scene_ready.emit(target_area, player_offset)
	
	await get_tree().process_frame
	await _fade_screen(Vector2.ZERO, -fade_pos)
	
	fade.visible = false
	get_tree().paused = false
	load_scene_finished.emit()

func _fade_screen(from: Vector2, to: Vector2) -> void:
	fade.position = from
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade, "position", to, FADE_DURATION)
	await tween.finished

func _calculate_fade_position(dir: String) -> Vector2:
	var base_pos = VIEWPORT_SIZE * FADE_MULTIPLIER
	
	match dir:
		"left": return base_pos * Vector2(-1, 0)
		"right": return base_pos * Vector2(1, 0)
		"up": return base_pos * Vector2(0, -1)
		"down": return base_pos * Vector2(0, 1)
		_: 
			push_warning("[SCENE MANAGER] Direcao invalida: ", dir, ", usando 'up'")
			return base_pos * Vector2(0, -1)

func _resolve_scene_path(scene: String) -> String:
	if scene.begins_with("uid://"):
		return _convert_uid_to_path(scene)
	return scene

func _convert_uid_to_path(uid: String) -> String:
	var uid_value = ResourceUID.text_to_id(uid)
	var path = ResourceUID.get_id_path(uid_value)
	print("[SCENE MANAGER] UID convertido: ", uid, " -> ", path)
	return path

func _validate_transition_request(scene: String) -> bool:
	if scene.is_empty():
		push_error("[SCENE MANAGER] Path da cena vazio")
		return false
	return true

func _validate_scene_exists(scene_path: String) -> bool:
	if not ResourceLoader.exists(scene_path):
		return false
	return true
