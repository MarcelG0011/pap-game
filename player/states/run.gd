class_name PlayerStateRun extends PlayerState

func init() -> void:
	pass
	
func enter() -> void:
	player.animation_player.play( "Run" )
	pass
	
func exit() -> void :
	pass
	
func handle_input( _event : InputEvent ) -> PlayerState:
	# ↓ + JUMP → descer da plataforma
	if _event.is_action_pressed( "jump" ):
		if Input.is_action_pressed("down") \
		and player.one_way_plataform_ray_cast.is_colliding():
			print("[RUN] Descendo de plataforma com DOWN+JUMP")
			player.position.y += 10
			return fall
		else:
			return jump
	return next_state
	
func process( _delta: float ) -> PlayerState:
	if player.direction.x == 0:
		return idle
	
	# Verifica crouch enquanto corre
	if Input.is_action_pressed("down") and player.is_on_floor():
		return crouch
		
	return next_state
	
func physics_process( _delta: float ) -> PlayerState:
	player.velocity.x = player.direction.x * player.move_speed
	
	if not player.is_on_floor():
		return fall
		
	return next_state
