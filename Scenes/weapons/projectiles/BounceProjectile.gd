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
	if !useAdvancedTrail:
		if hit:
			$meshtrail2.translation = Vector3(0, 0, 0.5) * min(hit.travel.length(), global_transform.origin.distance_to(spawnpos))
			$meshtrail2.scale = Vector3(1, min(hit.travel.length(), global_transform.origin.distance_to(spawnpos)) * basicTrailLength, 1)
		else:
			$meshtrail2.translation = Vector3(0, 0, 0.5) * min(Velocity.length() * delta, global_transform.origin.distance_to(spawnpos)) * basicTrailLength
			$meshtrail2.scale = Vector3(1, min(Velocity.length() * delta, global_transform.origin.distance_to(spawnpos))  * basicTrailLength, 1)
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
			
			#explode if needed
			if explodeOnPlayer:
	#				print("i hit a player i die")
				rpc("explode", global_transform.origin)
				explode(global_transform.origin)
				rpc("disableAll")
				disableAll()
				return
		
		if bounces >= maxBounces:
#			print("too many bounces i die")
			rpc("explode", global_transform.origin)
			explode(global_transform.origin)
			rpc("disableAll")
			disableAll()
			return
		
		if explodeOnBounce:
#			print("booom")
			rpc("explode", global_transform.origin)
			explode(global_transform.origin)
		
		Velocity = Velocity.bounce(hit.normal) * elasticity
		bounces += 1
	Velocity.y -= delta * gravitymult * 98


remote func explode(pos):
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


func _on_lifetime_timeout() -> void:
	if explodeOnTimeout:
		if get_tree().is_network_server() || get_tree().get_network_connected_peers().size() <= 0:
			rpc("explode", global_transform.origin)
			explode(global_transform.origin)
			
			rpc("disableAll")
			disableAll()
	else:
		if get_tree().is_network_server() || get_tree().get_network_connected_peers().size() <= 0:
			rpc("disableAll")
			disableAll()
	pass # Replace with function body.
