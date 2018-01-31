"""
Creates a quad with six different texture options for break animation
"""
extends MeshInstance

var textures = []

var mat = SpatialMaterial.new()

export(StreamTexture) var stage_1 = null
export(StreamTexture) var stage_2 = null
export(StreamTexture) var stage_3 = null
export(StreamTexture) var stage_4 = null
export(StreamTexture) var stage_5 = null
export(StreamTexture) var stage_6 = null

func clear_stop():
	self.translation = Vector3(-10, 0, 0)

func set_step(tex_index):
	mat.albedo_texture = textures[tex_index - 1]
	self.material_override = mat

func _ready():
	var st = SurfaceTool.new()
	mat.flags_transparent = true

	textures = [stage_1, stage_2, stage_3, stage_4, stage_5, stage_6]
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Front Face
	st.add_uv(Vector2(1,1))
	st.add_vertex(Vector3(0,0,1) + Vector3(0, 0, 0.1))
	
	st.add_uv(Vector2(1,0))
	st.add_vertex(Vector3(0,1,1) + Vector3(0, 0, 0.1))
	
	st.add_uv(Vector2(0,1))
	st.add_vertex(Vector3(1,0,1) + Vector3(0, 0, 0.1))
	
	st.add_uv(Vector2(0,1))
	st.add_vertex(Vector3(1,0,1) + Vector3(0, 0, 0.1))
	
	st.add_uv(Vector2(1,0))
	st.add_vertex(Vector3(0,1,1) + Vector3(0, 0, 0.1))
	
	st.add_uv(Vector2(0,0))
	st.add_vertex(Vector3(1,1,1) + Vector3(0, 0, 0.1))
	
	st.index()
	st.generate_normals()
	self.set_mesh(st.commit())
	
	self.clear_stop()

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
