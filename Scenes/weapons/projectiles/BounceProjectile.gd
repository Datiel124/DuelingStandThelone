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
			
			#damage target
			col.rpc("Damage", damage)
			col.Damage(damage)
			
			#explode if needed
			if explodeOnPlayer:
	#				print("i hit a player i die")
				var explosionname = "explosion" + str(randi())
				rpc("explode", explosionname, global_transform.origin)
				explode(explosionname, global_transform.origin)
				rpc("disableAll")
				disableAll()
				return
		
		if bounces >= maxBounces:
#			print("too many bounces i die")
			var explosionname = "explosion" + str(randi())
			rpc("explode", explosionname, global_transform.origin)
			explode(explosionname, global_transform.origin)
			rpc("disableAll")
			disableAll()
		
		if explodeOnBounce:
#			print("booom")
			var explosionname = "explosion" + str(randi())
			rpc("explode", explosionname, global_transform.origin)
			explode(explosionname, global_transform.origin)
		
		Velocity = Velocity.bounce(hit.normal) * elasticity
		bounces += 1
	Velocity.y -= delta * gravitymult * 98
