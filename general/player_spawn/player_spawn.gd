@icon("res://general/icons/player_spawn.svg")
class_name PlayerSpawn extends Node2D
const PLAYER = preload("uid://cklghektmr05n")

func _ready() -> void:
	visible = false
	await get_tree().process_frame
	
	if get_tree().get_first_node_in_group( "Player" ):
		#We have a Player!
		print( "We have a Player" )
		return
		
	print( "No Player found" )
	#Instantiate a new instance of our player scene
	var player : Player = load("uid://cklghektmr05n").instantiate()
	get_tree().root.add_child( player )
	#Position the player scene
	player.global_position = self.global_position
	pass
