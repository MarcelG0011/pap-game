# res://general/breakable.gd
@tool
@icon("res://general/icons/breakable.svg")
class_name Breakable
extends Node2D

signal destroyed

@export var hp: float = 3
@export var fixed_hit_count: bool = false

@export_category("Particles")
@export var emission_offset: Vector2 = Vector2.ZERO
@export var hit_particles: Array[HitParticleSettings]
@export var destroy_particles: Array[HitParticleSettings]

@export_category("Audio")
@export var hit_audio: AudioStream = preload("uid://cco45r0h104du")
@export var destroy_audio: AudioStream = preload("uid://doi4dl1urc3ev")

var is_destroyed: bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	for c in get_children():
		if c is DamageArea:
			c.damage_taken.connect(_on_damage_taken)
	pass

func _on_damage_taken(attack_area: AttackArea) -> void:
	if is_destroyed:
		return
	
	# Calcula dano
	if fixed_hit_count:
		hp -= 1
	else:
		hp -= attack_area.damage
		
	var pos: Vector2 = global_position + emission_offset
	var dir: Vector2 = Vector2(1, -1)
	if attack_area.global_position.x > global_position.x:
		dir.x *= -1
	
	if hp > 0:
		# Ainda está vivo - efeito de hit
		Audio.play_spatial_sound(hit_audio, pos)
		for p in hit_particles:
			VisualEffects.hit_particles(pos, dir, p)
	else:
		# Morreu - efeito de destruição
		_destroy(pos, dir)
	pass
	
func _destroy(pos: Vector2, dir: Vector2) -> void:
	if is_destroyed:
		return
	
	is_destroyed = true
	
	# Som e partículas
	Audio.play_spatial_sound(destroy_audio, pos)
	for p in destroy_particles:
		VisualEffects.hit_particles(pos, dir, p)
	
	destroyed.emit()
	
	# Remove colisões
	clear_collision()
	
	# Animação de fade out
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color(modulate, 0), 0.4)
	await tween.finished
	
	# Remove da cena
	queue_free()
	pass
	
func clear_collision() -> void:
	for c in get_children():
		if c is StaticBody2D or c is CollisionShape2D:
			c.queue_free()
	pass
	
func _get_configuration_warnings() -> PackedStringArray:
	if not _check_for_damage_area():
		return ["Requires a DamageArea node!"]
	return []

func _check_for_damage_area() -> bool:
	for c in get_children():
		if c is DamageArea:
			return true
	return false
