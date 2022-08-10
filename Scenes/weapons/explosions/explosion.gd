extends Spatial

var explosion_bodies

export var max_damage : float
export var impulse: float #pushes out from center
export var v_impulse : float #pushes up/down
export var lifetime : float = 5.0

export var additive : bool = true
export var damage_Falloff : Curve = preload('res://TextureAssets/curves/linear_falloff.tres')#replace with a pre-made curve resource
export var impulse_Falloff : Curve = preload('res://TextureAssets/curves/spherical_falloff.tres') #replace with a pre-made curve resource

var body_check = false

func _ready() -> void:
	$boom.pitch_scale += rand_range(-0.1, 0.1)
	if get_tree().is_network_server() || get_tree().get_network_connected_peers().size() <= 0:
		yield(get_tree(), 'physics_frame')
		yield(get_tree(), 'physics_frame')
		yield(get_tree(), 'physics_frame')
		rpc("explode")
		explode()

remote func explode():
	for i in $particles.get_children():
		if i is Particles:
			i.emitting = true
	for b in $explosionArea.get_overlapping_bodies():
		var dist = global_transform.origin.distance_to(b.global_transform.origin)
		var dir = global_transform.origin.direction_to(b.global_transform.origin)
		var damagemult = damage_Falloff.interpolate(dist / $explosionArea/explosionshape.shape.radius)
		var impulsemult = impulse_Falloff.interpolate(dist / $explosionArea/explosionshape.shape.radius)
		if b is Player && (get_tree().is_network_server() || get_tree().get_network_connected_peers().size() <= 0):
			var launchie = (dir * impulsemult * impulse) + (Vector3.UP * impulsemult * v_impulse)
			if additive:
				b.rpc("setVelocity", b.Velocity + Vector3(launchie))
				b.setVelocity(b.Velocity + launchie)
			else:
				b.rpc("setVelocity", launchie)
				b.setVelocity(launchie)
			
			b.rpc("Stun")
			b.Stun()
			
			b.rpc("Damage", (max_damage * damagemult))
			b.Damage(max_damage * damagemult)
			
	yield(get_tree().create_timer(lifetime), 'timeout')
	queue_free()
