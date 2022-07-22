extends Spatial

var explosion_bodies

export var max_damage : float
export var impulse: float #pushes out from center
export var v_impulse : float #pushes up/down
export var radius : float = 1

export var damage_Falloff : Curve = Curve.new() #replace with a pre-made curve resource
export var impulse_Falloff : Curve = Curve.new() #replace with a pre-made curve resource

var body_check = false

func _physics_process(delta):
	explode()
	pass

func explode():
	explosion_bodies = $explosionArea.get_overlapping_bodies()

