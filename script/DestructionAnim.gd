extends Node

export(ParticlesMaterial) var explode_material = null
export var particle_life = 0.4
export var particle_amount = 10

func particle_boom(x, y, tile_mat):
	var pos = Vector3(x + 0.5, y + 0.5, 0)
	
	var spat = Spatial.new()
	spat.set_translation(pos)
	
	var particle = Particles.new()
	particle.set_one_shot(true)
	particle.set_explosiveness_ratio(1)
	
	var particle_mesh = PrismMesh.new()
	particle_mesh.set_size(Vector3(0.1, 0.1, 0.1))
	particle.draw_pass_1 = particle_mesh
	
	explode_material.set_color(tile_mat.albedo_color)
	particle.set_process_material(explode_material)
	
	particle.set_lifetime(particle_life)
	particle.set_amount(particle_amount)
	
	spat.add_child(particle)
	
	$Sounds/Crumble.play()
	
	get_node("/root/Root").add_child(spat)
	
	# Delete the created nodes in 5 seconds
	GarbageCollector.add_trash(spat, 5)

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
