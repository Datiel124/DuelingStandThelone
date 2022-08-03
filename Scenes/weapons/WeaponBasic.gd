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
export var bullet_speed = 20.0;

#overrides bullet damage and explosion on spawn if available
export var override_dmg = 0.0;
export(PackedScene) var override_explosion;

onready var b_hole = preload('res://Scenes/entities/BulletHole.tscn')
onready var spark = preload("res://Scenes/entities/Spark/spark.tscn")

func _ready() -> void:
	$cooldown.wait_time = cooldown

var shooting : bool = false
puppet var canShoot : bool = true
func _InputFromPlayer(event:InputEvent) -> void:
	if !is_network_master():
		printerr("invalid Weapon access")
		return
	if fullauto:
		if event.is_action_released('fire') || !canShoot:
			#set shooting to false to disable autofire
			shooting = false
			$cooldown.disconnect('timeout', self, "rpc_id")
			$cooldown.disconnect('timeout', self, "fire")
	if $cooldown.time_left <= 0 && canShoot:
		if fullauto:
			if event.is_action_pressed('fire'):
				#set shooting to true to enable autofire
				shooting = true
				rpc_id(1, "fire", $MuzzlePoint.global_transform)
				fire($MuzzlePoint.global_transform)
				$cooldown.connect('timeout', self, "rpc_id", [1, "fire"])
				$cooldown.connect('timeout', self, "fire")
		else:
			if event.is_action_pressed('fire'):
				rpc_id(1, "fire", $MuzzlePoint.global_transform)
				fire($MuzzlePoint.global_transform)

signal spawnABullet(bullet)
remote func fire(muzzletf : Transform):
	#Clients- Play the animations. Do nothing else.
	if is_network_master():
		$cooldown.start(cooldown)
	$sounds/shoot.stream = $sounds.shoot_sounds[randi()%$sounds.shoot_sounds.size()]
	$sounds/shoot.play()
	anim_player.stop()
	anim_player.play("BaseShoot")
	if !get_tree().is_network_server():
		return

#SERVER STUFF
	if projectile:
		var id = str(randi())
		rpc("createProjectile", muzzletf, id)
		createProjectile(muzzletf, id)
	for i in get_tree().get_network_connected_peers():
		if i != get_tree().get_rpc_sender_id():
			rpc_id(i, "fire", muzzletf)

remote func createProjectile(spawntransforms : Transform, suffix : String):
	var newproj :Projectile= projectile.instance()
	newproj.name = filename + suffix
	#Spawn the bullet locally, on the server.
	emit_signal('spawnABullet', newproj)
	newproj.global_transform.origin = spawntransforms.origin
	newproj.Velocity = -spawntransforms.basis.z * bullet_speed
	newproj.shooter = get_tree().get_rpc_sender_id()
	if override_dmg:
		newproj.damage = override_dmg
	if override_explosion:
		newproj.Explosion = override_explosion
	pass

