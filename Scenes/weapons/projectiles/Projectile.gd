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
export var stunDuration : float = 0.5;

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
	#only the server can validate a hit
	if hit && (get_tree().is_network_server() || get_tree().get_network_connected_peers().size() <= 0):
		#only the server should let the projectile explode
		var col = hit.collider
		collisionnormal = hit.normal
		if col is Player:
			if col.get_network_master() == shooter:
				#prevent player from shooting themself
				return
			
			#velocity additive or set
			if impactAdditive:
				var launchdir = impactLaunch * Velocity.normalized()
				col.rpc("setVelocity", col.Velocity + Vector3(launchdir.x, launchdir.y + impactLaunch, launchdir.z))
				col.setVelocity(col.Velocity + Vector3(launchdir.x, launchdir.y + impactLaunch, launchdir.z))
			else:
				var launchdir = impactLaunch * Velocity.normalized()
				col.rpc("setVelocity", Vector3(launchdir.x, launchdir.y + impactLaunch, launchdir.z))
				col.setVelocity(Vector3(launchdir.x, launchdir.y + impactLaunch, launchdir.z))
			
			#stun target
			if stunDuration > 0:
				col.rpc("Stun", 0.0, stunDuration)
				col.Stun(0.0, stunDuration)
			#damage target
			col.rpc("Damage", damage)
			col.Damage(damage)
		
		#explode on hit
		var explosionname = "explosion" + str(randi())
		rpc("explode", explosionname, global_transform.origin)
		explode(explosionname, global_transform.origin)
	Velocity.y -= delta * gravitymult * 98


remote func syncpos(t : Transform, velocity):
	global_transform = t
	Velocity = velocity


remote func explode(uniquename : String, pos):
	if Explosion and is_physics_processing():
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
	rpc("disableAll")
	disableAll()


remote func disableAll():
	$corona.emitting = false
	$trail.emitting = false
	set_physics_process(false)
	$MeshInstance.visible = false
	$CollisionShape.disabled = true
	$Loop.stop()
	yield(get_tree().create_timer($trail.lifetime + 0.1), 'timeout')
	if get_tree().is_network_server() || get_tree().get_network_connected_peers().size() <= 0:
		rpc("cleanup")
		cleanup()


remote func cleanup():
	queue_free()


func _on_lifetime_timeout() -> void:
	if explodeOnTimeout:
		var a = "explodet" + str(randi())
		if get_tree().is_network_server() || get_tree().get_network_connected_peers().size() <= 0:
			rpc("explode", a, global_transform.origin)
			explode(a, global_transform.origin)
	else:
		rpc("disableAll")
		disableAll()
	pass # Replace with function body.
