extends Node

#woody
#cracky
#elastic
#crumbly
var error = false
var version = 0.1
var save = {player={}, objects={}, mods={},map={}}
var save_timer = 0
var chunk #noderef functions
var main #noderef functions
var WaEditor #noderef functions
var ui #noderef functions
var Loader #noderef functions
var chunks = {}
var chunk_size=8#16
var player
var objects = {}
var viewport_items = {}
var game_paused = true
var world_name = ""

var world = {name="earth",mapgen="super_flatland",meta={}}
var game
var map = {}
var meta = {}
var settings = {
		update_chunk_rules=[Vector3(-1,0,0),Vector3(1,0,0),Vector3(0,0,-1),Vector3(0,0,1),Vector3(0,-1,0),Vector3(0,1,0)],
		ganerate_chunk_range = 4,
		max_update_nodes = 512,
		save_timeout = 5,
		unload_chunk_distance = 100,
		item_drop_timeout = 300,
	}

var default_node_id = 7
var current_mapgen # funcref
var register = {
	items = {
		max_count = 1,
		"wieldhand":{name="wieldhand",
		type = "item",
		max_count = 1,
		inv_image=load("res://game/textures/wieldhand.png"),
			item_capabilities = {
				punch_interval = 1,
				damage = 1,
				groups = {crumbly=1},
			},
		},
		"default:stone_pick":{name="default:stone_pick",
		max_count = 1,
		type = "item",
		inv_image=load("res://game/textures/default_pick_stone.png"),
			item_capabilities = {
				punch_interval = 1,
				damage = 1,
				durability = 100,
				groups = {cracky=1},
			},
		},
		"default:stone_hoe":{name="default:stone_hoe",
		max_count = 1,
		type = "item",
		inv_image=load("res://game/textures/default_hoe_stone.png"),
			item_capabilities = {
				punch_interval = 1,
				damage = 1,
				durability = 100,
				groups = {crumbly=1},
			}
		},
		"default:stone_shovel":{name="default:stone_shovel",
		max_count = 1,
		type = "item",
		inv_image=load("res://game/textures/default_shovel_stone.png"),
			item_capabilities = {
				punch_interval = 1,
				damage = 1,
				durability = 100,
				groups = {crumbly=2},
			}
		},
		"default:axe_stone":{name="default:axe_stone",
		max_count = 1,
		type = "item",
		inv_image=load("res://game/textures/default_axe_stone.png"),
			item_capabilities = {
				punch_interval = 1,
				damage = 1,
				durability = 100,
				groups = {woody=1},
			}
		},
		"default:stick":{name="default:stick",
		max_count = 100,
		type = "item",
		inv_image=load("res://game/textures/default_stick.png"),
		groups = {"stick":1},
		},
	},
	nodes = {
		none={id=0,name="none",drawtype="none",tiles=[],type="node",groups={},max_count=100,},
		air={id=1,name="air",drawtype="none",tiles=[],collidable=false,solid_surface=false,type="node",groups={},max_count=100,},
		default={id=2,name="default",drawtype="default",tiles=[load("res://game/textures/default.png")],type="node",groups={cracky=1},max_count=100,},
	},
	id = {0:"none",1:"air",2:"default"}
}
var default_node = {
	texture = load("res://game/textures/default.png"),
	uv = [Vector2(0,0),Vector2(0,1),Vector2(1,1),Vector2(1,0)],
	dir = [Vector3(0,1,0),Vector3(0,-1,0),Vector3(1,0,0),Vector3(-1,0,0),Vector3(0,0,-1),Vector3(0,0,1)],
	faces = [
		[Vector3(1,0,0),Vector3(1,0,1),Vector3(0,0,1),Vector3(0,0,0)], #up y+
		[Vector3(0,-1,0),Vector3(0,-1,1),Vector3(1,-1,1),Vector3(1,-1,0)], #down y-
		[Vector3(1,0,0),Vector3(1,-1,0),Vector3(1,-1,1),Vector3(1,0,1)], #north x+
		[Vector3(0,0,1),Vector3(0,-1,1),Vector3(0,-1,0),Vector3(0,0,0)], #south x-
		[Vector3(0,0,0),Vector3(0,-1,0),Vector3(1,-1,0),Vector3(1,0,0)], #east z+
		[Vector3(1,0,1),Vector3(1,-1,1),Vector3(0,-1,1),Vector3(0,0,1)], #west z-
	]
}

