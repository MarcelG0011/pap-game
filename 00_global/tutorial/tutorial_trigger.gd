# res://ui/tutorial/tutorial_trigger.gd
# ==============================================================
#  SOULBOUND: ECHOES OF ETERNITY — Tutorial Trigger
#  Coloca esta cena em qualquer área do mundo para disparar
#  um tutorial quando o jogador entra na Area2D.
# ==============================================================
class_name TutorialTrigger
extends Area2D

@export_group("Tutorial Config")
@export var tutorial_id:          String = ""
@export var tutorial_title:       String = ""
@export_multiline var tutorial_description: String = ""
@export_multiline var tutorial_tip:         String = ""   # dica (caixa azul) — opcional
@export var tutorial_badge:       String = ""             # ex: "CHAPTER I — SOUL ABSORPTION"
@export_file("*.png,*.jpg,*.webp,*.ogv,*.webm")
	var tutorial_media: String = ""

@export_group("Trigger Settings")
@export var one_shot:     bool = true    # dispara só uma vez por sessão
@export var auto_destroy: bool = true    # elimina o nó depois de disparar
@export var check_db:     bool = true    # não dispara se já foi visto na BD

# ── Estado ────────────────────────────────────────────────────
var _has_triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask  = 5   # ajusta à layer do Player

	if tutorial_id.is_empty():
		push_warning("[TRIGGER] tutorial_id está vazio em %s" % name)

	print("[TRIGGER] '%s' pronto" % tutorial_id)


func _on_body_entered(body: Node2D) -> void:
	# one_shot: impede que dispare duas vezes na mesma sessão
	if _has_triggered and one_shot:
		return

	# Só activa para o Player
	if not body is Player:
		return

	# Verifica BD se check_db estiver activo
	if check_db and TutorialManager.has_seen(tutorial_id):
		if auto_destroy: queue_free()
		return

	_has_triggered = true
	_show_tutorial()

	if auto_destroy:
		queue_free()


func _show_tutorial() -> void:
	if tutorial_id.is_empty():
		push_warning("[TRIGGER] Tentativa de mostrar tutorial sem ID")
		return

	TutorialManager.show_tutorial(
		tutorial_id,
		tutorial_title,
		tutorial_description,
		tutorial_tip,
		tutorial_media,
		tutorial_badge
	)
