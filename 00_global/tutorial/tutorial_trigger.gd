# res://ui/tutorial/tutorial_trigger.gd
class_name TutorialTrigger
extends Area2D

@export_group("Tutorial")
@export var tutorial_id: String = "tutorial_movement"
@export var title: String = "Movement"
@export_multiline var description: String = "Use [b]A/D[/b] to move."
@export_file("*.png", "*.jpg", "*.ogv", "*.webm") var media_path: String = ""

@export_group("Trigger")
@export var one_shot: bool = true
@export var auto_destroy: bool = true

var triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	# Colisão apenas com player
	collision_layer = 0
	collision_mask = 5

func _on_body_entered(body: Node2D) -> void:
	if triggered and one_shot:
		return
	
	if not body is Player:
		return
	
	triggered = true
	
	TutorialManager.show_tutorial(
		tutorial_id,
		title,
		description,
		media_path
	)
	
	if auto_destroy:
		queue_free()
