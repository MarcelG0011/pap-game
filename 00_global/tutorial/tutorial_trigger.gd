class_name TutorialTrigger
extends Area2D

@export var tutorial_id: String = "tutorial_default"
@export var title: String = "Title"
@export_multiline var description: String = "Description"

func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 5  # Layer 5 (Player)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	print("[TRIGGER] Acionado: ", tutorial_id)
	if TutorialManager:
		TutorialManager.show_tutorial(tutorial_id, title, description)
	else:
		printerr("[TRIGGER] TutorialManager é null!")
	queue_free()
