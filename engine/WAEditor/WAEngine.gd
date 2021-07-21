extends Control
var paswc = "9n#3d!fnDSFP¤&(=)90&¤/TVba+v89H)(¤Hpo0F?)"
var nodes = {}
var tmpnodes = {}
var nodereg
var timer = 0
var events = 0
var stackoverflow = 400
var editor
func _ready():
	var e = load("res://engine/WAEditor/WAEditor.gd").new()
	nodereg = e.nodereg

func _process(delta):
	timer += delta
	if timer > 0.01:
		timer = 0
		events = 0

func scan(DIR="user://mods",getlist={},get=false):
	var d = Directory.new()
	d.open(DIR)
	d.list_dir_begin()
	var dir = d.get_next()
	while dir != "":
		if dir.begins_with(".") == false:
			var cd = str(d.get_current_dir(),"/",dir)
			var ex = dir.get_extension()
			if d.current_is_dir():
				getlist = scan(cd,getlist,get)
			elif ex == "mmode" or ex == "mmodt":
				getlist = load_mod(cd,getlist,get)
		dir = d.get_next()
	d.list_dir_end()
	return getlist

func reload_mod(s,edit=null):
	editor = edit
	var l = s.name.length()
	for id in nodes:
		if id.substr(0,l) == s.name:
			nodes.erase(id)
	if tmpnodes.get(s.name):
		for node in tmpnodes[s.name]:
			if is_instance_valid(node):
				node.free()
		tmpnodes[s.name] = null
	
	for id in s.data:
		var d = s.data[id]
		if nodereg.get(d.name) == null:
			core.Error(str("ERROR: invalid node: ",d.name))
			return
		d.mod_name = s.name
		d.mod_idname = str(s.name,":",id)
		nodes[d.mod_idname] = d

	for idname in nodes:
		var ob = nodes[idname]
		var def = nodereg.get(ob.name)
		if def.get("init") != null and idname.substr(0,l) == s.name:
			node_actions(ob,"init",null)

func load_mod(path,getlist,get=false):
	var file = File.new()
	var ex = path.get_extension()
	var s
	if ex == "mmodt":
		file.open(path,File.READ)
		s = str2var(file.get_as_text())
		file.close()
		if s is String:
			core.Error(str("ERROR: modfile not valid: ",path))
			return
	elif ex == "mmode":
		file.open_encrypted_with_pass(path,File.READ,paswc)
		s = file.get_var()
		file.close()
	if s != null:
		if get:
			s.path = path
			getlist[s.name] = s
			return getlist
		elif core.save.mods.get(s.name) != true:
			return
		for id in s.data:
			var d = s.data[id]
			if nodereg.get(d.name) == null:
				core.Error(str('A fatal error occorpted:\nMod "',s.name,'" is outdated (invalid node: "',d.name,'")\nCurrent game version: ',core.version,"\nBuild in version: ",s.game_version))
				return
			d.mod_name = s.name
			d.mod_idname = str(s.name,":",id)
			nodes[d.mod_idname] = d
	elif getlist != null:
		var fn = path.get_file()
		getlist[fn.replace(str(".",fn.get_extension()),"")] = {path=path,broken=true}
	return getlist
func init():
	for idname in nodes:
		var ob = nodes[idname]
		var def = nodereg.get(ob.name)
		if def.get("init") != null:
			node_actions(ob,"init",null)

func connection_flash(n):
	var u = ColorRect.new()
	u.rect_size = Vector2(10,10)
	u.rect_position = n.rect_global_position
	u.color = Color(1,1,1)
	core.add_child(u)
	yield(get_tree().create_timer(0.1),"timeout")
	u.free()

func next_connection(ob1,output:String,value=null):
	events += 1
	if events > stackoverflow:
		return

	if is_by_editor(ob1):
		var edob = editor.nodes[ob1.id]
		var edop = edob.options
		for op1name in ob1.options:
			var op1value = ob1.options[op1name]
			if op1value != null:
				var op2 = edop[op1name]
				op2.node.set(op2.method,op1value)
				#op2.node[op2.method] = op1value
		var out = edob.output.get(output)
		if out != null:
			connection_flash(out.node)
		
	var c = ob1.connections.get(output)
	if c != null:
		var outputs = c
		for ob2_input_key in outputs:
			var ob2_input = outputs[ob2_input_key]
			var ob2 = nodes[str(ob1.mod_name,":",ob2_input.id)]
			node_actions(ob2,ob2_input.name,value)

func tempnodes(ob,node):
	tmpnodes[ob.mod_name] = [] if tmpnodes.get(ob.mod_name) == null else tmpnodes[ob.mod_name]
	tmpnodes[ob.mod_name].push_back(node)

