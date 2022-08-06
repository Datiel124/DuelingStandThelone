extends Projectile

export var maxBounces : int = 1;
export var elasticity : float = 0.9;
var bounces : int = 0
export var explodeOnBounce : bool = false;
export var explodeOnPlayer : bool = true;

func doprojectilestuff(delta: float) -> void:
	#Server - tell all of the clients where this bullet should 'actually' be.
	if get_tree().is_network_server():
		rpc("syncpos", global_transform, Velocity)
	
	look_at(global_transform.origin + Velocity, Vector3.UP)
	var hit = move_and_collide(Velocity * delta)
	if hit && (get_tree().is_network_server() || get_tree().get_network_connected_peers().size() <= 0):
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
			if explodeOnPlayer:
	#				print("i hit a player i die")
				var explosionname = "explosion" + str(randi())
				rpc("explode", explosionname, global_transform.origin)
				explode(explosionname, global_transform.origin)
				rpc("cleanup")
				queue_free()
				return
		
		if bounces >= maxBounces:
#			print("too many bounces i die")
			var explosionname = "explosion" + str(randi())
			rpc("explode", explosionname, global_transform.origin)
			explode(explosionname, global_transform.origin)
			rpc("cleanup")
			queue_free()
		
		if explodeOnBounce:
#			print("booom")
			var explosionname = "explosion" + str(randi())
			rpc("explode", explosionname, global_transform.origin)
			explode(explosionname, global_transform.origin)
		
		Velocity = Velocity.bounce(hit.normal) * elasticity
		bounces += 1
	Velocity.y -= delta * gravitymult * 98

remote func explode(uniquename : String, pos):
#	print("Bang!")
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

remote func cleanup():
	queue_free()
