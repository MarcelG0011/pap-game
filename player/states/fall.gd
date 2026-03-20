class_name PlayerStateFall extends PlayerState

func init() -> void:
	pass
	
func enter() -> void:
	# Verifica se a animação existe antes de tocar
	if player.animation_player.has_animation("Fall"):
		player.animation_player.play( "Fall" )
	pass
	
func exit() -> void:
	pass
	
func handle_input( _event : InputEvent ) -> PlayerState:
	return next_state
	
func process( _delta: float ) -> PlayerState:
	return next_state
	
func physics_process( _delta: float ) -> PlayerState:
	if player.is_on_floor():
		# Se está a segurar DOWN quando aterra, vai para crouch
		if Input.is_action_pressed("down"):
			return crouch
		else:
			return idle
			
	player.velocity.x = player.direction.x * player.move_speed
	return next_state
