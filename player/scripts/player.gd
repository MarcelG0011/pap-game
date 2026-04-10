class_name Player extends CharacterBody2D
const DEBUG_JUMP_INDICATOR = preload("uid://ygjffhhiqrxf")

#region /// Signals
signal damage_taken()
#endregion

#region /// On Ready Variables
@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_sprite: Sprite2D = %AttackSprite2D
@onready var collision_stand: CollisionShape2D = $CollisionStand
@onready var collision_crouch: CollisionShape2D = $CollisionCrouch
@onready var da_stand: CollisionShape2D = %DAStand
@onready var da_crouch: CollisionShape2D = %DACrouch
@onready var one_way_plataform_ray_cast: RayCast2D = $OneWayPlataformRayCast
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera: Camera2D = $Camera2D
@onready var attack_area: AttackArea = %AttackArea
@onready var damage_area: DamageArea = %DamageArea 
#endregion

#region /// Export Variables
@export var move_speed : float = 150
#endregion

#region /// State Machine Variables
var states : Array[ PlayerState ]
var current_state : PlayerState :
	get : 
		if states.is_empty():
			return null
		return states.front()
var previous_state : PlayerState :
	get : 
		if states.size() < 2:
			return null
		return states[ 1 ]
#endregion

#region ///Player Stats
var hp : float = 20 :
	set( value ):
		hp = clampf( value, 0, max_hp )
		Messages.player_health_changed.emit( hp, max_hp )
		
var max_hp : float = 20 :
	set( value ):
		max_hp = value
		Messages.player_health_changed.emit( hp, max_hp )
		
var dash : bool = false
var double_jump : bool = false
var ground_slam : bool = false
var morph_roll : bool = false
#endregion

#region /// Standard Variables
var direction : Vector2 = Vector2.ZERO
var gravity : float = 980
var gravity_multiplier : float = 1.0
#endregion

#region /// Death Variables
var is_dead : bool = false
#endregion

func _ready() -> void:
	if get_tree().get_first_node_in_group("Player") != self:
		self.queue_free()
	initialize_states()
	self.call_deferred("reparent", get_tree().root)
	Messages.player_healed.connect( _on_player_healed )
	Messages.back_to_title_screen.connect( queue_free )
	damage_area.damage_taken.connect( _on_damage_taken )
	hp = max_hp
	pass


func _unhandled_input( event: InputEvent ) -> void:
	if event.is_action_released( "jump" ):
		velocity.y *= 0.5
	if event.is_action_pressed( "attack" ):
		Messages.player_interacted.emit( self )
	#elif event.is_action_pressed( "pause" ):
		#get_tree().paused = true
		#var pause_menu :  = load("res://pause_menu/pause_menu.tscn").instantiate()
		#add_child( pause_menu )
		#return
	change_state( current_state.handle_input(event) )
	pass
	
func _process( _delta: float) -> void:
	update_direction()
	update_sprite_direction()
	if current_state:
		change_state( current_state.process( _delta ))
	queue_redraw()
	
func _physics_process(_delta: float) -> void:
	velocity.y += gravity * _delta * gravity_multiplier
	move_and_slide()
	if current_state:
		change_state(current_state.physics_process( _delta ) )

func initialize_states() -> void:
	states = []
	for c in $States.get_children():
		if c is PlayerState:
			states.append( c )
			c.player = self
	
	
	if states.size() == 0:
		push_error("No states found!")
		return
	
	for state in states:
		state.init()
	
	if current_state:
		change_state( current_state )
		current_state.enter()
		if $Label:
			$Label.text = current_state.name

func change_state( new_state : PlayerState ) -> void:
	if new_state == null:
		return
	elif new_state == current_state:
		return
	if current_state:
		current_state.exit()
	
	states.push_front( new_state )
	current_state.enter()
	states.resize( 3 )
	if $Label:
		$Label.text = current_state.name

func update_direction() -> void:
	var prev_direction : Vector2 = direction
	
	var x_axis = Input.get_axis("left", "right")
	var y_axis = Input.get_axis("up", "down")
	direction = Vector2(x_axis, y_axis)

	if prev_direction.x != direction.x:
		attack_area.flip( direction.x )
		if direction.x < 0:
			#LEFT
			sprite.flip_h = true 
			attack_sprite.flip_h = true
			attack_sprite.position.x = -24
		elif direction.x > 0:
			sprite.flip_h = false
			attack_sprite.flip_h = false
			attack_sprite.position.x = 24
	pass
	
func update_sprite_direction() -> void:
	if direction.x > 0:
		sprite.flip_h = false
	elif direction.x < 0:
		sprite.flip_h = true
		


func add_debug_indicator( color : Color = Color.RED) -> void:
	var d: Node2D = DEBUG_JUMP_INDICATOR.instantiate()
	get_tree().root.add_child( d )
	d.global_position = global_position
	d.modulate = color
	await get_tree().create_timer( 3.0 ).timeout
	d.queue_free()

func _on_player_healed( amount : float ) -> void:
	hp += amount
	pass

func _on_damage_taken( attack_area : AttackArea ) -> void:
	hp -= attack_area.damage
	damage_taken.emit()
	print( "Player took damage: ", hp )
	pass
