"""
Adds a left, right, back and bottom walls, ensuring that the player never falls off the map
"""
extends MeshInstance

onready var chunk = get_node("/root/Root/Chunk")

export(SpatialMaterial) var material = null

func _ready():
	var st = SurfaceTool.new()
	var vertices = PoolVector3Array()
	
	vertices.append(Vector3(0, 0, 16))
	vertices.append(Vector3(0, chunk.rows + 16, 16))
	vertices.append(Vector3(0, 0, 0))
	vertices.append(Vector3(0, 0, 0))
	vertices.append(Vector3(0, chunk.rows + 16, 16))
	vertices.append(Vector3(0, chunk.rows + 16, 0))
	
	vertices.append(Vector3(0, 0, 0))
	vertices.append(Vector3(0, chunk.rows + 16, 0))
	vertices.append(Vector3(chunk.cellsPerRow, 0, 0))
	vertices.append(Vector3(chunk.cellsPerRow, 0, 0))
	vertices.append(Vector3(0, chunk.rows + 16, 0))
	vertices.append(Vector3(chunk.cellsPerRow, chunk.rows + 16, 0))
	
	vertices.append(Vector3(chunk.cellsPerRow, 0, 0))
	vertices.append(Vector3(chunk.cellsPerRow, chunk.rows + 16, 16))
	vertices.append(Vector3(chunk.cellsPerRow, 0, 16))
	vertices.append(Vector3(chunk.cellsPerRow, chunk.rows + 16, 0))
	vertices.append(Vector3(chunk.cellsPerRow, chunk.rows + 16, 16))
	vertices.append(Vector3(chunk.cellsPerRow, 0, 0))
	
	vertices.append(Vector3(0, 0, 0))
	vertices.append(Vector3(chunk.cellsPerRow, 0, 0))
	vertices.append(Vector3(chunk.cellsPerRow, 0, 16))
	vertices.append(Vector3(chunk.cellsPerRow, 0, 16))
	vertices.append(Vector3(chunk.cellsPerRow, 0, 0))
	vertices.append(Vector3(0, 0, 16))
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(material)
	for vert in vertices:
		st.add_vertex(vert)
	
	st.generate_normals()
	st.index()
	
	var mesh = st.commit()
	var col_shape = ConcavePolygonShape.new()
	col_shape.set_faces(mesh.get_faces())
	$StaticBody/CollisionShape.set_shape(col_shape)
	
	self.set_mesh(mesh)

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
