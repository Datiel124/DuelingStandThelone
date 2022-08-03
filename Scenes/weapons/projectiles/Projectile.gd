extends KinematicBody
class_name Projectile, 'res://DEV/class_icons/projectile.png'

var Velocity : Vector3 = Vector3.ZERO

var spawnpos : Vector3

export(PackedScene) var Explosion
export var impactPush : float = 0.0; #force in direction of Velocity
export var impactLaunch : float = 0.0; #force upward
export var impactAdditive : bool = true;

export var damage : float = 25.0;
export var gravitymult : float = 0.0;
export var explodeOnTimeout : bool = false;

func _ready() -> void:
	spawnpos = global_transform.origin

func _physics_process(delta: float) -> void:
	look_at(global_transform.origin + Velocity, Vector3.UP)
	var hit = move_and_collide(Velocity)
	if hit:
		var col = hit.collider
		if col is Player:
			if impactAdditive:
				var launchdir = impactLaunch * Velocity.normalized()
				col.Velocity += Vector3(launchdir.x, launchdir.y + impactLaunch, launchdir.z);
			else:
				var launchdir = impactLaunch * Velocity.normalized()
				col.Velocity = Vector3(launchdir.x, launchdir.y + impactLaunch, launchdir.z);
			col.Damage(damage)
			explode()
	Velocity.y -= delta * gravitymult * 98

func explode():
	if Explosion:
		var kabommies = Explosion.instance()
		get_parent().add_child(kabommies)
		kabommies.global_transform = global_transform
	queue_free()

func _on_lifetime_timeout() -> void:
	if explodeOnTimeout:
		explode()
	else:
		queue_free()
	pass # Replace with function body.
