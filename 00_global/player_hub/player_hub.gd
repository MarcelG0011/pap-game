#PlayerHub
extends CanvasLayer

@onready var hp_margin_container: MarginContainer = %HPMarginContainer
@onready var hp_bar: TextureProgressBar = %HPBar

func _ready() -> void:
	#Messages.player_health_changed.connect( update_health_bar )
	update_visibility()

	pass


func update_health_bar(hp: float, max_hp: float) -> void:
	var value : float = ( hp/max_hp ) * 100
	hp_bar.value = value
	hp_margin_container.size.x = max_hp + 22
	pass

func update_visibility() -> void:
	# Só mostra se:
	# 1. Tiver player na cena
	# 2. Usuario estiver logado
	# 3. Não estiver em menus
	
	var should_be_visible = (
		get_tree().get_first_node_in_group("Player") != null and
		AccountManager.is_logged_in and
		not is_in_menu()
	)
	
	visible = should_be_visible

func is_in_menu() -> bool:
	var current_scene = get_tree().current_scene
	if not current_scene:
		return false
	
	var scene_name = current_scene.name
	return scene_name in ["LoginScreen", "SignupScreen", "TitleScreen", "LeaderboardScreen"]
