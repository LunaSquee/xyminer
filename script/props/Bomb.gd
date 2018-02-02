extends MeshInstance

export var radius = 5
export var damage = 50

var fuse = 100
var fused = false

onready var chunk = get_node("/root/Root/Chunk")

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func blow_up():
	var pos = Vector2(floor(self.translation.x), floor(self.translation.y))
	var explosion_candidates = []
	
	$Explode.play()
	$Crumble.play()
	
	for x in range(pos.x - radius, pos.x + radius):
		for y in range(pos.y - radius, pos.y + radius):
			var p = Vector2(x, y)
			var vec = pos - p
			var dist = abs(sqrt(vec.x*vec.x + vec.y*vec.y))
			if dist <= radius:
				explosion_candidates.append(p)
	
	for i in explosion_candidates:
		var vec = pos - i
		var dist = abs(sqrt(vec.x*vec.x + vec.y*vec.y))
		var dmg = damage - dist
		
		if not chunk.getTileAt(i.x, i.y):
			continue
		
		chunk.damage_tile(i.x, i.y, dmg)
	
	GarbageCollector.add_trash(self, 5)

func _process(delta):
	if not fused and fuse > 0:
		fuse -= 1
	
	if not fused and fuse == 0:
		fused = true
		blow_up()
	
	pass
