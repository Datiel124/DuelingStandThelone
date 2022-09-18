extends Spatial
class_name Weapon, 'res://DEV/class_icons/gunicon.png'

onready var anim_player = $AnimationPlayer

export(Texture) var inventory_icon
#for the kill feed that might be added depending on the system
export(Texture) var kill_feed_icon
export(String) var WeaponName = "test_weapon"
export(PackedScene) var projectile
export var fullauto : bool = false 
export var cooldown = 0.2 setget setCooldown
export var knockbackforce : float = 0.0
func setCooldown(new):
	cooldown = new
	$cooldown.wait_time = new
export var bullet_count : int = 1
export var bullet_speed = 20.0;
export var bullet_spread : float = 2.5
onready var mesh = $MeshInstance

#overrides bullet damage and explosion on spawn if available
export var override_dmg = 0.0;
export(PackedScene) var override_explosion;

onready var b_hole = preload('res://Scenes/entities/BulletHole.tscn')
onready var spark = preload("res://Scenes/entities/Spark/spark.tscn")

func _ready() -> void:
	$cooldown.wait_time = cooldown

var shooting : bool = false
puppet var canShoot : bool = true

func stopShooting() -> void:
	shooting = false
	$cooldown.disconnect('timeout', self, "rpc_id")
	$cooldown.disconnect('timeout', self, "_InputFromPlayer")

func _InputFromPlayer(event:InputEvent) -> void:
	if !is_network_master():
		printerr("invalid Weapon access")
		return
	if fullauto:
		if event.is_action_released('fire') || !canShoot:
			#set shooting to false to disable autofire
			shooting = false
			if $cooldown.is_connected('timeout', self, 'rpc_id'):
				$cooldown.disconnect('timeout', self, "rpc_id")
				$cooldown.disconnect('timeout', self, "_InputFromPlayer")
	if $cooldown.time_left <= 0 && canShoot:
		if fullauto:
			if event.is_action_pressed('fire'):
				#set shooting to true to enable autofire
				shooting = true
				if !$cooldown.is_connected('timeout', self, 'rpc_id'):
					$cooldown.connect('timeout', self, "rpc_id", [1, "_InputFromPlayer", event])
					$cooldown.connect('timeout', self, "_InputFromPlayer", [event])
		if event.is_action_pressed('fire'):
			rpc_unreliable("playNewSound")
			playNewSound()
			for i in bullet_count:
				var transforms : Transform = $ProjectileSpawn.global_transform
				transforms.basis = transforms.basis.rotated(transform.basis.x, rand_range(deg2rad(-bullet_spread), deg2rad(bullet_spread))).rotated(transform.basis.z, rand_range(deg2rad(-bullet_spread), deg2rad(bullet_spread))).rotated(transform.basis.y, rand_range(deg2rad(-bullet_spread), deg2rad(bullet_spread)))
				rpc_id(1, "fire", transforms)
				fire(transforms)


func _physics_process(delta: float) -> void:
	var camray = RayCast.new()
	camray.collision_mask = 0b11
	get_tree().get_root().add_child(camray)
	camray.global_transform = get_viewport().get_camera().get_global_transform()
	camray.cast_to = Vector3.FORWARD * 5000
	camray.force_raycast_update()
	if camray.is_colliding():
		$ProjectileSpawn.look_at(camray.get_collision_point(), Vector3.UP)
	else:
		$ProjectileSpawn.look_at(camray.global_transform.origin + -camray.global_transform.basis.z * 100000, Vector3.UP)
	camray.queue_free()


signal spawnABullet(bullet)
remote func fire(muzzletf):
	#Clients- Play the animations. Do nothing else.
	if is_network_master():
		anim_player.stop()
		anim_player.play("BaseShoot")
		$cooldown.start(cooldown)
	if !get_tree().is_network_server() && get_tree().get_network_connected_peers().size() > 0:
		return
	#SERVER STUFF
	if projectile:
		createProjectile(muzzletf)
		rpc("createProjectile", muzzletf)
	
	for i in get_tree().get_network_connected_peers():
		if i != get_tree().get_rpc_sender_id():
			rpc_id(i, "fire", muzzletf)


remote func playNewSound():
	var newsound = $sounds/shoot.duplicate()
	$sounds.add_child(newsound)
	newsound.stream = $sounds.shoot_sounds[randi()%$sounds.shoot_sounds.size()]
	get_tree().create_timer(5.0).connect('timeout', newsound, 'queue_free')
	newsound.play()


remote func createProjectile(spawntransforms : Transform):
	var newproj :Projectile= projectile.instance()
	newproj.name += str(NetworkLobby.generate_network_instance_id(NetworkLobby.network_instance_name_id))
	emit_signal('spawnABullet', newproj)
	var pl : Player = newproj.get_parent().get_parent()
	newproj.add_collision_exception_with(pl)
	pl.rpc("setVelocity", pl.Velocity + global_transform.basis.z * knockbackforce)
	pl.setVelocity(pl.Velocity + global_transform.basis.z * knockbackforce) 
	pl.rpc("Stun", 0.0, 0.2)
	pl.Stun(0.0, 0.2)
	#Spawn the bullet locally, on the server.
	newproj.global_transform.origin = spawntransforms.origin
	newproj.Velocity = -spawntransforms.basis.z * bullet_speed
#	print(get_tree().get_rpc_sender_id())
	newproj.shooter = get_tree().get_rpc_sender_id()
	if override_dmg:
		newproj.damage = override_dmg
	if override_explosion:
		newproj.Explosion = override_explosion