func _init():
	set_process(false)

func register_node(def):
	var id = register.id.size()
	if def.get("tiles") != null:
		for i in range(0,def.tiles.size()):
			var t = def.tiles[i]
			if t is String:
				var l = load(t)
				if l is StreamTexture:
					def.tiles[i] = l
	
	def.id = 				id
	def.type =				"node"
	def.drop =				def.get("drops")
	def.drawtype =			"normal"			if def.get("drawtype") == null else def.drawtype
	def.groups =			{}					if def.get("groups") == null else def.groups
	def.max_count =			100					if def.get("max_count") == null else def.max_count
	def.replaceable =		false				if def.get("replaceable") == null else def.replaceable
	def.collidable =		true				if def.get("collidable") == null else def.collidable
	def.transparent =		false				if def.get("transparent") == null else def.transparent
	def.solid_surface =		false				if def.get("solid_surface") == null else def.solid_surface
	def.touchable =			false				if def.get("touchable") == null else def.touchable
	def.activatable =		false				if def.get("activatable") == null else def.activatable
	def.tiles =				[]					if def.get("tiles") == null else def.tiles
	#on_activate func ref
	
	
	register.id[id] = def.name
	register.nodes[def.name] = def

func world_main(change=false):
	Loader.start(100,{0:"World",1:"Saves",2:"Mods",3:"Preparing the map"})
	if change:
		save_data()
		world_quit(false,false)
		world.meta = {}
	game = Spatial.new()
	main.add_child(core.game)
	var w = load("res://engine/chunk/chunk.tscn").instance()
	game.add_child(w)
	Loader.setprogress(1)
	load_data()
	load_player()
	Loader.setprogress(2)
	WaEngine.scan()
	if core.error:
		Loader.end()
		return
	WaEngine.init()
	Loader.setprogress(3)
	current_mapgen = funcref(mapgen,world.mapgen)
	set_process(true)
	mapgen.set_process(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	ui.visible = true
	game_paused = false
	get_tree().paused = false
	yield(get_tree().create_timer(1),"timeout")
	var l = chunk.chunks_in_progress.size()
	var s = l
	Loader.start(l,{0:"loading map"})
	while l > 0:
			l = chunk.chunks_in_progress.size()
			Loader.setprogress(s-l)
			yield(get_tree().create_timer(0),"timeout")

func world_quit(quit=false,to_mainmanu=true):
	core.save_data()
	if quit:
		get_tree().quit()
		return
	ui.visible = false
	WaEditor.visible = false
	set_process(false)
	mapgen.set_process(false)
	chunk.queue_free()
	game.queue_free()
	game = null
	player.object.queue_free()
	player = null
	map.clear()
	meta.clear()
	chunks.clear()
	objects.clear()
	WaEngine.nodes.clear()
	chunk.chunks_in_progress.clear()
	if to_mainmanu:
		var manu = load("res://engine/MainManu/MainManu.tscn").instance()
		main.add_child(manu)

func game_pause():
	game_paused = game_paused == false
	get_tree().paused = game_paused
	if game_paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		ui.get_node("manu").visible = true
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		ui.get_node("manu").visible = false
func add_object(ob,type="",url=null):
	var id = 0
	while objects.get(id) != null:
		id += 1
	objects[id] = {
		name = str(id),
		id = id,
		type = type,
		inventory = {main=new_inventory(1)},
		object = ob,
		meta = {},
		url = url,
	}
	return objects[id]

func load_objects():
	for i in save.objects:
		var s = save.objects[i]
		objects[s.id] = {}
		var o = objects[s.id]
		o.id = s.id
		o.name = s.name
		o.type = s.type
		o.inventory = s.inventory
		o.url = s.url
		o.meta = s.meta
		o.object = load(o.url).instance()
		o.object.transform.origin = s.pos
		o.object.rotation = s.rotation
		o.object.scale = s.scale
		inv_remove_invalid_items(s.inventory)
		game.add_child(o.object)
		if o.object.has_method("on_load"):
			o.object.on_load(o)

func load_player(name:String="player"):
	player = {
		player=true,
		name = name,
		id = 0,
		right_item = null,
		left_item = null,
		inventory = {
			main=new_inventory(32),
			craft=new_inventory(9),
			craftoutput=new_inventory(1)	
		},
		slot_index = 0,
		hotbar_count = 8,
		right_slot = 4,
		left_slot = 0,
		object = load("res://engine/player/player.tscn").instance(),
		meta = {}
	}
	var s = save.player
	player.object.player = player

	if s != null and s.size() > 0:
		player.object.transform.origin = s.pos
		player.object.rotation = s.rotation
		for i in s:
			player[i] = s[i]
		inv_remove_invalid_items(player.inventory)
	else:
		player.object.transform.origin = Vector3(0,2,0)
		player.inventory={
				main=core.new_inventory(32,[
				core.itemstack("default:chest",{count=10}),
				core.itemstack("default:stone_pick"),
			]),
			
			craft=core.new_inventory(9),
			craftoutput=core.new_inventory(1)
		}
	game.add_child(player.object)

func save_player_objects():
	if player != null:
		var sp = {}
		sp.slot_index = player.slot_index
		sp.right_slot = player.right_slot
		sp.left_slot = player.left_slot
		sp.pos = player.object.transform.origin
		sp.inventory = player.inventory
		sp.rotation = player.object.rotation
		sp.meta = player.meta
		save.player = sp
		
	var ob2s = {}
	for i in objects:
		var o = objects[i]
		if o.get("object") != null and o.url != null and is_instance_valid(o.object):
			var s = {}
			s.id = o.id
			s.name = o.name
			s.type = o.type
			s.inventory = o.inventory
			s.url = o.url
			s.meta = o.meta
			s.pos = o.object.global_transform.origin
			s.rotation = o.object.rotation
			s.scale = o.object.scale
			ob2s[i] = s
		else:
			objects.erase(i)
		save.objects = ob2s
		
func load_file(path):
	var file = File.new()
	if not file.file_exists(path):
		return
	file.open(path,file.READ)
	var l = file.get_var()
	file.close()
	return l

func save_file(path,s):
	var D = Directory.new()
	var dir = path.get_base_dir().get_file()
	if D.dir_exists(str("user://",dir)) == false:
		D.make_dir(str("user://",dir))
	var file = File.new()
	file.open(str(path),file.WRITE_READ)
	file.store_var(s)
	file.close()

func load_data():
	var s = load_file(str("user://worlds/",world_name,".mworld"))
	save.mods = s.mods
	save.player = s.player
	if s.get(world.name):
		world = s[world.name].world
		save.objects = s[world.name].objects
		save.map = s[world.name].map.duplicate()
		meta = s[world.name].meta.duplicate()
		load_objects()
	else:
		world = world
		save.objects = {}
		save.map = {}
		meta = {}
	return true

func save_data():
	if world_name == "":
		return
	save_player_objects()
	var s = load_file(str("user://worlds/",world_name,".mworld"))
	if s == null:
		s = {}
	s.player = save.player
	s.mods = save.mods
	s[world.name] = {
		world=world,
		objects=save.objects,
		meta=meta,
		map=save.map,
	}
	save_file(str("user://worlds/",world_name,".mworld"),s)

func delete_data(wn=world_name):
	var d = Directory.new()
	d.remove(str("user://worlds/",wn,".mworld"))

func _process(delta):
	save_timer += delta
	if save_timer > settings.save_timeout:
		save_timer = 0
		save_data()

func get_pointed_pos():
	var pos = player.object.get_translation()
	var aim = player.object.get_node("head/Camera").get_global_transform().basis
	var hpos = player.object.get_node("head").get_translation()
	#var lpos = (pos + hpos+aim.z).round()
	for i in range(-1,-500,-1):
		var p = (pos + hpos+(aim.z*Vector3(i*0.01,i*0.01,i*0.01)))#.round()
		var rp = p.round()
		var id = map.get(rp)
		var reg = get_node_reg(id)
		if reg != null and reg.get("drawtype") != "none" and reg.get("collidable") != false:
				if (p.x >= rp.x-0.5 and p.x <= rp.x+0.5) and (p.y >= rp.y-0.5 and p.y <= rp.y+0.5) and (p.z >= rp.z-0.5 and p.z <= rp.z+0.5):
					return {inside=rp,outside=p}
		#lpos = rp
	return {inside=null,outside=null}

func place_node(node,inside:bool=false):
	var pos = player.object.get_translation()
	var aim = player.object.get_node("head/Camera").get_global_transform().basis
	var hpos = player.object.get_node("head").get_translation()
	var lpos = (pos + hpos+aim.z).round()
	
	for i in range(-1,-500,-1):
		var p = (pos + hpos+(aim.z*Vector3(i*0.01,i*0.01,i*0.01)))#.round()
		var rp = p.round()
		var id = map.get(rp)
		var reg = get_node_reg(id)
		if reg != null and reg.get("drawtype") != "none" and reg.get("collidable") != false and chunk.get_chunk_at_pos(rp):
			if (p.x >= rp.x-0.5 and p.x <= rp.x+0.5) and (p.y >= rp.y-0.5 and p.y <= rp.y+0.5) and (p.z >= rp.z-0.5 and p.z <= rp.z+0.5):
				if get_node_reg(node).get("collidable") == false or (pos-hpos).distance_to(p) > 0.9 and (pos+hpos).distance_to(p) > 1:
					var pp = rp if inside == true or reg.get("replaceable") == true else lpos
					set_node({name=node,pos=pp})
					return true
				return false
		lpos = rp
	return false

func get_item_reg(v):
	var it = register.items.get(v)
	if it:
		return it
	elif v is Vector3:
		v = v.round()
		v = map.get(v)
	elif v is String:
		return register.nodes.get(v)
	var n = register.id.get(v)
	return register.nodes.get(n)

func get_node_reg(v):
	if v is Vector3:
		v = v.round()
		v = map.get(v)
	elif v is String:
		return register.nodes.get(v)
	var n = register.id.get(v)
	return register.nodes.get(n)
	
func set_node(def:Dictionary):# set node
	assert(typeof(def.get("pos")) == TYPE_VECTOR3 and typeof(def.get("name")) == TYPE_STRING,"ERROR: set_node: def.pos & def.name required!")
	var n = register.nodes.get(def.name)
	assert(n != null,str('ERROR: set_node: "',def.name,'"', " doesn't exists"))
	var rpos = def.pos.round()
	var reg = get_node_reg(def.name)
	node_removed(map[rpos],rpos)
	map[rpos] = reg.id
	save.map[rpos] = reg.id
	var cid = chunk.pos_to_chunkid(rpos)
	for r in settings.update_chunk_rules.size():
		var near_chunk = rpos+settings.update_chunk_rules[r]
		if chunk.pos_to_chunkid(near_chunk) != cid:
			chunk.update(near_chunk)
	chunk.update(rpos)
				
func inset_map_node_id(id,pos):
	map[pos] = id

func item2mesh(item, priority_render:bool = false):
	var reg = get_item_reg(item)
	var mesh = Mesh.new()
	var st = SurfaceTool.new()
	
	if reg.type == "node":
		var tiles = reg.tiles
		var tile
		if reg.drawtype == "none":
			return mesh
		for f in default_node.faces.size()+1:
			st.begin(Mesh.PRIMITIVE_TRIANGLE_FAN)
			var mat = SpatialMaterial.new()
			if tiles.size() >= f:
				tile = tiles[f-1]
			mat.flags_transparent = (reg.get("transparent") == true)
			mat.albedo_texture = tile
			st.set_material(mat)
			for v in range(0,4):
				st.add_uv(default_node.uv[v])
				st.add_vertex(default_node.faces[f-1][v]-Vector3(0.5,-0.5,0.5))#-Vector3(0,0,0.5)
			st.commit(mesh)
		st.clear()
	else:
		var texture = reg.inv_image
		var faces = default_node.faces
		var img = texture.get_data()
		var s = img.get_size()
		img.decompress()
		img.flip_y()
		img.flip_x()
		img.lock()
		var size = Vector3(0.075,0.075,0.075)
		for y in s.y:
			for x in s.x:
				var c = img.get_pixel(x,y)
				if c.a != 0:
					var f = [4,5]
					var mat = SpatialMaterial.new()
					mat.albedo_color = c
					mat.flags_no_depth_test = priority_render
					if y == s.y-1 or img.get_pixel(x,y+1).a == 0:
						f.push_back(0)
					if y == 0 or img.get_pixel(x,y-1).a == 0:
						f.push_back(1)
					if x == s.x-1 or img.get_pixel(x+1,y).a == 0:
						f.push_back(2)
					if x == 0 or img.get_pixel(x-1,y).a == 0:
						f.push_back(3)
					for n in f:
						st.begin(Mesh.PRIMITIVE_TRIANGLE_FAN)
						st.set_material(mat)
						for v in 4:
							st.add_vertex((faces[n][v]+Vector3(x-7,y-7,0))*size)
						st.commit(mesh)
		st.clear()
		img.unlock()
	return mesh

func new_inventory(size:int = 32,items:Array=[]):
	items.resize(size)
	return items

func itemstack(item:String,def:Dictionary={}):
	var reg = get_item_reg(item)
	if reg == null:
		return null
	var durability = 0 if reg.get("item_capabilities") == null or reg.item_capabilities.get("durability") == null else reg.item_capabilities.durability
	return {
		name = item if def.get("item") == null else def.get("item"),
		count = def.get("count") if def.get("count") != null and def.get("count") <= reg.max_count else reg.max_count,
		durability = durability if def.get("durability") == null else def.get("durability"),
		meta = {} if def.get("meta") == null else def.get("meta"),
	}
func item_groups(item):
	var it = register.items.get(item)
	var nu = register.nodes.get(item)
	if it:
		var cap = it.get("item_capabilities")
		if cap != null:
			return cap.groups
	elif nu:
		return nu.groups

func stack_2invitem(stack):
	var t = TextureRect.new()
	var reg = get_item_reg(stack.name)
	t.texture = item3Dimg(stack.name)
	#t.texture = reg.get("inv_image") if reg.type == "item" else reg.tiles[0]
	t.expand = true
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.rect_size = Vector2(100,100)
	t.rect_clip_content = true
	t.name = "item"
	var d = Node2D.new()
	d.add_child(t)
	
	var c = reg.get("item_capabilities")
	if c != null and c.get("durability") != null:
		var bar1 = ColorRect.new()
		bar1.rect_size = Vector2(100,3)
		bar1.rect_position = Vector2(0,96)
		bar1.color = Color(255,0,0)
		t.add_child(bar1)
		var bar2 = ColorRect.new()
		var d1 = float(stack.durability)/float(c.durability)
		bar2.rect_size = Vector2(100*d1,3)
		bar2.color = Color(0,255,0)
		bar1.add_child(bar2)
	else:
		var p = Label.new()
		p.text = str(stack.count)
		p.rect_size = Vector2(50,5)
		p.rect_position = Vector2(0,70)
		p.rect_scale = Vector2(2,2)
		p.align = HALIGN_RIGHT
		p.name = "text"
		t.add_child(p)
	return d

func setMeta(pos:Vector3,label,set=null):
	if label == null:
		meta.erase(pos)
		return
	meta[pos] = {} if meta.get(pos) == null else meta[pos]
	var lab = meta[pos].get(label)
	meta[pos][label] = {} if lab == null else meta[pos][label]
	if lab == null:
		meta[pos].erase(pos)
	else:
		meta[pos][label] = set
func getMeta(pos:Vector3,label=null):
	if meta.get(pos) == null or label == null:
		return
	return meta[pos].get(label)
	
func existsMeta(pos):
	return meta.get(pos) != null

func create_node_inventory(pos:Vector3,name,size:int=32,add_to_stack=null):
		meta[pos] = {} if meta.get(pos) == null else meta[pos]
		meta[pos].inventory = {} if meta[pos].get("inventory") == null else meta[pos].inventory
		meta[pos].inventory[name] = new_inventory(size,add_to_stack)

func get_inventory(ref,name):
	var inv
	if ref is Vector3:
		if meta.get(ref):
			if meta[ref].get("inventory") != null and meta[ref].inventory.get(name):
				inv = meta[ref].inventory[name]
	elif ref.get("player"):
		inv = ref.inventory[name]
	elif objects.get(ref.id):
		inv = ref.inventory[name]
	return inv

func get_inventory_stack(ref,name,i):
	var inv = get_inventory(ref,name)
	var stack = inv[i]
	if stack != null:
		var reg = get_item_reg(stack.name)
		if reg == null:
			inv[i] = null
		else:
			return stack

func add_to_inventory(ref,name,stack):
	var inv
	var reg = get_item_reg(stack.name)
	var stack2 = stack.duplicate()
	if reg == null:
		return stack2
	elif ref is Vector3:
		if meta.get(ref):
			if meta[ref].get("inventory") != null and meta[ref].inventory.get(name):
				inv = meta[ref].inventory[name]
	elif player.get(ref.name):
		inv = ref.inventory[name]
	elif objects.get(ref.id):
		inv = ref.inventory[name]
	else:
		return stack2
	var c = stack.count
	var m = reg.max_count
	
	for i in inv.size():
		var slot = inv[i]
		if slot != null and slot.name == stack.name:
			var can_add = m - slot.count
			if can_add <= c:
				slot.count += can_add
				c -= can_add
			else:
				slot.count += c
				c = 0
			stack2.count = c
			if c <= 0:
				return stack2
	for i in inv.size():
		var slot = inv[i]
		if slot == null:
			if m <= c:
				inv[i] = itemstack(reg.name,{count=m})
				c -= m
			else:
				inv[i] = itemstack(reg.name,{count=c})
				c = 0
			stack2.count = c
			if c <= 0:
				return stack2
	return stack2

func get_drop(name_pos_id):
	var reg = get_item_reg(name_pos_id)
	var drop = reg.get("drop")
	var drops = {}
	var a = {}
	if drop == null:
		drops[reg.name] = 1
	elif drop is String:
		drops[drop] = 1
	elif drop is Dictionary:
		for i in drop:
			var d = drop[i]
			if d.get("chance") == null or round(rand_range(0,d.chance)) == d.chance:
				var count = 1 if d.get("count") == null else d.count
				drops[i] = count if drops.get(i) == null else drops[i]+count
				if d.get("additional") == false:
					drops = {}
					drops[i] = count
					break
	for i in drops:
		a[i]=itemstack(i,{count=drops[i]})
	return a

func item3Dimg(item):
	var texture = viewport_items.get(item)
	if texture == null:
		var tex = load("res://engine/item_to_texture/item_to_texture.tscn").instance()
		add_child(tex)
		texture = tex.texture(item)
		viewport_items[item] = texture
	return texture
	
func spawn_drop_item(pos,stack,droper=null):
	var d = load("res://game/item_drop/item_drop.tscn").instance()
	var ob = add_object(d,"item_drop",d.filename)
	if d.has_method("on_spawn"):
		d.on_spawn(ob)
	d.spawn(pos,stack,droper,ob)
	add_child(d)
	return d

func inv_remove_invalid_items(inv):
	for list in inv:
		var i = 0
		for stack in inv[list]:
			if stack != null and get_item_reg(stack.name) == null:
				inv[list][i] = null
			i += 1
func Error(msg):
	error = true
	world_quit()
	main.get_node("exitmsg/center/text").text = msg
	main.move_child(main.get_node("exitmsg"),main.get_child_count())
	main.get_node("exitmsg").visible = true
	yield(get_tree().create_timer(0.01),"timeout")
	error = false
func option_flash(o,text="",color=Color(1,0,0,0.8),blacktext=false):
	var b = Node2D.new()
	b.z_index = 1000
	add_child(b)
	var u = ColorRect.new()
	u.rect_size = o.rect_size
	u.rect_position = o.rect_global_position
	u.color = color
	b.add_child(u)
	var l = Label.new()
	l.text = text
	l.align = Label.ALIGN_CENTER
	l.valign = Label.VALIGN_CENTER
	l.rect_size = o.rect_size
	u.add_child(l)
	u.rect_size.x = l.rect_size.x
	l.add_color_override("font_color",Color(0,0,0) if blacktext else Color(1,1,1))
	yield(get_tree().create_timer(1),"timeout")
	u.free()

func node_set(id,pos):
	var reg = get_node_reg(id)
	if reg.get("touchable"):
		var c = chunk.get_chunk_at_pos(pos)
		var a = Area.new()
		var col = CollisionShape.new()
		col.shape = BoxShape.new()
		col.scale = Vector3(0.51,0.51,0.51)
		c.add_child(a)
		a.add_child(col)
		a.name = str(var2str(pos),"touchable")
		a.global_transform.origin = pos
		a.connect("body_entered",self,"node_touch",[id,pos,true])
		a.connect("body_exited",self,"node_touch",[id,pos,false])
func node_removed(id,pos):
	var reg = get_node_reg(id)
	if reg.get("touchable"):
		var c = chunk.get_chunk_at_pos(pos)
		var n = str(var2str(pos),"touchable")
		if c.has_node(n):
			c.get_node(n).queue_free()
func node_touch(body,id,pos,touch):
	if not body is StaticBody:
		var reg = get_node_reg(id)
		for i in WaEngine.nodes:
			var ob = WaEngine.nodes[i]
			if ob.name == "register_node" and ob.options.touchable and ob.options.name == reg.name:
				if touch:
					WaEngine.next_connection(ob,"on_touch",body)
				else:
					WaEngine.next_connection(ob,"on_untouch",body)
				yield(get_tree().create_timer(0.1),"timeout")
				WaEngine.next_connection(ob,"pos",pos)