func text_to_groups(a):
	a = a.replace(" ","")
	var g = {}
	for i in a.split(",",false):
		var l = i.find("=")
		if l == -1:
			return str("invalid input: ",i)
		var name = i.substr(0,l)
		var n = i.substr(l+1,-1)
		var I = n.is_valid_integer()
		if name.is_valid_identifier() == false:
			return str("invalid name: ",name)
		elif I == false and n.is_valid_float() == false:
			return str("invalid value: ",n)
		var intn = int(n)
		g[name] = intn if I else float(n)
	return g
func text_to_drop(a):
	a = a.replace(" ","")
	var g = {}
	for d in a.split(";",false):
	
		var count = 1
		var additional = true
		var item = ""
		var chance = 10
	
		for i in d.split(",",false):
			var l = i.find("=")
			if l == -1:
				return str("invalid input: ",i)
			var name = i.substr(0,l)
			var n = i.substr(l+1,-1)
			var I = n.is_valid_integer()
			#var p = false
			#if I == false:
			#	return str("invalid value: ",n)

			if name == "+" and not (n == "false" or n == "true"):
				return str("invalid + value: ",n)
			elif name == "+" and n == "false":
				additional = false

			elif (name == "chance" and I == false):
				return str("invalid chance value: ",n)
			elif name == "chance":
				chance = int(n)
				
			elif name.find(":") > 0:
				var ndef = name.split(":")
				if ndef.size() != 2 or not (ndef[0].is_valid_identifier() and ndef[1].is_valid_identifier()):
					return str("invalid item name: ",name)
				elif I == false:
					return str("invalid item count: ",name)
				else:
					count = int(n)
					item = name
			else:
				return str("invalid option: ",name)
		if item == "":
			return str("invalid drop: no item")
		g[item] = {chance=chance,count=count,additional=additional}
	return g
func is_valid_itemstack(s):
	if s is Dictionary:
		if s.get("name") is String:
			return core.get_item_reg(s.name) != null
	return false
	
func is_by_editor(ob):
	return editor != null and editor.get_node("manu/name").text == ob.mod_name
func editor_error(ob,opname,message):
	if is_by_editor(ob):
		core.option_flash(editor.nodes[ob.id].options[opname].node,message)

func get_opmanu_value(nodedef,name,i):
	for op in nodereg[nodedef].op:
		if op.get("name") == name:
			return op.manu[i]

# ==================================================================
# functions ========================================================
# ==================================================================

func node_actions(ob,input:String="",value=null):

	if is_by_editor(ob):
		var inp = editor.nodes[ob.id].input.get(input)
		if inp != null:
			connection_flash(inp.node)
	
	var name = ob.name
	match name:
		"print":
			print(value)
		"world":
			if input == "init":
				next_connection(ob,"Enter")
				next_connection(ob,"Wolrd name",core.world.name)
			else:
				next_connection(ob,"Quit")
		"string":
			match input:
				"Set (1)":
					ob.options.text1 = value
				"Set (2)":
					ob.options.text2 = value
				"Number to string (1)":
					ob.options.text2 = str(value)
				"Replace":
					next_connection(ob,"Value",value.replace(ob.options.text1,ob.options.text2))
				"Add front":
					ob.options.text1 = str(value,ob.options.text1)
				"Add back":
					ob.options.text1 = str(ob.options.text1,value)
			next_connection(ob,"Value",ob.options.text1)
		"gate":
			match input:
				"In":
					if ob.options.checkbox1:
						next_connection(ob,"Opened",value)
					else:
						next_connection(ob,"Closed",value)
				"Open":
					ob.options.checkbox1 = true
				"Close":
					ob.options.checkbox1 = false
				"Toggle":
					ob.options.checkbox1 = ob.options.checkbox1 == false
		"number":
			if input == "In":
				next_connection(ob,"Value",ob.options.number1)
				return
			elif ob.options.checkbox1:
				value = int(value)
			elif ob.options.checkbox1 == false:
				value = float(value)
			ob.options.number1 = 0 if ob.options.number1 == null else ob.options.number1
			match input:
				#"In":
				"Set":
					ob.options.number1 = value
				"String to number":
					ob.options.number1 = value
				"+":
					ob.options.number1 += value
				"-":
					ob.options.number1 -= value
				"*":
					ob.options.number1 *= value
				"/":
					ob.options.number1 /= value
			next_connection(ob,"Value",ob.options.number1)
		"timer":
			match input:
				"Start":
					var t
					ob.options.number1 = 0 if ob.options.number1 == null else ob.options.number1
					if ob.get("timer") == null:
						t = Timer.new()
						ob.timer = t
						tempnodes(ob,t)
						core.add_child(t)
					else:
						t = ob.timer
						t.disconnect("timeout",self,"node_actions")
					t.one_shot = false if ob.options.checkbox1 != true else true
					t.connect("timeout",self,"node_actions",[ob,"Timeout",value])
					t.wait_time = ob.options.number1
					ob.timer.start()
				"Stop":
					if ob.get("timer") != null:
						ob.timer.stop()
				"Set":
					ob.options.number1 = value
					ob.timer.wait_time = value
				"Timeout":
					next_connection(ob,"Timeout",value)
		"delay":
			yield(get_tree().create_timer(ob.options.number1),"timeout")
			next_connection(ob,"Out",value)
		"set_node":
			if input == "node":
				ob.options.text1 = input
			else:
				var r = core.get_node_reg(ob.options.node)
				if r == null:
					editor_error(ob,"text1",str("invalid node"))
				else:
					core.set_node({name=ob.options.node,pos=value})
		"vector":
			ob.options.text1 = ob.options.text1.replace(" ","")
			var s = ob.options.text1.split(",",false)
			var msg
			var n = s.size()
			if n < 2 or n > 3:
				msg = "2 or 3 numbers allowed"
			else:
				for i in s:
					if i.is_valid_integer() == false and i.is_valid_float() == false:
						msg = "Invalid vector\n(only numbers allowed)"
			if msg != null and is_by_editor(ob):
				core.option_flash(editor.nodes[ob.id].options["text1"].node,msg)
				return
			if n == 2:
				value = str2var(str("Vector2(",s[0],",",s[1],")"))
			else:
				value = str2var(str("Vector3(",s[0],",",s[1],",",s[2],")"))
			next_connection(ob,str("Vector",n),value)
			
