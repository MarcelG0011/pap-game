class_name PlayerStateJump extends PlayerState
@export var jump_velocity: float = 450.0

func init() -> void:
	pass
	
func enter() -> void:
	player.animation_player.play( "Jump" )
	#player.add_debug_indicator( Color.LIME_GREEN )
	player.velocity.y = -jump_velocity
	
	# Check if this is a buffer jump
	if player.previous_state == fall and not Input.is_action_pressed("jump"):
		await get_tree().physics_frame
		player.velocity.y *= 0.5
		player.change_state( fall )
	
	pass
	
func exit() -> void :
	#player.add_debug_indicator( Color.YELLOW )
	pass
	
func handle_input( event : InputEvent ) -> PlayerState:
	if event.is_action_released("jump"):
		player.velocity.y *= 0.5
		return fall
	return next_state
	
func process( _delta: float ) -> PlayerState:
	return next_state
	
func physics_process( _delta: float ) -> PlayerState:
	if player.is_on_floor():
		return idle
	elif player.velocity.y >= 0:
		return fall
	player.velocity.x = player.direction.x * player.move_speed
	return next_state
