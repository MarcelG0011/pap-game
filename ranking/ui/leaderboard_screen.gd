extends Control

@onready var entries_container: VBoxContainer = %EntriesContainer
@onready var local_button: Button = %LocalButton
@onready var online_button: Button = %OnlineButton
@onready var personal_best_label: Label = %PersonalBestLabel
@onready var back_button: Button = %BackButton

enum Tab { LOCAL, ONLINE }
var current_tab: Tab = Tab.LOCAL

func _ready() -> void:
	print("[LEADERBOARD] Tela inicializada")
	
	# Conecta botões
	local_button.pressed.connect(_on_local_pressed)
	online_button.pressed.connect(_on_online_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	local_button.disabled = false
	online_button.disabled = false
	
	# Atualiza personal best
	update_personal_best()

func _on_local_pressed() -> void:
	print("[LEADERBOARD] Tab Local selecionada")
	current_tab = Tab.LOCAL
	local_button.disabled = true
	online_button.disabled = false
	load_local_leaderboard()

func _on_online_pressed() -> void:
	print("[LEADERBOARD] Tab Online selecionada")
	current_tab = Tab.ONLINE
	local_button.disabled = false
	online_button.disabled = true
	show_online_placeholder()


func load_local_leaderboard() -> void:
	clear_entries()
	
	var entries = LeaderboardManager.get_top_entries(10)
	
	if entries.is_empty():
		show_placeholder("Nenhuma run completada!")
		return
	
	print("[LEADERBOARD] Carregando ", entries.size(), " entradas")
	
	# Header
	add_header_row()
	
	# Entradas
	for i in range(entries.size()):
		add_entry_row(i + 1, entries[i])

func add_header_row() -> void:
	var header = HBoxContainer.new()
	header.custom_minimum_size.y = 30
	
	var rank_label = create_label("RANK", 80, HORIZONTAL_ALIGNMENT_CENTER)
	rank_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	
	var name_label = create_label("JOGADOR", 0, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	
	var time_label = create_label("TEMPO", 120, HORIZONTAL_ALIGNMENT_RIGHT)
	time_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	
	header.add_child(rank_label)
	header.add_child(name_label)
	header.add_child(time_label)
	
	entries_container.add_child(header)

func add_entry_row(rank: int, entry: Dictionary) -> void:
	var row = HBoxContainer.new()
	row.custom_minimum_size.y = 35
	
	# Rank 
	var rank_text = ""
	if rank == 1:
		rank_text = "1º"
	elif rank == 2:
		rank_text = "2º"
	elif rank == 3:
		rank_text = "3º"
	else:
		rank_text = "#%d" % rank
	
	var rank_label = create_label(rank_text, 80, HORIZONTAL_ALIGNMENT_CENTER)
	
	# Nome
	var name_label = create_label(entry.player, 0, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Tempo
	var time_label = create_label(
		SpeedrunTimer.format_time(entry.time_ms),
		120,
		HORIZONTAL_ALIGNMENT_RIGHT
	)
	
	# Highlight se for o player
	if entry.player == LeaderboardManager.player_name:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 0, 0.15)
		style.border_color = Color(1, 1, 0, 0.5)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		
		row.add_theme_stylebox_override("panel", style)
	
	row.add_child(rank_label)
	row.add_child(name_label)
	row.add_child(time_label)
	
	entries_container.add_child(row)

func show_online_placeholder() -> void:
	clear_entries()
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var title_label = Label.new()
	title_label.text = "Online Leaderboard"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title_label)
	
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 20
	vbox.add_child(spacer)
	
	var message_label = Label.new()
	message_label.text = "Em desenvolvimento"
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(message_label)
	
	entries_container.add_child(vbox)

func show_placeholder(message: String) -> void:
	var label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	entries_container.add_child(label)

func create_label(text: String, min_width: float, alignment: HorizontalAlignment) -> Label:
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	if min_width > 0:
		label.custom_minimum_size.x = min_width
	return label

func clear_entries() -> void:
	for child in entries_container.get_children():
		child.queue_free()

func update_personal_best() -> void:
	var best_time = LeaderboardManager.get_player_best_time()
	
	if best_time > 0:
		personal_best_label.text = "Personal Best: %s" % SpeedrunTimer.format_time(best_time)
	else:
		personal_best_label.text = "Personal Best: --:--"

func _on_back_pressed() -> void:
	print("[LEADERBOARD] Fechando...")
	queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		print("[LEADERBOARD] ESC pressionado - fechando...")
		queue_free()
