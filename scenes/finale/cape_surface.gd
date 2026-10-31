extends MeshInstance2D
## Draw the original body texture on a grid; only inspected free cloth vertices move.
var cloth_material: ShaderMaterial
func setup(body: Sprite2D) -> void:
 var atlas: AtlasTexture=body.texture
 texture=atlas.atlas
 var vertices:=PackedVector3Array()
 var uvs:=PackedVector2Array()
 var indices:=PackedInt32Array()
 const COLS=30
 const ROWS=34
 for y in ROWS+1:
  for x in COLS+1:
   var at:=Vector2(x*atlas.region.size.x/COLS,y*atlas.region.size.y/ROWS)
   vertices.append(Vector3(at.x+body.offset.x,at.y+body.offset.y,0))
   uvs.append((atlas.region.position+at)/texture.get_size())
 for y in ROWS:
  for x in COLS:
   var i:=y*(COLS+1)+x
   indices.append_array(PackedInt32Array([i,i+1,i+COLS+1,i+1,i+COLS+2,i+COLS+1]))
 var arrays:=[]
 arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX]=vertices
 arrays[Mesh.ARRAY_TEX_UV]=uvs
 arrays[Mesh.ARRAY_INDEX]=indices
 var surface:=ArrayMesh.new()
 surface.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 mesh=surface
 cloth_material=ShaderMaterial.new()
 cloth_material.shader=preload("res://scenes/finale/cape_surface.gdshader")
 cloth_material.set_shader_parameter("sheet_size",texture.get_size())
 material=cloth_material
 body.self_modulate.a=0
 body.add_child(self)
func sample(seconds: float, strength: float) -> void:
 cloth_material.set_shader_parameter("seconds",seconds)
 cloth_material.set_shader_parameter("strength",strength)
