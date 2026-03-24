#Visual Effects
extends Node

const DUST_EFFECT = preload("uid://ceurnrkrxc63x")
signal camera_shook( strength : float)


#Create Dust Effects
func _create_dust_effects( pos : Vector2 ) -> DustEffect:
	var dust : DustEffect = DUST_EFFECT.instantiate()
	add_child( dust )
	dust.global_position = pos
	return dust
	
	
	pass
	
#Create Jump Dust
func jump_dust( pos : Vector2 ) -> void:
	var dust : DustEffect = _create_dust_effects( pos )
	dust.start( DustEffect.TYPE.JUMP )
	pass
	
#Create Land Dust
func land_dust( pos : Vector2 ) -> void:
	var dust : DustEffect = _create_dust_effects( pos )
	dust.start( DustEffect.TYPE.LAND )
	pass
	
#Hit Dust
func hit_dust( pos : Vector2 ) -> void:
	var dust : DustEffect = _create_dust_effects( pos )
	dust.start( DustEffect.TYPE.HIT )
	pass

func hit_particles( settings :  ) -> void:
	
	
	pass


func camera_shake( strength : float = 1.0 ) -> void:
	camera_shook.emit( strength )
	pass
