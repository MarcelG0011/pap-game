class_name PlayerStateIdle extends PlayerState

func init() -> void:
	pass
	
func enter() -> void:
	player.animation_player.play( "Idle" )
	player.dash_count = 0
	pass
	
func exit() -> void :
	pass
	
func handle_input( _event : InputEvent ) -> PlayerState:

	if _event.is_action_pressed( "dash" ) and player.can_dash():
		return dash
	if _event.is_action_pressed( "attack" ):
		return attack
	# ↓ + JUMP → descer da plataforma
	if _event.is_action_pressed( "jump" ):
		if Input.is_action_pressed( "down" ) \
		and player.one_way_plataform_ray_cast.is_colliding():
			player.position.y += 10
			return fall
		else:
			return jump
	return next_state
	
func process( _delta: float ) -> PlayerState:
	# Verifica crouch PRIMEIRO
	if Input.is_action_pressed("down") and player.is_on_floor():
		return crouch
	
	if player.direction.x != 0:
		return run
		
	return next_state
	
func physics_process( _delta: float ) -> PlayerState:
	player.velocity.x = 0
	if not player.is_on_floor():
		return fall
	return next_state
