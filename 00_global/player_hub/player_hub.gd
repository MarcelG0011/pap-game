#PlayerHub
extends CanvasLayer

@onready var hp_margin_container: MarginContainer = %HPMarginContainer
@onready var hp_bar: TextureProgressBar = %HPBar

@onready var game_over: Control = %GameOver
@onready var load_button: Button = %LoadButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	Messages.player_health_changed.connect( update_health_bar )
	game_over.visible = false
	load_button.pressed.connect( _on_load_pressed )
	quit_button.pressed.connect( _on_quit_pressed )
	update_visibility()

	# Liga ao sinal de cena completamente carregada
	if SceneManager:
		SceneManager.load_scene_finished.connect(_on_scene_fully_loaded)

func _on_scene_fully_loaded() -> void:
	await get_tree().process_frame
	if get_tree().get_first_node_in_group("Player") and not is_in_menu():
		if get_tree().get_nodes_in_group("story_screen").is_empty():
			visible = true
			print("[PlayerHub] Exibido.")


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

func show_game_over() -> void:
	load_button.visible = false
	quit_button.visible = false
	
	game_over.modulate.a = 0
	game_over.visible = true
	
	var tween : Tween = create_tween()
	tween.tween_property( game_over, "modulate", Color.WHITE, 3.0 )
	await tween.finished
	
	load_button.visible = true
	quit_button.visible = true
	
	load_button.grab_focus()
	pass

func clear_game_over() -> void:
	load_button.visible = false
	quit_button.visible = false
	await SceneManager.scene_entered
	game_over.visible = false
	var player : Player = get_tree().get_first_node_in_group( "Player" )
	player.queue_free()
	pass

func _on_load_pressed() -> void:
	SaveManager.load_game( SaveManager.current_slot )
	clear_game_over()
	pass

func _on_quit_pressed() -> void:
	SceneManager.transition_scene("res://title_screen/title_screen.tscn", "", Vector2.ZERO, "up" )
	clear_game_over()
	pass

func force_show() -> void:
	visible = true
