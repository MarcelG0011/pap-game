class_name PlayerStateDeath extends PlayerState

const DEATH_AUDIO = preload( "uid://5jwoq06142vu" )

func init() -> void:
	pass
	
func enter() -> void:
	player.animation_player.play( "Death" )
	Audio.play_spatial_sound( DEATH_AUDIO, player.global_position )
	Audio.play_music( null )
	await player.animation_player.animation_finished
	PlayerHub.show_game_over()
	pass
	
func exit() -> void :
	pass
	
func handle_input( _event : InputEvent ) -> PlayerState:

	return null
	
func process( _delta: float ) -> PlayerState:
		
	return null
	
func physics_process( _delta: float ) -> PlayerState:
	player.velocity.x = 0
	
	return null
