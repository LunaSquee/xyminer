"""
Generates a `rows` * `cellsPerRow` 2D-in-3D mine
"""
extends MeshInstance

# Materials, customizable from the editor
export(SpatialMaterial) var sand = null
export(SpatialMaterial) var topsoil = null
export(SpatialMaterial) var dirt = null
export(SpatialMaterial) var rock = null
export(SpatialMaterial) var copper = null
export(SpatialMaterial) var iron = null
export(SpatialMaterial) var silver = null
export(SpatialMaterial) var gold = null
export(SpatialMaterial) var amethyst = null
export(SpatialMaterial) var emerald = null
export(SpatialMaterial) var sapphire = null
export(SpatialMaterial) var ruby = null
export(SpatialMaterial) var diamond = null
export(SpatialMaterial) var flawless_diamond = null

# Seed. Set to -1 to generate a random seed
export var generatorSeed = 0

# Rows (y axis)
export var rows = 32

# Columns (x axis)
export var cellsPerRow = 16

# All tiles, 2D array
var cells = []

# Materials (populated in _ready())
var materials = []

# Material strengths (Determines pickaxe required)
var strengths = [20, 30, 40, 50, 60, 90, 120, 140, 165, 170, 200, 250, 500]

# Names of the materials
var names = ["Sand", "Topsoil", "Dirt", "Rock", "Copper", "Iron", "Silver", "Gold", "Amethyst", "Emerald", "Sapphire", "Ruby", "Diamond", "Flawless Diamond"]

# Gem generator settings (reversed y)
# 0: Hotspot, 1: Minimum, 2: Maximum, 3: Percentage
var generators = [
	[6, 2, 24, 0.4, "Copper"],
	[12, 3, 30, 0.4, "Iron"],
	[18, 8, 42, 0.4, "Silver"],
	[24, 17, 46, 0.3, "Gold"],
	[30, 22, 49, 0.3, "Amethyst"],
	[36, 24, 52, 0.3, "Emerald"],
	[42, 33, 54, 0.26, "Sapphire"],
	[48, 37, 58, 0.23, "Ruby"],
	[54, 48, 60, 0.2, "Diamond"],
	[62, 53, 64, 0.16, "Flawless Diamond"]
]

# Set to true to regenerate the terrain next frame
var dirty = false

# Calculate generator data
func percent (gendata, r):
	var hs = gendata[0]
	var mm = gendata[1]
	var M = gendata[2]
	var p = gendata[3]
	var sub_percent = 0

	if r > M or r < mm:
		return 0
	elif hs == r:
		return p
	elif hs > r:
		sub_percent = p / (hs - mm + 1)
	else:
		sub_percent = p / (M + 1 - hs)

	var distance = abs(hs - r)
	return (p - distance * sub_percent)

# Pick a random mineral
func pick_mineral(r):
	var top = 0
	var picked = null
	for i in range(0, generators.size()):
		var minr = generators[i]
		
		var p = percent(minr, r)
		
		if p > 0:
			top = top + 100
		# top = top+ceil(percent(v, r)*100)
	
	if top == 0:
		return null
	
	var chosen = randi() % top + 1
	var prev = 0
	
	for i in range(0, generators.size()):
		var minr = generators[i]
		var p = percent(minr, r)
		if p > 0:
			prev = prev + ceil(p * 100)
			if chosen <= prev:
				picked = i

	return picked

# Pick a random dirt
func pick_dirt(t):
	var ran = randi() % 2
	var interval = float(rows) / 10
	var tile = 1
	if t <= interval / 10:
		tile = 1
	elif t <= interval * 2 / 10:
		if ran < 4:
			tile = 1
		else:
			tile = 2
	elif t <= interval * 3 / 10:
		if ran < 4:
			tile = 2
		else:
			tile = 1
	elif t <= interval * 4 / 10:
		tile = 2
	elif t <= interval * 5 / 10:
		if ran < 4:
			tile = 2
		else:
			tile = 3
	elif t <= interval * 6 / 10:
		if ran < 4:
			tile = 3
		else:
			tile = 2
	elif t <= interval * 7 / 10:
		tile = 3
	elif t <= interval * 8 / 10:
		if ran < 4:
			tile = 3
		else:
			tile = 4
	elif t <= interval * 9 / 10:
		if ran < 4:
			tile = 4
		else:
			tile = 3
	else:
		tile = 4
	
	return tile

