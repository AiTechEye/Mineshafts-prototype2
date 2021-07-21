extends Spatial

var timer = 0
var chunks_in_progress = {}
var progress2del = {}#ca t delete chunks in the for loop, remove it after instead
var dim = 0


func _init():
	core.chunk=self

func new_chunk(pos):
	var id = pos_to_chunkid(pos)
	var chunk_pos = to_chunk_pos(pos)
	var none = core.get_node_reg("none").id
	for x in range(-core.chunk_size/2,core.chunk_size/2):
		for y in range(-core.chunk_size/2,core.chunk_size/2):
			for z in range(-core.chunk_size/2,core.chunk_size/2):
				var p = chunk_pos+Vector3(x,y,z)
				var saved_node = core.save.map.get(p)
				core.inset_map_node_id(none if saved_node == null else saved_node,p)
	core.chunks[id] = MeshInstance.new()
	var chunk = core.chunks[id]
	chunk.transform.origin = chunk_pos
	add_child(chunk)
	var staticbody = StaticBody.new()
	staticbody.name = "body"
	chunk.add_child(staticbody)
	var collision = CollisionShape.new()
	collision.name = "collision"
	staticbody.add_child(collision)
	var timeout = Timer.new()
	timeout.wait_time = 10
	timeout.autostart = true
	timeout.connect("timeout",self,"chunk_timer",[id,chunk_pos])
	chunk.add_child(timeout)

func unload_chunk(id,chunk_pos):
	for x in range(-core.chunk_size/2,core.chunk_size/2):
		for y in range(-core.chunk_size/2,core.chunk_size/2):
			for z in range(-core.chunk_size/2,core.chunk_size/2):
				core.map.erase(chunk_pos+Vector3(x,y,z))
	core.chunks[id].queue_free()
	core.chunks.erase(id)

func chunk_timer(id,chunk_pos):
	if core.player.object.global_transform.origin.distance_to(chunk_pos) > core.settings.unload_chunk_distance:
		unload_chunk(id,chunk_pos)
		
func to_chunk_pos(pos):
	var c = core.chunk_size
	var s = core.chunk_size/2
	return ((pos+Vector3(s,s,s))/c).floor()*c

func chunk_loaded_at_pos(pos):
	var c = core.chunk_size
	var s = core.chunk_size/2
	var c_pos = ((pos+Vector3(s,s,s))/c).floor()
	return core.chunks.get(c_pos) != null

func get_chunk_at_pos(pos):
	var c = core.chunk_size
	var s = core.chunk_size/2
	var c_pos = ((pos+Vector3(s,s,s))/c).floor()
	return core.chunks.get(c_pos)
	
func pos_to_chunkid(pos):
	var c = core.chunk_size
	var s = core.chunk_size/2
	return ((pos+Vector3(s,s,s))/c).floor()
	
func get_chunk(id):
	return core.chunks.get(id)

func _process(delta):
	timer += delta
	if timer > 0.0:
		timer = 0
		
		for i in progress2del:
			chunks_in_progress.erase(i)
		progress2del.clear()
		var max_nodes = core.settings.max_update_nodes
		for di in chunks_in_progress:
			var data = chunks_in_progress.get(di)
			var chunk_mesh = get_chunk(data.chunkid)
			if chunk_mesh == null:
				data = chunks_in_progress.erase(di)
				continue
			for x in range(data.range_x.a,data.range_x.b):
				for y in range(data.range_y.a,data.range_y.b):
					for z in range(data.range_z.a,data.range_z.b):
						var lpos = Vector3(x,y,z)
						var id = core.map.get(lpos+data.chunk_pos)
						var n = core.register.id.get(id)# if id != null else "default"
						if n == null:
							core.map.erase(data.chunk_pos)
							core.save.map.erase(data.chunk_pos)
							unload_chunk(pos_to_chunkid(data.chunk_pos),data.chunk_pos)
							update(data.chunk_pos)
							return
						core.node_set(id,lpos+data.chunk_pos)
						max_nodes -= 1
						if max_nodes < 0:
							data.range_x.a = x
							data.range_y.a = y
							data.range_z.a = z
							return
						
						var reg = core.register.nodes.get(n)
						var tile = "" if reg.tiles.size() < 1 else reg.tiles[0]
						if reg.drawtype != "none":
							for f in core.default_node.faces.size():
								var neighbour_id = core.map.get(lpos+core.default_node.dir[f]+data.chunk_pos)
								var neighbour_name = core.register.id.get(neighbour_id) if neighbour_id != null else "default"
								var neighbour_reg = core.register.nodes.get(neighbour_name)
								
								if neighbour_reg == null:
									core.map.erase(lpos+core.default_node.dir[f]+data.chunk_pos)
									core.save.map.erase(lpos+core.default_node.dir[f]+data.chunk_pos)
									continue
								elif neighbour_id != id and neighbour_reg.get("solid_surface") == false:
									data.st.begin(Mesh.PRIMITIVE_TRIANGLE_FAN)
									var mat = SpatialMaterial.new()
									var transparent = reg.get("transparent") == true
									if f < reg.tiles.size():
										tile = reg.tiles[f]
									mat.albedo_texture = tile
									mat.flags_transparent = transparent 
									data.st.set_material(mat)
									#data.st.add_color(Color(0,1,1))
									var cmf = []
									for v in range(0,4):
										data.st.add_uv(core.default_node.uv[v])
										data.st.add_vertex(core.default_node.faces[f][v]+lpos)
										cmf.push_back(core.default_node.faces[f][v]+lpos)
									
									data.st.commit(data.mesh)
									if reg.get("collidable") != false:
										data.cst.begin(Mesh.PRIMITIVE_TRIANGLES)
										data.cst.add_triangle_fan(cmf)
										data.cst.commit(data.collision_mesh)
			data.st.clear()
			data.cst.clear()
			chunk_mesh.mesh = data.mesh
			chunk_mesh.get_node_or_null("body/collision").shape = data.collision_mesh.create_trimesh_shape()
			chunks_in_progress.erase(di)
			progress2del[di] = di
	
func update(pos):
	if get_chunk_at_pos(pos) == null:
		new_chunk(pos)
		core.current_mapgen.call_func(to_chunk_pos(pos))
		return
		
	var chunkid =  pos_to_chunkid(pos)
	var data = {
		vertex = {},
		mesh = Mesh.new(),
		collision_mesh = Mesh.new(),
		chunkid =  chunkid,
		chunk_pos = get_chunk(chunkid).transform.origin,
		st = SurfaceTool.new(),
		cst = SurfaceTool.new(),
		range_x = {a=-core.chunk_size/2,b=core.chunk_size/2},
		range_y = {a=-core.chunk_size/2,b=core.chunk_size/2},
		range_z = {a=-core.chunk_size/2,b=core.chunk_size/2},
	}
	chunks_in_progress[chunkid] = data
