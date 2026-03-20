# class_name PauseMenu
extends CanvasLayer

func _init() -> void:
	print( " PAUSE MANAGER")
#region // On Ready Variables
@onready var pause_screen: Control = %PauseScreen
@onready var system: Control = %System
@onready var system_menu_button: Button = %SystemMenuButton
@onready var back_to_map_button: Button = %BackToMapButton
@onready var back_to_title_button: Button = %BackToTitleButton
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var ui_slider: HSlider = %UISlider
@onready var shop_button: Button = %ShopButton
#endregion

var player: Player
var player_position : Vector2


func _ready() -> void:
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	if system_menu_button:
		system_menu_button.pressed.connect(show_system_menu)
		
	Audio.setup_button_audio( self )
	
	setup_system_menu()
	if shop_button:
		shop_button.pressed.connect(_show_shop)
	var player : Node2D = get_tree().get_first_node_in_group( "Player" )
	if player:
		player_position = player.global_position

func _input(event: InputEvent) -> void:	
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		toggle_pause()

func _unhandled_input(event: InputEvent) -> void:
	if pause_screen and pause_screen.visible:
		if event.is_action_pressed("right") or event.is_action_pressed("down"): 
			if system_menu_button:
				system_menu_button.grab_focus()

func toggle_pause() -> void:
	if get_tree().paused:
		unpause_game()
	else:
		pause_game()

func pause_game() -> void:
	get_tree().paused = true
	show()
	show_pause_screen()
	if system_menu_button:
		system_menu_button.grab_focus()

func unpause_game() -> void:
	get_tree().paused = false
	hide()

func show_pause_screen() -> void:
	if pause_screen:
		pause_screen.visible = true
	if system:
		system.visible = false

func show_system_menu() -> void:
	if pause_screen:
		pause_screen.visible = false
	if system:
		system.visible = true
	if back_to_map_button:
		back_to_map_button.grab_focus()

func setup_system_menu() -> void:
	music_slider.value = AudioServer.get_bus_volume_linear( 2 )
	sfx_slider.value = AudioServer.get_bus_volume_linear( 3 )
	ui_slider.value = AudioServer.get_bus_volume_linear( 4 )

	music_slider.value_changed.connect( _on_music_slider_changed )
	sfx_slider.value_changed.connect( _on_sfx_slider_changed )
	ui_slider.value_changed.connect( _on_ui_slider_changed )

	if back_to_title_button:
		back_to_title_button.pressed.connect(_on_back_to_title_pressed)
	if back_to_map_button:
		back_to_map_button.pressed.connect(show_pause_screen)

func _on_music_slider_changed( v : float ) -> void:
	AudioServer.set_bus_volume_linear( 2, v )
	SaveManager.save_configuration()
	Audio.ui_focus_change()
	pass
	
func _on_sfx_slider_changed( v : float ) -> void:
	AudioServer.set_bus_volume_linear( 3, v )
	Audio.play_spatial_sound( Audio.ui_focus_audio, player_position )
	SaveManager.save_configuration()
	pass
	
func _on_ui_slider_changed( v : float ) -> void:
	AudioServer.set_bus_volume_linear( 4, v )
	Audio.ui_focus_change()
	SaveManager.save_configuration()
	pass
	
func _show_shop() -> void:
	print("[PAUSE] Abrindo loja...")
	var shop = load("res://economy/ui/shop_screen.tscn").instantiate()
	add_child(shop)


func _on_back_to_title_pressed() -> void:
	get_tree().paused = false
	SceneManager.transition_scene("res://title_screen/title_screen.tscn", "", Vector2.ZERO, "up")
