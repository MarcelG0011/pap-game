extends CanvasLayer

signal main_menu_pressed

@onready var main_menu_button: Button = %MainMenuButton
@onready var background: ColorRect = $ColorRect

var _hud_nodes: Array[Node] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	main_menu_button.pressed.connect(func(): main_menu_pressed.emit(); _close())

	var hud_names = ["PlayerHub", "SpeedrunHub", "CurrencyDisplay", "PauseMenu"]
	for hud_name in hud_names:
		var hud = get_node_or_null("/root/" + hud_name)
		if hud:
			_hud_nodes.append(hud)

func _process(_delta: float) -> void:
	for hud in _hud_nodes:
		if is_instance_valid(hud) and hud.visible:
			hud.visible = false

func _close() -> void:
	for hud in _hud_nodes:
		if is_instance_valid(hud):
			hud.visible = true
	get_tree().paused = false
	queue_free()
