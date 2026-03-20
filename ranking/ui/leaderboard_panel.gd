# leaderboard_panel.gd
extends Panel

@onready var entries: VBoxContainer = %Entries
@onready var close_button: Button = %CloseButton

signal closed

func _ready() -> void:
	close_button.pressed.connect(_on_close)
	populate_leaderboard()
	
	# Slide in animation
	position.x = get_viewport_rect().size.x
	var tween = create_tween()
	tween.tween_property(self, "position:x", get_viewport_rect().size.x - size.x, 0.3)

func populate_leaderboard() -> void:
	var top_10 = LeaderboardManager.get_top_entries(10)
	
	for i in range(top_10.size()):
		var entry = top_10[i]
		var label = Label.new()
		label.text = "#%d  %s  %s" % [
			i + 1,
			entry.player,
			SpeedrunTimer.format_time(entry.time_ms)
		]
		entries.add_child(label)

func _on_close() -> void:
	var tween = create_tween()
	tween.tween_property(self, "position:x", get_viewport_rect().size.x, 0.3)
	await tween.finished
	closed.emit()
	queue_free()
