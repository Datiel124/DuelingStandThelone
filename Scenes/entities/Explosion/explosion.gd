extends Spatial

var explosion_bodies

export var max_damage : float
export var impulse: float #pushes out from center
export var v_impulse : float #pushes up/down
export var radius : float = 1

export var damage_Falloff : Curve = preload('res://TextureAssets/curves/linear_falloff.tres')#replace with a pre-made curve resource
export var impulse_Falloff : Curve = preload('res://TextureAssets/curves/spherical_falloff.tres') #replace with a pre-made curve resource

var body_check = false

func _ready() -> void:
	yield(get_tree(), 'idle_frame')
	explode()

func explode():
	explosion_bodies = $explosionArea.get_overlapping_bodies()
	for b in explosion_bodies:
		var dist = global_transform.origin.distance_to(b.global_transform.origin)
		var dir = global_transform.origin.direction_to(b.global_transform.origin)
		var damagemult = damage_Falloff.interpolate(dist / radius)
		var impulsemult = impulse_Falloff.interpolate(dist / radius)
		if b.is_in_group("Players"):
			b.Velocity += dir * impulsemult
			b.Velocity.y += v_impulse * impulsemult
			b.Damage(max_damage * damagemult)
	queue_free()
