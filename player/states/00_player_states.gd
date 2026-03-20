@icon("res://icon.png")
class_name PlayerState extends Node

var player : Player
var next_state : PlayerState

#region /// state references
@onready var idle: PlayerStateIdle = %Idle
@onready var run: PlayerStateRun = %Run
@onready var jump: PlayerStateJump = %Jump
@onready var fall: PlayerStateFall = %Fall
@onready var crouch: PlayerStateCrouch = %Crouch
#endregion

# What happens when this state is initialized?
func init() -> void:
	print("init! ", name)
	pass
	
# What happens when this state is initialized?
func enter() -> void:
	print("enter: ", name)
	pass
	
# What happens when we exit state?
func exit() -> void :
	print("exit: ", name)
	pass
	
# What happens when an input is pressed?
func handle_input( _event : InputEvent ) -> PlayerState:
	return next_state
	
#What happens each process tick in this state?
func process( _delta: float ) -> PlayerState:
	return next_state
	
#What happens each physics_process tick in this state?
func physics_process( _delta: float ) -> PlayerState:
	return next_state
