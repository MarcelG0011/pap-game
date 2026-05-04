extends CanvasLayer

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

var player_position : Vector2

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Audio.setup_button_audio( self )
	add_to_group("PauseMenu") # Necessário para o InactivityMonitor
	hide()
	
	if system_menu_button:
		system_menu_button.pressed.connect(show_system_menu)
		
	Audio.setup_button_audio(self)
	setup_system_menu()
	
	if shop_button:
		shop_button.pressed.connect(_show_shop)
		
	var _player = get_tree().get_first_node_in_group("Player")
	if _player:
		player_position = _player.global_position
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		# VERIFICA SE O LOCKSCREEN ESTÁ NO TOPO
		if InactivityMonitor and InactivityMonitor.is_lockscreen_active():
			get_viewport().set_input_as_handled()
			return
		
		get_viewport().set_input_as_handled()
		toggle_pause()

func toggle_pause() -> void:
	if visible:
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
	hide()
	# Só retoma o tempo do motor se o lockscreen não estiver a forçar a pausa
	if InactivityMonitor and not InactivityMonitor.is_lockscreen_active():
		get_tree().paused = false

func show_pause_screen() -> void:
	if pause_screen: pause_screen.show()
	if system: system.hide()

func show_system_menu() -> void:
	if pause_screen: pause_screen.hide()
	if system: system.show()
	if back_to_map_button: back_to_map_button.grab_focus()

func setup_system_menu() -> void:
	# Configurações iniciais dos sliders
	music_slider.value = AudioServer.get_bus_volume_linear(2)
	sfx_slider.value = AudioServer.get_bus_volume_linear(3)
	ui_slider.value = AudioServer.get_bus_volume_linear(4)

	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	ui_slider.value_changed.connect(_on_ui_slider_changed)

	if back_to_title_button:
		back_to_title_button.pressed.connect(_on_back_to_title_pressed)
	if back_to_map_button:
		back_to_map_button.pressed.connect(show_pause_screen)

func _on_music_slider_changed(v: float) -> void:
	AudioServer.set_bus_volume_linear(2, v)
	SaveManager.save_configuration()
	Audio.ui_focus_change()

func _on_sfx_slider_changed(v: float) -> void:
	AudioServer.set_bus_volume_linear(3, v)
	Audio.play_spatial_sound(Audio.ui_focus_audio, player_position)
	SaveManager.save_configuration()

func _on_ui_slider_changed(v: float) -> void:
	AudioServer.set_bus_volume_linear(4, v)
	Audio.ui_focus_change()
	SaveManager.save_configuration()

func _show_shop() -> void:
	var shop = load("res://economy/ui/shop_screen.tscn").instantiate()
	add_child(shop)

func _on_back_to_title_pressed() -> void:
	get_tree().paused = false
	SceneManager.transition_scene("res://title_screen/title_screen.tscn", "", Vector2.ZERO, "up")
