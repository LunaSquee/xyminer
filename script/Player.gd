"""
Deals with everything to do with the player.
"""
extends KinematicBody

# Easy access nodes
onready var camera = get_node("Camera")
onready var downRay = get_node("Down")
onready var upRay = get_node("Up")
onready var flashlight = get_node("Flashlight")

onready var chunk = get_node("../Chunk")
onready var break_anim = get_node("../CrackBox")

var ground_level = 0

# Jumping
var jump = false
var jump_power = 0

var fall_duration = 0

# Editor-available variables
export var gravity = 0.5
export var walk_speed = 16
export var jump_velocity = 18

export(ParticlesMaterial) var explode_material = null
export var particle_life = 0.4
export var particle_amount = 10

export(StreamTexture) var pickaxe = null
export(StreamTexture) var pickaxe_red = null
export(StreamTexture) var pickaxe_green = null

# Raycasting
const ray_length = 15
var mine_start = false
var from
var to

# Player Stats
var inventory = {}
var props = {
	"Bomb": 1,
	"Torch": 1
}
var money = 1000

# Pickaxe stats
# `delay` is ticks until `strength` is subtracted from tile's damage value
var pickaxe_level = 1
var pickaxe_delay = 10
var pickaxe_strength = 1
var pickaxe_health_max = 250
var pickaxe_health = 250

# Currently breaking tile
# {"x": 0, "y": 0}
var breaking = null
var break_clock = 0

signal inventory_changed
signal block_mined

func reposition():
	self.set_translation(Vector3(10, ground_level + 2, 0.8))

# Create particle effect when block breaks
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
	flashlight.spot_range = 7
	ground_level = chunk.rows
	reposition()
	
	camera.translation = Vector3(0, 2, 10)
	camera.rotation_degrees = Vector3(-10, 0, 0)

func _process(delta):
	if self.translation.y < 0:
		reposition()

	if not downRay.is_colliding():
		if not jump:
			fall_duration += 1
			self.move_and_collide(Vector3(0, -gravity - (fall_duration / 100), 0))
	else:
		fall_duration = 0
		if Input.is_action_just_pressed("game_jump"):
			jump = true
			jump_power = jump_velocity
	
	if jump and upRay.is_colliding():
		jump = false
	
	var velocity = Vector3(0, 0, 0)
	
	if not breaking:
		if Input.is_action_pressed("game_right"):
			velocity.x = walk_speed
		elif Input.is_action_pressed("game_left"):
			velocity.x = -walk_speed
		else:
			velocity.x = 0
	else:
		velocity.x = 0
		jump = false
	
	if jump:
		velocity.y = jump_velocity - (jump_velocity - jump_power)
		jump_power -= 1
		
		if jump_power <= 0:
			jump = false
	
	self.move_and_slide(velocity)
	
	if self.translation.x < camera.translation.z:
		camera.translation.x = camera.translation.z - self.translation.x
	elif self.translation.x > chunk.cellsPerRow - camera.translation.z:
		camera.translation.x = chunk.cellsPerRow - self.translation.x - camera.translation.z
	else:
		camera.translation.x = 0
	
	if self.translation.y > ground_level:
		if pickaxe_health < pickaxe_health_max:
			pickaxe_health += 5
			pickaxe_health = clamp(pickaxe_health, 0, pickaxe_health_max)

func block_distance (block):
	var vector = Vector2(self.translation.x, self.translation.y)
	var div = block - vector
	return abs(floor(sqrt(div.x*div.x + div.y*div.y)))

var step = 1

func _can_mine(block):
	if block_distance(block) > 2:
		return false

	var x = block.x
	var y = block.y

	var tile = chunk.getTileAt(x, y)

	if not tile:
		return false
	
	if pickaxe_health == 0:
		return false
	
	if tile.damage == -1:
		return false
	
	if chunk.getTileAt(x + 1, y) and chunk.getTileAt(x - 1, y) and chunk.getTileAt(x, y + 1) and chunk.getTileAt(x, y - 1):
		return false
	
	return true

func chunk_modify (block):
	if breaking:
		return
	
	if not _can_mine(block):
		return
	
	var tile = chunk.getTileAt(block.x, block.y)
	var t = chunk.get_tile_info(tile)
	
	breaking = block
	break_clock = pickaxe_delay
	
	$Sounds/Pickaxe.play()
	
	break_anim.set_step(1)
	break_anim.set_translation(Vector3(block.x, block.y, 0))

func _physics_process(delta):
	# Do breaking animation
	if breaking:
		var tile = chunk.getTileAt(breaking.x, breaking.y)
		var t = chunk.get_tile_info(tile)
		
		break_clock -= 1
		
		if break_clock <= 0:
			# Damage the tile
			# destroyed is true when the tile was set to null
			pickaxe_health -= 1
			if pickaxe_health <= 0:
				pickaxe_health = 0
				if breaking:
					breaking = null
					break_anim.clear_stop()
					$Sounds/Pickaxe.stop()
					$Sounds/PickaxeBreak.play()
					return
			
			var destroyed = chunk.damage_tile(breaking.x, breaking.y, pickaxe_strength)
			
			if destroyed:
				# Increment tile count in inventory
				if not inventory.has(t.name):
					inventory[t.name] = 1
				else:
					inventory[t.name] += 1
				
				# Reset
				$Sounds/Pickaxe.stop()
				particle_boom(breaking.x, breaking.y, t.material)
				breaking = null
				break_anim.clear_stop()
				
				# Refresh inventory
				self.emit_signal("block_mined", t)
				self.emit_signal("inventory_changed")
			else:
				# Reset clock
				break_clock = pickaxe_delay
				
				# Set crack texture based on damage percentage
				var percent = floor((float(tile.damage) / float(t.strength)) * 100)
				if percent > 80:
					break_anim.set_step(1)
				elif percent >= 64:
					break_anim.set_step(2)
				elif percent >= 48:
					break_anim.set_step(3)
				elif percent >= 32:
					break_anim.set_step(4)
				elif percent >= 16:
					break_anim.set_step(5)
				elif percent >= 0:
					break_anim.set_step(6)
	
	# Raycasting
	if from and to:
		var space_state = get_world().get_direct_space_state()
		var result = space_state.intersect_ray( from, to, [ self ] )
		
		if (not result.empty()):
			from = null
			to = null
			
			var block = Vector2(int(result.position.x), int(result.position.y))
			
			# Start breaking
			if Input.is_mouse_button_pressed(1):
				chunk_modify(block)
			else:
				# Set cursor
				if breaking:
					Input.set_custom_mouse_cursor(pickaxe)
				elif _can_mine(block):
					Input.set_custom_mouse_cursor(pickaxe_green)
				else:
					Input.set_custom_mouse_cursor(pickaxe_red)

func _input(ev):
	# Start raycasting on mouse motion/click
	if ev is InputEventMouseMotion or ev is InputEventMouseButton:
		from = camera.project_ray_origin(ev.position)
		to = from + camera.project_ray_normal(ev.position) * ray_length