# Get a tile from x, y
func getTileAt(x, y):
	if y < 0 or y >= cells.size():
		return null
	
	if x < 0 or x >= cellsPerRow:
		return null
	
	return cells[y][x]

# Set a tile at x, y with the index `num` in materials list (starting at 1)
func setTileAt(x, y, num):
	if y < 0 or y >= cells.size():
		return null
	
	if x < 0 or x >= cellsPerRow:
		return null

	# Re-generate next frame
	dirty = true

	if num == null:
		cells[y][x] = null
		return

	var strength = strengths[num - 1]
	cells[y][x] = {"tile": num, "damage": strength}

# Get the name, material and strength of a tile
func get_tile_info (tile):
	if not tile:
		return null
	
	var info = {}
	var tileIndex = tile.tile - 1
	
	info["name"] = names[tileIndex]
	info["material"] = materials[tileIndex]
	info["strength"] = strengths[tileIndex]
	
	return info

# Function for Player
func damage_tile (x, y, strength):
	var tile = getTileAt(x, y)
	
	if not tile:
		return null
	
	if tile.damage == -1:
		return null
	
	cells[y][x].damage -= strength
	
	if cells[y][x].damage <= 0:
		setTileAt(x, y, null)
		return true
	
	return false

func redraw():
	# Make sure we don't re-generate the mesh every frame
	dirty = false

	var mesh = Mesh.new()
	var st = SurfaceTool.new()

	for y in range(0, cells.size()):
		for x in range(0, cells[y].size()):
			st.begin(Mesh.PRIMITIVE_TRIANGLES)

			var tile = getTileAt(x, y)
			
			if not tile:
				continue
			
			var material = materials[tile['tile'] - 1]
			st.set_material(material)

			# Front Face
			st.add_uv(Vector2(1,1))
			st.add_vertex(Vector3(0,0,1) + Vector3(x, y, 0))
			
			st.add_uv(Vector2(1,0))
			st.add_vertex(Vector3(0,1,1) + Vector3(x, y, 0))
			
			st.add_uv(Vector2(0,1))
			st.add_vertex(Vector3(1,0,1) + Vector3(x, y, 0))
			
			st.add_uv(Vector2(0,1))
			st.add_vertex(Vector3(1,0,1) + Vector3(x, y, 0))
			
			st.add_uv(Vector2(1,0))
			st.add_vertex(Vector3(0,1,1) + Vector3(x, y, 0))
			
			st.add_uv(Vector2(0,0))
			st.add_vertex(Vector3(1,1,1) + Vector3(x, y, 0))
			
			if not getTileAt(x, y + 1):
				# Top Face
				st.add_uv(Vector2(1,1))
				st.add_vertex(Vector3(0,1,1) + Vector3(x, y, 0))
				
				st.add_uv(Vector2(1,0))
				st.add_vertex(Vector3(0,1,0) + Vector3(x, y, 0))
				
				st.add_uv(Vector2(0,1))
				st.add_vertex(Vector3(1,1,1) + Vector3(x, y, 0))
				
				st.add_uv(Vector2(0,1))
				st.add_vertex(Vector3(1,1,1) + Vector3(x, y, 0))
				
				st.add_uv(Vector2(1,0))
				st.add_vertex(Vector3(0,1,0) + Vector3(x, y, 0))
				
				st.add_uv(Vector2(0,0))
				st.add_vertex(Vector3(1,1,0) + Vector3(x, y, 0))
			
			if not getTileAt(x - 1, y):
				# Left Face
				st.add_uv(Vector2(1,1))
				st.add_vertex(Vector3(0,0,0) + Vector3(x, y, 0))
				
				st.add_uv(Vector2(1,0))
				st.add_vertex(Vector3(0,1,0) + Vector3(x, y, 0))
				
				st.add_uv(Vector2(0,1))
				st.add_vertex(Vector3(0,0,1) + Vector3(x, y, 0))
				
				st.add_uv(Vector2(0,1))
				st.add_vertex(Vector3(0,0,1) + Vector3(x, y, 0))
				
				st.add_uv(Vector2(1,0))
				st.add_vertex(Vector3(0,1,0) + Vector3(x, y, 0))
				
				st.add_uv(Vector2(0,0))
				st.add_vertex(Vector3(0,1,1) + Vector3(x, y, 0))
			
			if not getTileAt(x + 1, y):
				# Right Face
				st.add_uv(Vector2(1,1))
				st.add_vertex(Vector3(1,0,0) + Vector3(x, y, 0))
				
				st.add_uv(Vector2(0,1))
				st.add_vertex(Vector3(1,0,1) + Vector3(x, y, 0))
				
				st.add_uv(Vector2(1,0))
				st.add_vertex(Vector3(1,1,0) + Vector3(x, y, 0))
				
				st.add_uv(Vector2(1,0))
				st.add_vertex(Vector3(1,1,0) + Vector3(x, y, 0))
				
				st.add_uv(Vector2(0,1))
				st.add_vertex(Vector3(1,0,1) + Vector3(x, y, 0))
				
				st.add_uv(Vector2(0,0))
				st.add_vertex(Vector3(1,1,1) + Vector3(x, y, 0))
			
			if not getTileAt(x, y - 1):
				# Bottom Face
				
				st.add_uv(Vector2(0,0))
				st.add_vertex(Vector3(1,0,0) + Vector3(x, y, 0))
				
				st.add_uv(Vector2(1,0))
				st.add_vertex(Vector3(0,0,0) + Vector3(x, y, 0))
				
				st.add_uv(Vector2(0,1))
				st.add_vertex(Vector3(1,0,1) + Vector3(x, y, 0))
				
				st.add_uv(Vector2(0,1))
				st.add_vertex(Vector3(1,0,1) + Vector3(x, y, 0))
				
				st.add_uv(Vector2(1,0))
				st.add_vertex(Vector3(0,0,0) + Vector3(x, y, 0))
				
				st.add_uv(Vector2(1,1))
				st.add_vertex(Vector3(0,0,1) + Vector3(x, y, 0))
			
			st.generate_normals()
			st.index()
			
			st.commit(mesh)

	var col_shape = ConcavePolygonShape.new()
	col_shape.set_faces(mesh.get_faces())
	$Collision/ColShape.set_shape(col_shape)

	self.set_mesh(mesh)

func generate():
	if generatorSeed == -1:
		generatorSeed = OS.get_unix_time()
		print("Chunk Seed: " + str(generatorSeed))

	rand_seed(generatorSeed)

	cells = []
	for y in range(0, rows):
		var row = []
		for x in range(0, cellsPerRow):
			var select_cell = 1
			if y == 0:
				row.push_back({"tile": 4, "damage": -1})
				continue
			
			select_cell = pick_dirt(float(rows - y)/10)
			var mineral = pick_mineral(rows - y)
			
			if mineral:
				select_cell = mineral
			
			var strength = strengths[select_cell - 1]
			row.push_back({"tile": select_cell, "damage": strength})
		cells.push_back(row)

func _ready():
	materials = [sand, topsoil, dirt, rock, copper, iron, silver, gold, amethyst, emerald, sapphire, ruby, diamond, flawless_diamond]
	generate()
	redraw()

func _process(delta):
	if dirty:
		redraw()
