class_name PlayerStateFall extends PlayerState

func init() -> void:
	pass
	
func enter() -> void:
	# Verifica se a animação existe antes de tocar
	if player.animation_player.has_animation("Fall"):
		player.animation_player.play( "Fall" )
		
		#var prev : PlayerState = player.previous_state
		#if prev == jump or prev == attack or prev == dash:
			#coyote_timer = 0
		#elif  player.previous_state == crouch:
			#coyote_timer = 0
			#player.jump_count = 1
		#else:
			#coyote_timer = coyopte_time
	pass
	
func exit() -> void:
	pass
	
func handle_input( _event : InputEvent ) -> PlayerState:
	if _event.is_action_pressed( "dash" ) and player.can_dash():
		return dash
	if _event.is_action_pressed( "attack" ):
		return attack
	return next_state
	
func process( _delta: float ) -> PlayerState:
	return next_state
	
func physics_process( _delta: float ) -> PlayerState:
	if player.is_on_floor():
		VisualEffects.land_dust( player.global_position )
		# Se está a segurar DOWN quando aterra, vai para crouch
		if Input.is_action_pressed("down"):
			return crouch
		else:
			return idle
			
	player.velocity.x = player.direction.x * player.move_speed
	return next_state
