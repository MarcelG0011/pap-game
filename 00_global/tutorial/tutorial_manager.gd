# res://00_global/tutorial_manager.gd
extends Node

signal tutorial_shown(tutorial_id: String)
signal tutorial_closed(tutorial_id: String)

const TUTORIAL_POPUP_SCENE = preload("res://00_global/tutorial/tutorial_popup.tscn")

var active_tutorial: CanvasLayer = null
var is_tutorial_active: bool = false

func _ready() -> void:
	print("[TUTORIAL] Tutorial Manager inicializado")

# Mostra tutorial simples (1 passo)
func show_tutorial(tutorial_id: String, title: String, description: String, media_path: String = "") -> void:
	if has_seen(tutorial_id):
		print("[TUTORIAL] '", tutorial_id, "' já foi visto")
		return
	
	if is_tutorial_active:
		push_warning("[TUTORIAL] Já existe tutorial ativo")
		return
	
	if not AccountManager or not AccountManager.is_logged_in:
		push_warning("[TUTORIAL] Usuário não está logado")
		return
	
	print("[TUTORIAL] Mostrando: ", tutorial_id)
	
	_create_popup(tutorial_id, title, description, media_path, 1, 1)

# Mostra tutorial multi-passo
func show_tutorial_sequence(tutorials: Array) -> void:
	if tutorials.is_empty():
		push_warning("[TUTORIAL] Array de tutoriais vazio")
		return
	
	var total_steps = tutorials.size()
	
	for i in range(total_steps):
		var tut = tutorials[i]
		var tutorial_id = tut.get("id", "tutorial_" + str(i))
		
		if has_seen(tutorial_id):
			continue
		
		var title = tut.get("title", "Tutorial")
		var description = tut.get("description", "")
		var media = tut.get("media", "")
		
		await _show_step(tutorial_id, title, description, media, i + 1, total_steps)

func _show_step(tutorial_id: String, title: String, description: String, media_path: String, step: int, total: int) -> void:
	if not AccountManager or not AccountManager.is_logged_in:
		return
	
	_create_popup(tutorial_id, title, description, media_path, step, total)
	
	# Aguarda fechar
	if active_tutorial and active_tutorial.has_signal("popup_closed"):
		await active_tutorial.popup_closed

func _create_popup(tutorial_id: String, title: String, description: String, media_path: String, step: int, total: int) -> void:
	if not TUTORIAL_POPUP_SCENE:
		push_error("[TUTORIAL] tutorial_popup.tscn não encontrado!")
		return
	
	active_tutorial = TUTORIAL_POPUP_SCENE.instantiate()
	
	if active_tutorial.has_method("setup"):
		active_tutorial.setup(tutorial_id, title, description, media_path, step, total)
	
	if active_tutorial.has_signal("popup_closed"):
		active_tutorial.popup_closed.connect(_on_tutorial_closed.bind(tutorial_id))
	
	get_tree().root.add_child(active_tutorial)
	is_tutorial_active = true
	tutorial_shown.emit(tutorial_id)

func _on_tutorial_closed(tutorial_id: String) -> void:
	print("[TUTORIAL] Fechado: ", tutorial_id)
	
	mark_as_seen(tutorial_id)
	
	if active_tutorial:
		active_tutorial = null
	
	is_tutorial_active = false
	tutorial_closed.emit(tutorial_id)

func has_seen(tutorial_id: String) -> bool:
	if not AccountManager or not AccountManager.is_logged_in:
		return false
	
	var user_id = AccountManager.get_user_id()
	return DatabaseManager.has_seen_tutorial(user_id, tutorial_id)

func mark_as_seen(tutorial_id: String) -> void:
	if not AccountManager or not AccountManager.is_logged_in:
		return
	
	var user_id = AccountManager.get_user_id()
	DatabaseManager.mark_tutorial_as_seen(user_id, tutorial_id)

func reset_all_tutorials() -> void:
	if not AccountManager or not AccountManager.is_logged_in:
		return
	
	var user_id = AccountManager.get_user_id()
	DatabaseManager.reset_tutorials(user_id)
	print("[TUTORIAL] Todos resetados")
