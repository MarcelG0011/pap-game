extends CanvasLayer

@onready var title_label: Label = %TitleLabel
@onready var body_label: RichTextLabel = %BodyLabel
@onready var continue_button: Button = %ContinueButton

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	if continue_button:
		continue_button.pressed.connect(_close)

func setup(_id: String, t: String, d: String) -> void:
	print("[POPUP] setup: ", t, " / ", d)
	if title_label: title_label.text = t
	if body_label: body_label.text = d
	visible = true
	if continue_button: continue_button.grab_focus()

func _close() -> void:
	get_tree().paused = false
	queue_free()
