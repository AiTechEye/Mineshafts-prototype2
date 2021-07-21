extends Node

var timer = 1
var n2gc_timer = -0.01
var n2gc_time = 0
var mapgens = ["super_flatland","none","super_flatstoneland"]

func _ready():
	set_process(false)


func _process(delta):
	timer += delta
	if timer > n2gc_time and core.player != null:
		if n2gc_timer >= 1:
			n2gc_timer = 0
			n2gc_time = 1
		else:
			n2gc_timer += timer
		timer = 0
		
		var player = core.player
		var ppos = player.object.global_transform.origin
		var pos = core.chunk.to_chunk_pos(ppos)
		if core.chunk.get_chunk_at_pos(pos) == null:
			core.chunk.new_chunk(pos)
			core.current_mapgen.call_func(pos)
			n2gc_time = 0
			n2gc_timer = 0
		for i in range(1,core.settings.ganerate_chunk_range):
			var r = core.chunk_size*i
			var s = core.chunk_size
			for x in range(-r,r,s):
				for y in range(-r,r,s):
					for z in range(-r,r,s):
						pos = Vector3(x,y,z) + core.chunk.to_chunk_pos(ppos)
						if core.chunk.get_chunk_at_pos(pos) == null:
							core.chunk.new_chunk(pos)
							core.current_mapgen.call_func(pos)
							n2gc_time = 0
							n2gc_timer = 0
							
func none(pos):
	pass
	
func super_flatland(pos):
	var id
	var grassy = core.get_node_reg("default:grassy").id
	var dirt = core.get_node_reg("default:dirt").id
	var stone = core.get_node_reg("default:stone").id
	var air = core.get_node_reg("air").id
	var Y
	for x in range(-core.chunk_size/2,core.chunk_size/2):
		for y in range(-core.chunk_size/2,core.chunk_size/2):
			for z in range(-core.chunk_size/2,core.chunk_size/2):
				var p = Vector3(x,y,z)+pos
				Y = pos.y+y
				if core.map.get(p) != 0:
					continue
				elif Y == 0:
					id = grassy
				elif Y < -3:
					id = stone
				elif Y < 0:
					id = dirt
				else:
					id = air
				core.inset_map_node_id(id,p)
	core.chunk.update(pos)

func super_flatstoneland(pos):
	var id
	var stone = core.get_node_reg("default:cobble").id
	var air = core.get_node_reg("air").id
	var Y
	for x in range(-core.chunk_size/2,core.chunk_size/2):
		for y in range(-core.chunk_size/2,core.chunk_size/2):
			for z in range(-core.chunk_size/2,core.chunk_size/2):
				var p = Vector3(x,y,z)+pos
				Y = pos.y+y
				if core.map.get(p) != 0:
					continue
				elif Y <= 0:
					id = stone
				else:
					id = air
				core.inset_map_node_id(id,p)
	core.chunk.update(pos)
