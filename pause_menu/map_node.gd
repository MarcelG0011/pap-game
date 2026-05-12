# res://general/map_node/map_node.gd
@tool
@icon("res://general/icons/map_node.svg")
class_name MapNode
extends Control

const SCALE_FACTOR: float = 40.0

@export_file("*.tscn") var linked_scene: String: set = _on_scene_set
@export_tool_button("Update") var update_node_action = update_node

@export var entrances_top:    Array[float] = []
@export var entrances_right:  Array[float] = []
@export var entrances_left:   Array[float] = []
@export var entrances_bottom: Array[float] = []

@export var indicator_offset: Vector2 = Vector2.ZERO

@onready var transition_blocks: Control        = %TransitionBlocks
@onready var label:             Label          = $Label
@onready var player_indicator:  Control        = %PlayerIndicator
@onready var background:        ColorRect      = $ColorRect

# ── Estado ────────────────────────────────────────────────────
var _last_discovered_count: int = -1
var _is_visible_confirmed:  bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		_setup_editor_colors()
		return

	add_to_group("map_nodes")

	if label:
		label.visible = false

	_setup_runtime_colors()
	create_transition_blocks()

	# ── FIX: espera um frame para o SaveManager ter carregado os dados
	# antes de verificar visibilidade. Em jogos novos o array está pronto,
	# mas ao carregar save o SceneManager pode ainda estar a processar.
	await get_tree().process_frame
	update_visibility()

	# Esconde o indicador de jogador até ser necessário
	if player_indicator:
		player_indicator.visible = false


# ── Cores ─────────────────────────────────────────────────────
func _setup_editor_colors() -> void:
	if background:
		background.color = Color(0.2, 0.2, 0.3, 0.5)


func _setup_runtime_colors() -> void:
	if background:
		background.color = Color(0.098, 0.11, 0.16, 1.0)  # #191C29


# ── Process ───────────────────────────────────────────────────
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	# Só verifica quando o tamanho do array muda — evita overhead
	var current_count := SaveManager.discovered_areas.size()
	if current_count != _last_discovered_count:
		_last_discovered_count = current_count
		update_visibility()

	# Actualiza posição do jogador quando este mapa está visível e o jogo está pausado
	if visible and get_tree().paused:
		if SceneManager.current_scene_uid == linked_scene:
			_update_player_indicator()
		else:
			# Esconde indicador se o jogador não está neste nível
			if player_indicator and player_indicator.visible:
				player_indicator.visible = false


# ── Visibilidade ──────────────────────────────────────────────
func update_visibility() -> void:
	if linked_scene.is_empty():
		visible = false
		return

	var discovered := SaveManager.is_discovered_area(linked_scene)
	visible = discovered

	if discovered and not _is_visible_confirmed:
		_is_visible_confirmed = true
		print("[MAP_NODE] Área visível no mapa: %s" % linked_scene)


# ── Scene setter ──────────────────────────────────────────────
func _on_scene_set(value: String) -> void:
	if linked_scene != value:
		linked_scene = value
		if Engine.is_editor_hint():
			update_node()


# ── Update (editor) ───────────────────────────────────────────
func update_node() -> void:
	var new_size := Vector2(480, 270)
	var transitions: Array[LevelTransition] = []

	if ResourceLoader.exists(linked_scene):
		var packed := ResourceLoader.load(linked_scene) as PackedScene
		if packed:
			var instance := packed.instantiate()
			if instance:
				update_node_label(instance)

				for c in instance.get_children():
					if c is LevelBounds:
						new_size        = Vector2(c.width, c.height)
						indicator_offset = c.position
					elif c is LevelTransition:
						transitions.append(c)

				instance.queue_free()

	size = (new_size / SCALE_FACTOR).round()

	if background:
		background.size = size

	create_entrance_data(transitions)
	create_transition_blocks()


func update_node_label(scene: Node) -> void:
	if not label:
		label = get_node_or_null("Label")
	if label:
		var t := scene.scene_file_path
		t = t.replace("res://levels/", "").replace(".tscn", "")
		label.text = t


# ── Entrance data ─────────────────────────────────────────────
func create_entrance_data(transitions: Array[LevelTransition]) -> void:
	entrances_bottom.clear()
	entrances_left.clear()
	entrances_right.clear()
	entrances_top.clear()

	for t in transitions:
		# ── FIX: usa indicator_offset para converter posição correctamente
		var pos := (t.position - indicator_offset) / SCALE_FACTOR

		match t.location:
			LevelTransition.SIDE.LEFT:
				entrances_left.append(clampf(pos.y - 3, 2.0, size.y - 5))
			LevelTransition.SIDE.RIGHT:
				entrances_right.append(clampf(pos.y - 3, 2.0, size.y - 5))
			LevelTransition.SIDE.TOP:
				entrances_top.append(clampf(pos.x, 2.0, size.x - 5.0))
			LevelTransition.SIDE.BOTTOM:
				entrances_bottom.append(clampf(pos.x, 2.0, size.x - 5.0))


# ── Blocos de transição ───────────────────────────────────────
func create_transition_blocks() -> void:
	if not transition_blocks:
		transition_blocks = get_node_or_null("%TransitionBlocks")
	if not transition_blocks:
		push_warning("[MAP_NODE] TransitionBlocks não encontrado em: %s" % name)
		return

	for c in transition_blocks.get_children():
		c.queue_free()

	for t in entrances_left:
		_add_block(Vector2(0, t),           Vector2(2, 4))
	for t in entrances_right:
		_add_block(Vector2(size.x - 2, t),  Vector2(2, 4))
	for t in entrances_top:
		_add_block(Vector2(t, 0),           Vector2(4, 2))
	for t in entrances_bottom:
		_add_block(Vector2(t, size.y - 2),  Vector2(4, 2))


func _add_block(pos: Vector2, block_size: Vector2) -> ColorRect:
	var block := ColorRect.new()
	block.color        = Color(0.392, 0.588, 0.902)  # #6496E6
	block.size         = block_size
	block.position     = pos
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_blocks.add_child(block)
	return block

# Alias público mantido para retrocompatibilidade
func add_block() -> ColorRect:
	return _add_block(Vector2.ZERO, Vector2(2, 4))


# ── Indicador do jogador ──────────────────────────────────────
func _update_player_indicator() -> void:
	var player: Player = get_tree().get_first_node_in_group("Player")
	if not player:
		if player_indicator:
			player_indicator.visible = false
		return

	if not player_indicator:
		player_indicator = get_node_or_null("%PlayerIndicator")
	if not player_indicator:
		push_warning("[MAP_NODE] PlayerIndicator não encontrado em: %s" % name)
		return

	player_indicator.visible = true

	# ── FIX: usa indicator_offset para calcular posição relativa correctamente
	# indicator_offset é a position do LevelBounds no mundo da cena
	var local_pos := (player.global_position - indicator_offset) / SCALE_FACTOR
	var ind_size  := player_indicator.size

	# Garante que o indicador não sai fora da room
	var clamped := Vector2(
		clampf(local_pos.x - ind_size.x * 0.5, 1.0, size.x - ind_size.x - 1.0),
		clampf(local_pos.y - ind_size.y * 0.5, 1.0, size.y - ind_size.y - 1.0)
	)

	player_indicator.position = clamped

# Alias público mantido por retrocompatibilidade
func display_player_location() -> void:
	_update_player_indicator()
