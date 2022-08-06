extends KinematicBody
class_name Projectile, 'res://DEV/class_icons/projectile.png'

var Velocity : Vector3 = Vector3.ZERO
var shooter : int = -1
var spawnpos : Vector3
var active : bool = true

export(PackedScene) var Explosion
export var impactPush : float = 0.0; #force in direction of Velocity
export var impactLaunch : float = 0.0; #force upward
export var impactAdditive : bool = true;

export var damage : float = 25.0;
export var gravitymult : float = 0.0;
export var explodeOnTimeout : bool = false;

func _ready() -> void:
	spawnpos = global_transform.origin

var collisionnormal : Vector3 = Vector3.UP
func _physics_process(delta: float) -> void:
	doprojectilestuff(delta)

func doprojectilestuff(delta: float) -> void:
	#Server - tell all of the clients where this bullet should 'actually' be.
	if get_tree().is_network_server():
		rpc("syncpos", global_transform, Velocity)
	
	look_at(global_transform.origin + Velocity, Vector3.UP)
	
	var hit = move_and_collide(Velocity * delta)
	if hit && (get_tree().is_network_server() || get_tree().get_network_connected_peers().size() <= 0):
		#only the server should let the projectile explode
		var col = hit.collider
		collisionnormal = hit.normal
		if col is Player:
			if col.get_network_master() == shooter:
				return
			if impactAdditive:
				var launchdir = impactLaunch * Velocity.normalized()
				col.Velocity += Vector3(launchdir.x, launchdir.y + impactLaunch, launchdir.z);
			else:
				var launchdir = impactLaunch * Velocity.normalized()
				col.Velocity = Vector3(launchdir.x, launchdir.y + impactLaunch, launchdir.z);
			col.rpc("Damage", damage)
			col.Damage(damage)
		var explosionname = "explosion" + str(randi())
		rpc("explode", explosionname, global_transform.origin)
		explode(explosionname, global_transform.origin)
	Velocity.y -= delta * gravitymult * 98

remote func syncpos(t : Transform, velocity):
	global_transform = t
	Velocity = velocity

remote func explode(uniquename : String, pos):
	if Explosion:
		var kabommies = Explosion.instance()
		kabommies.name = uniquename
		get_parent().add_child(kabommies)
		kabommies.global_transform.origin = pos
		var lookdir = collisionnormal
		if lookdir.is_equal_approx(Vector3.UP):
			kabommies.rotation_degrees.x = 90
		elif lookdir.is_equal_approx(Vector3.DOWN):
			kabommies.rotation_degrees.x = -90
		else:
			kabommies.look_at(global_transform.origin + lookdir,Vector3.UP)
	queue_free()


func _on_lifetime_timeout() -> void:
	if explodeOnTimeout:
		var a = "explodet" + str(randi())
		if get_tree().is_network_server() || get_tree().get_network_connected_peers().size() == 0:
			rpc("explode", a, global_transform.origin)
			explode(a, global_transform.origin )
			queue_free()
	else:
		rpc("queue_free")
		queue_free()
	pass # Replace with function body.
