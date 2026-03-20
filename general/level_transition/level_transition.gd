@tool
@icon("res://general/icons/level_transition.svg")
class_name LevelTransition extends Node2D

enum SIDE { LEFT, RIGHT, TOP, BOTTOM }

@export_range(2, 12, 1, "or_greater" ) var size : int = 2 :
	set( value ):
		size = value
		apply_area_settings()

@export var location: SIDE = SIDE.LEFT :
	set( value ):
		location = value
		apply_area_settings()

@export_file("*.tscn") var target_level: String = ""
@export var target_area_name: String = "LevelTransition"

@onready var area_2d: Area2D = $Area2D
@onready var collision: CollisionShape2D = $Area2D/CollisionShape2D
@onready var spawn_marker: Marker2D = $SpawnMarker


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	apply_area_settings()
	
	if not area_2d.body_entered.is_connected(_on_player_entered):
		area_2d.body_entered.connect(_on_player_entered)
		
	SceneManager.new_scene_ready.connect( _on_new_scene_ready )
	SceneManager.load_scene_finished.connect( _on_load_scene_finished )
	pass
	
func _on_player_entered( _n : Node2D ) -> void:
	print("=== PLAYER ENTROU ===")
	print("LevelTransition: ", name)
	print("Location: ", location)
	print("Player pos: ", _n.global_position)
	print("Transition pos: ", global_position)
	print("Offset calculado: ", get_offset(_n))
	print("Target: ", target_area_name)
	SceneManager.transition_scene( target_level, target_area_name, get_offset( _n ), get_transition_direction() )
	pass

func _on_new_scene_ready(target_name : String, offset : Vector2) -> void:
	print("=== NOVA CENA PRONTA ===")
	print("Target name: ", target_name)
	print("Meu name: ", name)
	print("Offset recebido: ", offset)
	if target_name == name:
		var player : Node = get_tree().get_first_node_in_group( "Player" )
		print("Player vai spawnar em: ", player.global_position)
		player.global_position = global_position + offset
	pass


func _on_load_scene_finished() -> void:
	area_2d.monitoring = false
	await get_tree().physics_frame
	await get_tree().physics_frame
	area_2d.monitoring = true
	pass
	
	
func get_offset( player : Node2D ) -> Vector2:
	var offset : Vector2 = Vector2.ZERO
	var player_pos : Vector2 = player.global_position
	
	if location == SIDE.LEFT or location == SIDE.RIGHT:
		offset.y = player_pos.y - self.global_position.y
		if location == SIDE.LEFT:
			offset.x = -32
		else:
			offset.x = 32
	else:
		offset.x = player_pos.x - self.global_position.x
		if location == SIDE.TOP:
			offset.y = -12
		else:
			offset.y = 48
			
	return offset

func apply_area_settings() -> void:
	area_2d = get_node_or_null( "Area2D" )
	if not area_2d:
		return
	if location == SIDE.LEFT or location == SIDE.RIGHT:
# size controla a escala em Y
		area_2d.scale.y = size
# location controla a direção em X
		if location == SIDE.LEFT:
			area_2d.scale.x = -1
		else:
			area_2d.scale.x = 1
	else:  # TOP ou BOTTOM
# size controla a escala em X
		area_2d.scale.x = size
# location controla a direção em Y
		if location == SIDE.TOP:
			area_2d.scale.y = 1
		else:
			area_2d.scale.y = -1
pass


func get_transition_direction() -> String:
	match location:
		SIDE.LEFT:
			return "left"
		SIDE.RIGHT:
			return "right"
		SIDE.TOP:
			return "up"
		_:
			return "down"
