extends CanvasLayer

@onready var panel: PanelContainer = %Panel

func _ready() -> void:
	AutosaveManager.autosave_triggered.connect(_on_autosave)
	panel.visible = false

func _on_autosave(_reason: String) -> void:
	show_indicator()

func show_indicator() -> void:
	panel.visible = true
	panel.modulate.a = 1.0
	
	await get_tree().create_timer(2.0).timeout
	
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	panel.visible = false
