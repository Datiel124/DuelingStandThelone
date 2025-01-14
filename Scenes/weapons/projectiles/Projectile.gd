extends KinematicBody
class_name Projectile, 'res://DEV/class_icons/projectile.png'

var Velocity : Vector3 = Vector3.ZERO
var shooter : int = -1
var spawnpos : Vector3

export(PackedScene) var Explosion
export var impactPush : float = 0.0; #force in direction of Velocity
export var impactLaunch : float = 0.0; #force upward
export var impactAdditive : bool = true;
export var stunDuration : float = 0.5;

export var damage : float = 25.0;
export var gravitymult : float = 0.0;
export var explodeOnTimeout : bool = false;

export(int, 0, 1440) var trailFadeDelay : int = 2
export var useAdvancedTrail : bool = false
export var basicTrailLength : float = 5.0
var fading : bool = false

signal on_spawn(proj)
signal on_collide(collision)
signal on_life_timeout()
signal on_explode()


func _ready() -> void:
	emit_signal('on_spawn', self)
	spawnpos = global_transform.origin
	$meshtrail.visible = useAdvancedTrail
	$meshtrail2.visible = !useAdvancedTrail


var collisionnormal : Vector3 = Vector3.UP
func _physics_process(delta: float) -> void:
	do_projectile_phys(delta)


func do_projectile_phys(delta: float) -> void:
	#Server - tell all of the clients where this bullet should 'actually' be.
	if get_tree().is_network_server():
		rpc_unreliable("syncpos", global_transform, Velocity)
	
	look_at(global_transform.origin + Velocity, Vector3.UP)
	var hit = move_and_collide(Velocity * delta)
	#only the server can validate a hit
	if !useAdvancedTrail:
		if hit:
			$meshtrail2.translation = Vector3(0, 0, 0.5) * min(hit.travel.length(), global_transform.origin.distance_to(spawnpos))
			$meshtrail2.scale = Vector3(1, min(hit.travel.length(), global_transform.origin.distance_to(spawnpos)) * basicTrailLength, 1)
		else:
			$meshtrail2.translation = Vector3(0, 0, 0.5) * min(Velocity.length() * delta, global_transform.origin.distance_to(spawnpos)) * basicTrailLength
			$meshtrail2.scale = Vector3(1, min(Velocity.length() * delta, global_transform.origin.distance_to(spawnpos))  * basicTrailLength, 1)
	if hit && (get_tree().is_network_server() || get_tree().get_network_connected_peers().size() <= 0):
		#only the server should let the projectile explode
		var col = hit.collider
		emit_signal('on_collide', hit)
		collisionnormal = hit.normal
		if col is Player:
			if col.get_network_master() == shooter:
				#prevent player from shooting themself
				return
			
			#velocity additive or setd
			if impactAdditive:
				var launchdir = impactPush * Velocity.normalized()
				col.rpc("setVelocity", col.Velocity + Vector3(launchdir.x, launchdir.y + impactLaunch, launchdir.z))
				col.setVelocity(col.Velocity + Vector3(launchdir.x, launchdir.y + impactLaunch, launchdir.z))
			else:
				var launchdir = impactPush * Velocity.normalized()
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
		rpc("explode", global_transform.origin)
		explode(global_transform.origin)
	Velocity.y -= delta * gravitymult * 98


remote func syncpos(t : Transform, velocity):
	global_transform = t
	Velocity = velocity


remote func explode(pos):
	emit_signal('on_explode')
	if Explosion and is_physics_processing():
		var kabommies = Explosion.instance()
		kabommies.name += str(NetworkLobby.generate_network_instance_id(NetworkLobby.network_instance_name_id))
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


func _process(delta: float) -> void:
	if fading:
		if useAdvancedTrail:
			$meshtrail.segments = max($meshtrail.segments - 2, 0)
			$meshtrail.base_width *= 0.9
		else:
			$meshtrail2.scale *= 0.0


remote func disableAll():
	set_physics_process(false)
	$corona.emitting = false
	$trail.emitting = false
	$ProjectileMesh.visible = false
	$CollisionShape.disabled = true
	$Loop.stop()
	for i in trailFadeDelay:
		#wait a couple physframes before fading out
		yield(get_tree(), 'physics_frame')
	fading = true
	yield(get_tree().create_timer($trail.lifetime + 0.1), 'timeout')
	if useAdvancedTrail:
		while($meshtrail.segments > 0):
			yield(get_tree(), 'idle_frame')
	else:
		while($meshtrail2.scale.y > 0.05):
			yield(get_tree(), 'idle_frame')
	if get_tree().is_network_server() || get_tree().get_network_connected_peers().size() <= 0:
		rpc("cleanup")
		cleanup()


remote func cleanup():
	queue_free()


func _on_lifetime_timeout() -> void:
	emit_signal('on_life_timeout')
	if explodeOnTimeout:
		if get_tree().is_network_server() || get_tree().get_network_connected_peers().size() <= 0:
			rpc("explode", global_transform.origin)
			explode(global_transform.origin)
	else:
		rpc("disableAll")
		disableAll()
	pass # Replace with function body.
