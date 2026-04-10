@icon("res://general/icons/attack_area.svg")
class_name AttackArea
extends Area2D

@export var damage: float = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)  
	visible = false
	monitorable = false
	monitoring = false

func _on_body_entered(body: Node2D) -> void:
	# Detecta bodies (CharacterBody2D, StaticBody2D, etc)
	if body.has_method("take_damage"):
		body.take_damage(self)

func _on_area_entered(area: Area2D) -> void:
	# Detecta areas (DamageArea)
	if area is DamageArea:
		area.take_damage(self)

func activate(duration: float = 0.1) -> void:
	set_active(true)
	await get_tree().create_timer(duration).timeout
	set_active(false)

func set_active(value: bool = true) -> void:
	monitoring = value
	visible = value

func flip(direction_x: float) -> void:
	if direction_x > 0:
		scale.x = 1
	elif direction_x < 0:  
		scale.x = -1
