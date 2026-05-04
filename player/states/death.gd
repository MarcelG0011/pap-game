class_name PlayerStateDeath extends PlayerState

const DEATH_AUDIO = preload( "uid://5jwoq06142vu" )

func init() -> void:
	pass
	
func enter() -> void:
	player.animation_player.play( "Death" )
	#Audio.play_spatial_sound( DEATH_AUDIO, player.global_position, true )
	Audio.play_music( null )
	var timer = player.get_tree().create_timer(2.5)
	timer.timeout.connect(_on_timeout_backup)
	
	await player.animation_player.animation_finished
	_show_game_over_safe()
	pass
	
func _on_timeout_backup() -> void:
	_show_game_over_safe()

func _show_game_over_safe() -> void:
	# Evita chamar duas vezes se o timer e a animação acabarem quase juntos
	if PlayerHub.has_method("show_game_over"):
		PlayerHub.show_game_over()
		# Opcional: Desativa o player para não processar mais nada
		player.process_mode = Node.PROCESS_MODE_DISABLED
	
func exit() -> void :
	pass
	
func handle_input( _event : InputEvent ) -> PlayerState:

	return null
	
func process( _delta: float ) -> PlayerState:
		
	return null
	
func physics_process( _delta: float ) -> PlayerState:
	player.velocity = Vector2.ZERO
	return null
