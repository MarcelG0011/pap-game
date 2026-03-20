extends CanvasLayer

signal new_game_started(slot: int)
signal game_loaded(slot: int)

@onready var main_menu: VBoxContainer = %MainMenu
@onready var new_game_menu: VBoxContainer = %NewGameMenu
@onready var load_game_menu: VBoxContainer = %LoadGameMenu

@onready var new_game_button: Button = $Control/MainMenu/NewGameButton
@onready var load_game_button: Button = $Control/MainMenu/LoadGameButton
@onready var leaderboard_button: Button = %LeaderboardButton
@onready var logout_button: Button = %LogoutButton
@onready var settings_button: Button = %SettingsButton

@onready var new_slot_01: Button = %NewSlot01
@onready var new_slot_02: Button = %NewSlot02
@onready var new_slot_03: Button = %NewSlot03

@onready var load_slot_01: Button = %LoadSlot01
@onready var load_slot_02: Button = %LoadSlot02
@onready var load_slot_03: Button = %LoadSlot03

const FIRST_LEVEL_PATH: String = "res://levels/00_prison/01.tscn"
const MAX_SLOTS: int = 3

var is_loading_game: bool = false
var is_creating_game: bool = false

func _ready() -> void:
	
	_initialize()

func _initialize() -> void:
	_hide_game_huds()
	
	if not _validate_user_logged_in():
		return
	
	print("[TITLE] Bem-vindo, ", AccountManager.get_username())
	
	_connect_button_signals()
	_update_slot_buttons()
	
	show_main_menu()

