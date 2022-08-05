extends Spatial

var explosion_bodies

export var max_damage : float
export var impulse: float #pushes out from center
export var v_impulse : float #pushes up/down
export var boom_radius : float = 1

export var damage_Falloff : Curve = preload('res://TextureAssets/curves/linear_falloff.tres')#replace with a pre-made curve resource
export var impulse_Falloff : Curve = preload('res://TextureAssets/curves/spherical_falloff.tres') #replace with a pre-made curve resource

var body_check = false

func _ready() -> void:
	$explosionArea.scale *= boom_radius
	force_update_transform()
	yield(get_tree(), 'physics_frame')
	yield(get_tree(), 'physics_frame')
	if get_tree().is_network_server():
		rpc("explode")
		explode()
	else:
		if get_tree().get_network_connected_peers().size() <= 0:
			explode()

remote func explode():
	$Particles.emitting = true
	explosion_bodies = $explosionArea.get_overlapping_bodies()
	for b in explosion_bodies:
		var dist = global_transform.origin.distance_to(b.global_transform.origin)
		var dir = global_transform.origin.direction_to(b.global_transform.origin)
		var damagemult = damage_Falloff.interpolate(dist / boom_radius)
		var impulsemult = impulse_Falloff.interpolate(dist / boom_radius)
		if b.is_in_group("Players"):
			b.Velocity += (dir * impulsemult * impulse)
			b.Velocity.y += v_impulse * impulsemult
			print(b.Velocity)
			b.rpc("Damage", (max_damage * damagemult))
			b.Damage(max_damage * damagemult)
	yield(get_tree().create_timer($Particles.lifetime + 1.0), 'timeout')
	queue_free()
