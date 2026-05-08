# res://00_global/tutorial_manager.gd
# ==============================================================
#  SOULBOUND: ECHOES OF ETERNITY — Tutorial Manager
#  AutoLoad: TutorialManager
#  Depende de: AccountManager, DatabaseManager (SQLite)
# ==============================================================
extends Node

signal tutorial_shown(tutorial_id: String)
signal tutorial_closed(tutorial_id: String)
signal all_tutorials_skipped

var active_tutorial:    CanvasLayer = null
var is_tutorial_active: bool        = false

var _queue:        Array[Dictionary] = []
var _current_data: Dictionary        = {}

const POPUP_SCENE := "res://ui/tutorial/tutorial_popup.tscn"


func _ready() -> void:
	print("[TUTORIAL] Manager inicializado")


# ─────────────────────────────────────────────────────────────
#  API PÚBLICA
# ─────────────────────────────────────────────────────────────

## Tutorial simples (1 passo).
## p_tip e p_badge são opcionais.
func show_tutorial(
	p_id:    String,
	p_title: String,
	p_desc:  String,
	p_tip:   String = "",
	p_media: String = "",
	p_badge: String = ""
) -> void:
	if has_seen(p_id):
		print("[TUTORIAL] Já visto: %s" % p_id)
		return
	if not _can_show():
		_enqueue(p_id, p_title, p_desc, p_tip, p_media, p_badge)
		return
	_show_one(p_id, p_title, p_desc, p_tip, p_media, 1, 1, p_badge)


## Sequência multi-passo — cada Dictionary deve ter:
##   id, title, description
##   tip (opt), media_path (opt), badge (opt)
func show_sequence(steps: Array[Dictionary]) -> void:
	if steps.is_empty(): return
	if is_tutorial_active:
		push_warning("[TUTORIAL] Tutorial já activo, sequência ignorada")
		return
	if not _can_show(): return

	# Filtra já vistos
	var unseen: Array[Dictionary] = []
	for s in steps:
		var id: String = s.get("id", "")
		if not id.is_empty() and not has_seen(id):
			unseen.append(s)
	if unseen.is_empty(): return

	_queue = unseen.duplicate()
	_current_data["_total_original"] = _queue.size()
	_show_next_queued()


## "Skip All" — chamado pelo próprio popup
func skip_all_current_tutorials() -> void:
	if _current_data.has("id"):
		mark_as_seen(_current_data["id"])
	_queue.clear()
	_current_data.clear()
	all_tutorials_skipped.emit()
	print("[TUTORIAL] Todos saltados")


# ── Consultas à BD ────────────────────────────────────────────

func has_seen(tutorial_id: String) -> bool:
	if not _logged_in(): return false
	return DatabaseManager.has_seen_tutorial(
		AccountManager.get_user_id(), tutorial_id
	)


func mark_as_seen(tutorial_id: String) -> void:
	if not _logged_in(): return
	DatabaseManager.mark_tutorial_as_seen(
		AccountManager.get_user_id(), tutorial_id
	)


func reset_all_tutorials() -> void:
	if not _logged_in(): return
	DatabaseManager.reset_tutorials(AccountManager.get_user_id())
	print("[TUTORIAL] Todos os tutoriais resetados")


# ─────────────────────────────────────────────────────────────
#  INTERNOS
# ─────────────────────────────────────────────────────────────

func _show_one(
	p_id:    String,
	p_title: String,
	p_desc:  String,
	p_tip:   String,
	p_media: String,
	p_step:  int,
	p_total: int,
	p_badge: String
) -> void:
	var scene_res := load(POPUP_SCENE)
	if not scene_res:
		push_error("[TUTORIAL] Cena não encontrada: %s" % POPUP_SCENE)
		return

	active_tutorial = scene_res.instantiate()
	if not active_tutorial:
		push_error("[TUTORIAL] Falha ao instanciar popup")
		return

	_current_data = {
		"id": p_id, "title": p_title, "description": p_desc,
		"tip": p_tip, "media": p_media, "step": p_step, "total": p_total
	}

	if active_tutorial.has_method("setup"):
		active_tutorial.setup(p_id, p_title, p_desc, p_tip, p_media, p_step, p_total, p_badge)

	if active_tutorial.has_signal("popup_closed"):
		active_tutorial.popup_closed.connect(_on_tutorial_closed.bind(p_id))

	get_tree().root.add_child(active_tutorial)
	is_tutorial_active = true
	tutorial_shown.emit(p_id)
	print("[TUTORIAL] Mostrando '%s' (%d/%d)" % [p_id, p_step, p_total])


func _show_next_queued() -> void:
	if _queue.is_empty(): return
	var data  := _queue[0]
	var total := _current_data.get("_total_original", _queue.size()) as int
	var step  := total - _queue.size() + 1

	_show_one(
		data.get("id",          ""),
		data.get("title",       ""),
		data.get("description", ""),
		data.get("tip",         ""),
		data.get("media_path",  ""),
		step, total,
		data.get("badge",       "")
	)


func _on_tutorial_closed(tutorial_id: String) -> void:
	mark_as_seen(tutorial_id)
	active_tutorial    = null
	is_tutorial_active = false
	tutorial_closed.emit(tutorial_id)
	print("[TUTORIAL] Fechado: %s" % tutorial_id)

	if not _queue.is_empty():
		_queue.pop_front()

	if not _queue.is_empty():
		await get_tree().create_timer(0.15).timeout
		_show_next_queued()
	else:
		var total_original = _current_data.get("_total_original", 0)
		_current_data.clear()
		if total_original > 0:
			_current_data["_total_original"] = 0


func _enqueue(
	p_id:    String,
	p_title: String,
	p_desc:  String,
	p_tip:   String,
	p_media: String,
	p_badge: String
) -> void:
	for item in _queue:
		if item.get("id", "") == p_id: return   # evita duplicados
	_queue.append({
		"id": p_id, "title": p_title, "description": p_desc,
		"tip": p_tip, "media_path": p_media, "badge": p_badge
	})
	print("[TUTORIAL] Em fila: %s (total na fila: %d)" % [p_id, _queue.size()])


func _can_show() -> bool:
	if not _logged_in(): return false
	if is_tutorial_active:
		print("[TUTORIAL] Tutorial activo, a enfileirar")
		return false
	return true


func _logged_in() -> bool:
	if not AccountManager:
		push_warning("[TUTORIAL] AccountManager não encontrado")
		return false
	if not AccountManager.is_logged_in:
		return false
	return true