func _connect_button_signals() -> void:
	new_game_button.pressed.connect(_on_new_game_button_pressed)
	load_game_button.pressed.connect(_on_load_game_button_pressed)
	leaderboard_button.pressed.connect(_on_leaderboard_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	logout_button.pressed.connect(_on_logout_button_pressed)
	
	new_slot_01.pressed.connect(_on_new_game_slot_pressed.bind(0))
	new_slot_02.pressed.connect(_on_new_game_slot_pressed.bind(1))
	new_slot_03.pressed.connect(_on_new_game_slot_pressed.bind(2))
	
	load_slot_01.pressed.connect(_on_load_game_slot_pressed.bind(0))
	load_slot_02.pressed.connect(_on_load_game_slot_pressed.bind(1))
	load_slot_03.pressed.connect(_on_load_game_slot_pressed.bind(2))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not main_menu.visible:
			show_main_menu()

func show_main_menu() -> void:
	_set_menu_visibility(true, false, false)
	leaderboard_button.visible = true
	new_game_button.grab_focus()

func show_new_game_menu() -> void:
	_set_menu_visibility(false, true, false)
	leaderboard_button.visible = false
	_update_new_game_slots()
	new_slot_01.grab_focus()

func show_load_game_menu() -> void:
	_set_menu_visibility(false, false, true)
	leaderboard_button.visible = false
	_update_load_game_slots()
	load_slot_01.grab_focus()

func _set_menu_visibility(main: bool, new_game: bool, load_game: bool) -> void:
	main_menu.visible = main
	new_game_menu.visible = new_game
	load_game_menu.visible = load_game

func _on_new_game_button_pressed() -> void:
	show_new_game_menu()

func _on_load_game_button_pressed() -> void:
	show_load_game_menu()

func _on_leaderboard_button_pressed() -> void:
	_open_leaderboard()

func _on_settings_button_pressed() -> void:
	_open_settings()

func _on_logout_button_pressed() -> void:
	await _perform_logout()

func _on_new_game_slot_pressed(slot: int) -> void:
	if is_creating_game or is_loading_game:
		push_warning("[TITLE] Operacao ja em progresso")
		return
	
	await _create_and_start_new_game(slot)

func _on_load_game_slot_pressed(slot: int) -> void:
	if is_loading_game or is_creating_game:
		push_warning("[TITLE] Operacao ja em progresso")
		return
	
	await _load_and_start_game(slot)

func _create_and_start_new_game(slot: int) -> void:
	print("[TITLE] ========== NEW GAME INICIADO ==========")
	print("[TITLE] Slot: ", slot)
	
	is_creating_game = true
	
	var success = SaveManager.create_new_game_save(slot)
	
	if not success:
		push_error("[TITLE] Falha ao criar novo jogo")
		is_creating_game = false
		return
	
	_start_speedrun()
	_show_game_huds()
	
	var transition_success = await SceneManager.transition_scene(
		FIRST_LEVEL_PATH,
		"", Vector2.ZERO, "up"
	)
	
	is_creating_game = false
	
	if transition_success:
		new_game_started.emit(slot)
		print("[TITLE] ========== NEW GAME COMPLETO ==========")
	else:
		push_error("[TITLE] Falha na transicao de cena")

func _load_and_start_game(slot: int) -> void:
	print("[TITLE] ========== LOAD GAME INICIADO ==========")
	print("[TITLE] Slot: ", slot)
	
	if not SaveManager.save_file_exists(slot):
		push_warning("[TITLE] Save nao existe no slot ", slot)
		return
	
	is_loading_game = true
	
	_show_game_huds()
	
	
	var success = await SaveManager.load_game(slot)
	
	is_loading_game = false
	
	if success:
		game_loaded.emit(slot)
		print("[TITLE] ========== LOAD GAME COMPLETO ==========")
	else:
		push_error("[TITLE] Falha ao carregar jogo")

func _perform_logout() -> void:
	print("[TITLE] ========== LOGOUT INICIADO ==========")
	
	_stop_speedrun()
	_reset_inactivity()
	_unpause_game()
	_hide_all_huds()
	
	AccountManager.logout()
	
	await get_tree().process_frame
	
	get_tree().change_scene_to_file("res://auth/ui/login_screen.tscn")
	
	print("[TITLE] ========== LOGOUT COMPLETO ==========")

func _update_slot_buttons() -> void:
	_update_new_game_slots()
	_update_load_game_slots()

func _update_new_game_slots() -> void:
	var slot_buttons = [new_slot_01, new_slot_02, new_slot_03]
	
	for i in range(MAX_SLOTS):
		if SaveManager.save_file_exists(i):
			slot_buttons[i].text = "Replace Slot %02d" % (i + 1)
		else:
			slot_buttons[i].text = "New Game Slot %02d" % (i + 1)

func _update_load_game_slots() -> void:
	var slot_buttons = [load_slot_01, load_slot_02, load_slot_03]
	
	for i in range(MAX_SLOTS):
		var exists = SaveManager.save_file_exists(i)
		slot_buttons[i].disabled = not exists
		
		if exists:
			slot_buttons[i].text = "Load Slot %02d" % (i + 1)
		else:
			slot_buttons[i].text = "Empty Slot %02d" % (i + 1)

func _hide_game_huds() -> void:
	var hud_names = ["PlayerHub", "SpeedrunHub"]
	
	for hud_name in hud_names:
		var hud = get_node_or_null("/root/" + hud_name)
		if hud and "visible" in hud:
			hud.visible = false

func _show_game_huds() -> void:
	var player_hub = get_node_or_null("/root/PlayerHub")
	if player_hub and "visible" in player_hub:
		player_hub.visible = true
	
	var speedrun_hub = get_node_or_null("/root/SpeedrunHub")
	if speedrun_hub and "visible" in speedrun_hub:
		speedrun_hub.visible = true

func _hide_all_huds() -> void:
	var hud_names = ["PlayerHub", "SpeedrunHub", "PauseManager"]
	
	for hud_name in hud_names:
		var hud = get_node_or_null("/root/" + hud_name)
		if hud and "visible" in hud:
			hud.visible = false

func _start_speedrun() -> void:
	if SpeedrunTimer:
		SpeedrunTimer.start_run()

func _stop_speedrun() -> void:
	if SpeedrunTimer:
		SpeedrunTimer.cancel_run()

func _reset_inactivity() -> void:
	if InactivityMonitor:
		InactivityMonitor.reset()

func _unpause_game() -> void:
	get_tree().paused = false

func _open_leaderboard() -> void:
	print("[TITLE] Abrindo leaderboard...")
	
	var leaderboard = load("res://ranking/ui/leaderboard_screen.tscn").instantiate()
	add_child(leaderboard)
	
	_set_menu_visibility(false, false, false)
	leaderboard_button.visible = false
	
	leaderboard.tree_exited.connect(func():
		print("[TITLE] Leaderboard fechado")
		show_main_menu()
	)

func _open_settings() -> void:
	print("[TITLE] Abrindo configuracoes...")
	
	var settings = load("res://auth/ui/settings_screen.tscn").instantiate()
	add_child(settings)

func _validate_user_logged_in() -> bool:
	if not AccountManager or not AccountManager.is_logged_in:
		push_error("[TITLE] Usuario nao logado! Voltando para login...")
		get_tree().change_scene_to_file("res://auth/ui/login_screen.tscn")
		return false
	return true
