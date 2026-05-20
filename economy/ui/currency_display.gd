extends Control

@onready var soul_label: Label = %SoulLabel
@onready var gems_label: Label = %GemsLabel

func _ready() -> void:
	CurrencyManager.soul_changed.connect(_on_soul_changed)
	CurrencyManager.gems_changed.connect(_on_gems_changed)
	_on_soul_changed(CurrencyManager.get_soul())
	_on_gems_changed(CurrencyManager.get_gems())
	print("[CURRENCY DISPLAY] Inicializado")

	# Conecta ao sinal que indica que a transição terminou
	if SceneManager:
		SceneManager.load_scene_finished.connect(_on_scene_fully_loaded)

func _on_scene_fully_loaded() -> void:
	#await get_tree().process_frame
	if get_tree().get_first_node_in_group("Player") and not _is_in_menu():
		if get_tree().get_nodes_in_group("story_screen").is_empty():
			visible = true
			print("[CurrencyDisplay] Exibido.")

func _is_in_menu() -> bool:
	var current_scene = get_tree().current_scene
	if not current_scene: return false
	return current_scene.name in ["LoginScreen", "SignupScreen", "TitleScreen", "LeaderboardScreen"]

func _on_soul_changed(new_amount: int) -> void:
	soul_label.text = str(new_amount)
	print("[CURRENCY DISPLAY] Soul atualizado: ", new_amount)

func _on_gems_changed(new_amount: int) -> void:
	gems_label.text = str(new_amount)
	print("[CURRENCY DISPLAY] Gems atualizado: ", new_amount)