#		"get_player_by_name":
#			if input == "Player name":
#				ob.options.playername = value
#			else:
#				var p = core.players.get(ob.options.playername)
#				if p != null:
#					next_connection(ob,"Player",core.player.object)
		"player":
			next_connection(ob,"Player",core.player.object)
		"add_to_inventory":
			match input:
				"Stack input":
					if is_valid_itemstack(value) and ob.options.get("object_var") != null:
						var stack2
						if ob.options.object_var is Vector3:
							stack2 = core.add_to_inventory(ob.options.object_var,ob.options.listname,value)
						elif is_instance_valid(ob.options.object_var):
	# wrong ob.options.listname will crash
							var o = ob.options.object_var
							if o.get("player"):
								o = o.player
							elif o.get("mob"):
								o = o.mob
							elif o.get("object"):
								o = o.object
							else:
								return
							stack2 = core.add_to_inventory(o,ob.options.listname,value)
							if ob.options.object_var.get("player"):
								ob.options.object_var.update_player()
						if stack2.count > 0:
							next_connection(ob,"Leftover",stack2)	
				"listname":
					ob.options.listname = value
				"Set object":
					if value is KinematicBody and (value.get("player") != null or value.get("mob") != null):
						ob.options.object_var = value
					elif is_by_editor(ob):
						core.option_flash(editor.nodes[ob.id].options["label"].node,"Not valid")
					return
				"Set position":
					ob.options.object_var = value
		"itemstack":
			match input:
				"In":
					if ob.options.item_name != null and core.get_item_reg(ob.options.item_name) != null:
						next_connection(ob,"Stack",core.itemstack(ob.options.item_name,{count=ob.options.count}))	
				"Item name":
					if core.get_item_reg(value) == null:
						if is_by_editor(ob):
							core.option_flash(editor.nodes[ob.id].options["item_name"].node,"Invalid item")
						return
					ob.options.item_name = value
				"Count":
					ob.options.count = value	
		"distribute":
			var v = typeof(value)
			if v == TYPE_INT or v == TYPE_REAL:
					next_connection(ob,"Number",value)
			elif v == TYPE_STRING:
					next_connection(ob,"String",value)
			elif v == TYPE_BOOL:
				next_connection(ob,"Bool",value)
			elif v == TYPE_ARRAY:
				next_connection(ob,"Array",value)
			elif v == TYPE_DICTIONARY:
				next_connection(ob,"Tree",value)
			elif v == TYPE_VECTOR3:
				next_connection(ob,"Vector3",value)
			elif v == TYPE_VECTOR2:
				next_connection(ob,"Vector2",value)
			elif is_instance_valid(value) and value.get("player") != null:
				next_connection(ob,"Player",value)
			elif is_instance_valid(value) and value.get("mob") != null:
				next_connection(ob,"Mob",value)
			elif value is StreamTexture:
				next_connection(ob,"Texture",value)
			elif is_instance_valid(value):
				next_connection(ob,"Object",value)
			else:
				next_connection(ob,"Variant",value)
		"counter":
			if ob.options.number1 == null:
				ob.options.number1 = 1
			match input:
				"In":
					next_connection(ob,"Value",ob.options.number1)
				"Reset":
					ob.options.number1 = 0
				"Add (variant: 1, number: value)":
					ob.options.number1 += 1 if typeof(value) != TYPE_REAL and typeof(value) != TYPE_INT else value
				"Set (1)":
					ob.options.number1 = value
				"Set (2)":
					ob.options.number2 = value
			var a = 0 if ob.options.number1 == null else ob.options.number1
			var b = 0 if ob.options.number2 == null else ob.options.number2
			if a < b:
				next_connection(ob,"<",value)
			elif a <= b:
				next_connection(ob,"<=",value)
			if a > b:
				next_connection(ob,">",value)
			elif a >= b:
				next_connection(ob,">=",value)
			if a == b:
				next_connection(ob,"==",value)
			elif a != b:
				next_connection(ob,"~",value)
		"texture":
			if input == "In":
				var l = load(ob.options.text1)
				if l is StreamTexture:
					next_connection(ob,"Value",	l)
			else:
				ob.options.text1 = value if value != null else ""

		"default_chest_inventory":
			if core.existsMeta(value) == false:
				core.create_node_inventory(value,"main")
			GUI.show(core.player,"background[8;8.5]inventory[player:player1;main;0;4.5;8;4]inventory[node:"+var2str(value)+";main;0;0;8;4]")
		"change_world":
			if ob.options.name != "":
				core.world.name = ob.options.name
				core.world.mapgen = get_opmanu_value("change_world","mapgen",ob.options.mapgen)
				core.world_main(true)
		"register_item":
			var o = ob.options
			var inv_image = load(ob.options.inv_image)
			var groups = text_to_groups(ob.options.groups)
			var item_groups = text_to_groups(ob.options.item_groups)
			if o.name.is_valid_filename() == false:
				if is_by_editor(ob):
					core.option_flash(editor.nodes[ob.id].options["name"].node,"Invalid name")
				return
			elif not inv_image is StreamTexture:
				if is_by_editor(ob):
					core.option_flash(editor.nodes[ob.id].options["inv_image"].node,"Texture not found")
				return
			elif groups is String:
				if is_by_editor(ob):
					core.option_flash(editor.nodes[ob.id].options["groups"].node,groups)
				return
			elif item_groups is String:
				if is_by_editor(ob):
					core.option_flash(editor.nodes[ob.id].options["item_groups"].node,item_groups)
				return
			var reg_item_name = str(ob.mod_name,":",o.name)
			core.register.items[reg_item_name] = {
				name = reg_item_name,
				type = "item",
				inv_image = inv_image,
				max_count = o.max_count,
				groups = o.item_groups,
			}
			if o.capabilities:
				core.register.items[reg_item_name].item_capabilities = {
					punch_interval = o.punch_interval,
					damage = o.damage,
					durability = o.durability,
					groups = groups,
				}
		"register_node":
			var groups = text_to_groups(ob.options.groups)
			var drops = text_to_drop(ob.options.drops)
			var tiles = []
			if ob.options.name.is_valid_identifier() == false:
				editor_error(ob,"name","invalid name")
			elif groups is String:
				editor_error(ob,"groups",groups)
				return
			elif ob.options.drops != "" and drops is String:
				editor_error(ob,"drops",drops)
				return
			if ob.options.drops == "":
				drops = null
			
			for i in range(1,6):
				var t = ob.options[str("tile",i)]
				if t != "":
					var l = load(t)
					if l is StreamTexture:
						tiles.push_back(l)
					else:
						editor_error(ob,str("tile",i),str("not found"))
						return
			core.register_node({
				name = str(ob.mod_name,":",ob.options.name),
				drop = drops,
				drawtype = get_opmanu_value("register_node","drawtype",ob.options.drawtype),
				groups=groups,
				max_count = ob.options.max_count,
				replaceable = ob.options.replaceable,
				collidable = ob.options.collidable,
				transparent = ob.options.transparent,
				solid_surface = ob.options.solid_surface,
				touchable = ob.options.touchable,
				activatable = ob.options.activatable,
				tiles = tiles,
			})
			next_connection(ob,"on_register")
