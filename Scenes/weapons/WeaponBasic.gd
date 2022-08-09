extends Spatial
class_name Weapon, 'res://DEV/class_icons/gunicon.png'

onready var anim_player = $AnimationPlayer

export(String) var WeaponName = "test_weapon"
export(PackedScene) var projectile
export var fullauto : bool = false 
export var cooldown = 0.2 setget setCooldown
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
		$cooldown.start(cooldown)
	$sounds/shoot.stream = $sounds.shoot_sounds[randi()%$sounds.shoot_sounds.size()]
	$sounds/shoot.play()
	anim_player.stop()
	anim_player.play("BaseShoot")
	#Create projectile on the client-side.
	
	if !get_tree().is_network_server() && get_tree().get_network_connected_peers().size() > 0:
		return

#SERVER STUFF	
	if projectile:
		var id = "projectile" + str(randi())
		createProjectile(muzzletf, id, false)
		rpc("createProjectile", muzzletf, id)
	
	for i in get_tree().get_network_connected_peers():
		if i != get_tree().get_rpc_sender_id():
			rpc_id(i, "fire", muzzletf)

remote func createProjectile(spawntransforms : Transform, suffix : String, is_active : bool = true):
	var newproj :Projectile= projectile.instance()
	emit_signal('spawnABullet', newproj)
	newproj.name = "b-" + suffix
	#Spawn the bullet locally, on the server.
	newproj.global_transform.origin = spawntransforms.origin
	newproj.Velocity = -spawntransforms.basis.z * bullet_speed
	newproj.active = is_active
#	print(get_tree().get_rpc_sender_id())
	newproj.shooter = get_tree().get_rpc_sender_id()
	if override_dmg:
		newproj.damage = override_dmg
	if override_explosion:
		newproj.Explosion = override_explosion
