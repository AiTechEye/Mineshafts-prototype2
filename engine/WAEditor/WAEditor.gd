extends Control
var paswc = WaEngine.paswc
var password
var mod_file = ""
var enabled = false setget enable
var nodes = {}
var lines = []
var select = {object=null,output=null,value=null,del=false}
var del = [Color(0,0,0),Color(0.1,0.1,0.1)]

var datatype_texture = {
	"texture":load("res://engine/WAEditor/texture.png"),
}
var datatype_color = {
	number=Color(0,0,1),
	string=Color(1,1,0),
	variant=Color(1,0,0.51),
	"bool":Color(1,0,0),
	"array":Color(0.7,0,1),
	"tree":Color(0,1,1),
	"vector3":Color(0,1,0.5),
	"vector2":Color(0,0.5,1),
	"object":Color(1,0.3,0),
	"texture":Color(1,1,1),
}
var nodereg = {
	"invalid":{
		label="Invalid",
		color = Color(0.5,0.5,0.5),
		op=[{type="label",text="",w=100,h=100}],
	},
	"timer":{
		label="Timer",
		color=Color(1,0.4,0.9),
		op=[{type="number",w=100,tooltip="Value"},{type="checkbox",on_toggle=["timeout","interval"]}],
		input={"Start":"variant","Stop":"variant","Set":"number"},
		output={Timeout="variant"},
	},
	"var":{
		label="Var",
		color=Color(1,0,0.51),
		input={In="variant",Set="variant"},
		output={Value="variant"},
	},
	string={
		label="String",
		color=Color(0,0.3,0.9),
		op=[{type="text",w=100,tooltip="Value"},{type="text",w=100,tooltip="Replace"}],
		input={In="variant","Set (1)":"string","Set (2)":"string","Number to string (1)":"number",Replace="string","Add front":"string","Add back":"string"},
		output={Value="string"},
	},
	"number":{
		label="Number",
		color=Color(0,0.3,0.9),
		op=[{type="number",w=100,tooltip="Value"},{type="checkbox",on_toggle=["Int","Float"]}],
		input={In="variant",Set="number","String to number":"string","+":"number","-":"number","*":"number","/":"number"},
		output={Value="number"},
	},
	world={
		init=true,
		label="World",
		color=Color(1,0,0),
		output={Enter="variant",Quit="variant","Wolrd name":"string"},
	},
	gate={
		label="Gate",
		color=Color(0.5,0,0.1),
		op=[{type="checkbox",pressed=false,on_toggle=["Open","Closed"]}],
		input={In="variant",Open="variant",Close="variant",Toggle="variant"},
		output={Opened="variant",Closed="variant"},
	},
	"counter":{
		label="Counter",
		color=Color(1,0.5,0.5),
		op=[{type="number",w=100,tooltip="Value1"},{type="number",w=100,tooltip="Value2"}],
		input={In="variant",Reset="variant","Add (variant: 1, number: value)":"variant","Set (1)":"number","Set (2)":"number"},
		output={Value="number","<":"variant","<=":"variant","=":"variant",">":"variant",">=":"variant","~":"variant"},
	},
	texture={
		label="Texture",
		color=Color(1,1,1),
		op=[{type="text",w=100}],
		input={"In":"variant","Set":"string"},
		output={"Value":"texture"}
	},
	itemstack={
		label="Itemstack",
		color=Color(0,0,1.1),
		op=[{name="item_name",type="text",w=100},{name="count",type="number",w=100,step=1,min_value=1,default=1}],
		input={"In":"variant","Item name":"string","Count":"number"},
		output={Stack="variant"},
	},
	player={
		label="Get player",
		color=Color(0,1,0),
		output={Player="object"},
		input={"In":"variant"},
	},
	vector={
		label="Vector",
		color=Color(0,0.5,0.2),
		op=[{type="text",w=100,tooltip="Vector3 = 0,2,1\nVector2 = 234.67,78",default="0,0,0"},],
		input={"In":"variant"},
		output={"Vector2":"vector2","Vector3":"vector3"},
	},
	add_to_inventory={
		label="Add to inventory",
		color=Color(0,1,0.1),
		op=[{name="listname",type="text",w=100,default="main",tooltip="List name (eg main, craft, output)"},{name="label",type="label",w=100,h=100,text="Object\nVector3 (node)"}],
		input={"Stack input":"variant","Listname":"string","Set object":"object","Set position":"vector3"},
		output={Leftover="variant"},
	},
	change_world={
		label="Change world",
		color=Color(0,0,0),
		size = 300,
		op=[
			{name="name",type="text",w=200,tooltip="World name"},{type="label",text="name",w=100},
			{name="mapgen",type="manu",w=200,manu=mapgen.mapgens},{type="label",text="Mapgen",w=100},
		],
		input={"Change":"variant"},
	},
	delay={
		label="Delay",
		color=Color(1,0.3,0),
		op=[{type="number",w=100,default=0.1,min_value=0.001}],
		input={"In:":"variant"},
		output={"Out":"variant"},
	},
	default_chest_inventory={
		label="Show Default chest inventory",
		color=Color(0.1,0,1),
		input={"In:":"vector3"},
	},
	distribute={
		output_labels = true,
		label="Distribute",
		color=Color(1,0,0.51),
		input={"Input":"variant"},
		output={
			"Variant":"variant",
			"String":"string",
			"Number":"number",
			"Bool":"bool",
			"Array":"array",
			"Tree":"tree",
			"Vector3":"vector3",
			"Vector2":"vector2",
			"Object":"object",
			"Mob":"variant",
			"Player":"variant",
			"Texture":"variant",
			"Itemstack":"variant",
			},
	},
	set_node={
		label="Set node",
		color=Color(1,0,0),
		input={"set":"vector3","node":"string"},
		op=[{name="node",type="text",w=100,default="air",tooltip="node name, eg default:grassy"}],
	},
	register_item={
		init=true,
		size = 250,
		label="Register item",
		color=Color(1,0,0),
		output={"on_use":"variant"},
		op=[
			{name="name",type="text",w=100,default="piackaxe"},{type="label",text="name",w=150},
			{name="inv_image",type="text",w=100,default="res://game/textures/default_axe_stone.png",text="item texture (URL)"},{type="label",w=150},
			{name="max_count",type="number",w=100,step=1,allow_lesser=false,default=100,min_value=1,tooltip="Will be 1 if tool"},{type="label",text="max count",w=150},
			{name="item_groups",type="text",w=100,default="",tooltip="group1=n, group2=n...\nUsed to determined item in groups\n eg Useful with craft recipes"},{type="label",text="groups",w=150},
			{type="label",text="item capabilities",w=150},{type="checkbox",w=100,pressed=true,on_toggle=["Tool","Item"],tooltip="Enable/disable item capabilities (The properties below)",name="capabilities"},
			{name="punch_interval",type="number",w=100,default=1,allow_lesser=false,allow_greater=false,max_value=60},{type="label",text="punch interval",w=150},
			{name="damage",type="number",w=100,default=1,allow_lesser=false},{type="label",text="damage",w=150},
			{name="durability",type="number",w=100,allow_lesser=false,default=100},{type="label",text="durability",w=150},
			{name="groups",type="text",w=100,default="cracky=1",tooltip="group1=n, group2=n...\nUsed to determine nodes that is breakable with this tool"},{type="label",text="groups",w=150},
		],
	},
	register_node={
		init=true,
		size = 250,
		label="Register node",
		color=Color(1,0,0),
		output={"on_register":"variant","pos":"vector3","on_touch":"object","on_untouch":"object","on_activate":"object"},
		op=[
			{name="name",type="text",w=100,tooltip="eg stone"},{type="label",text="name",w=150},
			{name="max_count",type="number",w=100,step=1,allow_lesser=false,default=100,min_value=1},{type="label",text="max count",w=150},
			{name="groups",type="text",w=100,default="cracky=1",tooltip="group1=n, group2=n...\nUsed to determined item in groups\n eg Useful with craft recipes"},{type="label",text="groups",w=150},
			{name="drawtype",type="manu",w=100,manu=["default","none","liquid"]},{type="label",text="Drawtype",w=150},
			{name="replaceable",type="checkbox",pressed=false,tooltip="Replaceable (Replace while you placing a node on it)"},
			{name="collidable",type="checkbox",pressed=true,tooltip="Collidable (Has collision)"},
			{name="transparent",type="checkbox",pressed=false,tooltip="Transparent"},
			{name="solid_surface",type="checkbox",pressed=false,tooltip="Solid surface (Visible from inside from blocks, usefull for transparent nodes)"},
			{name="touchable",type="checkbox",pressed=false,tooltip="Touchable (enables touch signals), activated after the node is rendered"},
			{name="activatable",type="checkbox",w=150,pressed=false,tooltip="activatable (activated instead of showing the players inventory)"},
			{name="drops",type="text",w=100,tooltip="You can ignore this field for a default drop\nmod:name=1 sets a drop (Required)\nchance=10 chance to drop (Optional)\n+=false if added, this drop will not be overwrited by other drops (Optional)\n ; for new drops\n\ndefault:grassy=1, chance=10, +=false; default:cobble=4..."},{type="label",text="drops",w=150},
			{name="tile1",type="text",w=100,default="res://game/textures/stone.png"},{type="label",text="tile 1 (URL/textures)",w=150},
			{name="tile2",type="text",w=100},{type="label",text="tile 2",w=150},
			{name="tile3",type="text",w=100},{type="label",text="tile 3",w=150},
			{name="tile4",type="text",w=100},{type="label",text="tile 4",w=150},
			{name="tile5",type="text",w=100},{type="label",text="tile 5",w=150},
			{name="tile6",type="text",w=100},{type="label",text="tile 6",w=150},
		],
	},
}

func enable(v:bool):
	enabled = v
	visible = v
func _ready():
	core.WaEditor = self
	var n = 0
	for i in nodereg:
		$manu/nodes.add_item(i)
		var c = nodereg[i].color
		c.a = 0.1
		$manu/nodes.set_item_custom_bg_color(n,c)
		n += 1
	$manu/nodes.remove_item(0)
func new_node(name,def={id=0,options={},connections={}}):
	var id = def.id
	while nodes.get(id) != null:
		id += 1

	var y = 0
	var next_y = 0
	var x = 0
	var w = 25
	var h = 25
	var h2 = 25
	
	var b = ColorRect.new()
	var frame = ReferenceRect.new()
	var label = Label.new()
#system
	var a = nodereg.get(name)
	if a == null:
		a = nodereg["invalid"]
		a.op[0].text = name
		name = "Invalid"
		def.connections = {}
	
	var s = 100 if a.get("size") == null else a.size
	var n = {
			node=b,
			input={},
			output={},
			name=name,
			id=id,
			options=def.options,
			connections=def.connections
		}
		
#set basics
	b.rect_position = Vector2() if def.get("pos") == null else def.pos
	b.rect_size = Vector2(s,s)
	b.color = Color(0.3,0.3,0.3,0.7)
	
	frame.rect_size = Vector2(s,s)
	frame.border_color = Color(1,0,0) if a.get("color") == null else a.color
	frame.border_width = 2
	frame.editor_only = false
	b.add_child(frame)
	label.text = a.label
	label.align = Label.ALIGN_CENTER
	label.valign = Label.VALIGN_CENTER
	label.rect_size.y = 20
	label.rect_position = Vector2((b.rect_size.x/2)-(label.rect_size.x/2),-20)
	b.add_child(label)
#conntections
	if a.get("input"):
		for i in a.input:
			var p
			var c = datatype_color[a.input[i]]
			var t = datatype_texture.get(a.input[i])
			if t == null:
				p = ColorRect.new()
				p.color = datatype_color[a.input[i]]
			else:
				p = TextureRect.new()
				p.texture = t
			p.hint_tooltip = i
			p.rect_size = Vector2(10,10)
			p.rect_position = Vector2(-10,y)
			y+= 15
			b.add_child(p)
			n.input[i] = {node=p,color=c,name=i,type=a.input[i]}
	if y > h2:
		h2 = y
	y = 0
	if a.get("output"):
		for i in a.output:
			var p
			var c = datatype_color[a.output[i]]
			var t = datatype_texture.get(a.output[i])
			if t == null:
				p = ColorRect.new()
				p.color = c
			else:
				p = TextureRect.new()
				p.texture = t
			p.hint_tooltip = i
			p.rect_size = Vector2(10,10)
			p.rect_position = Vector2(s,y)
			y+= 15
			b.add_child(p)
			n.output[i] = {node=p,color=c,name=i,type=a.output[i]}

			if a.get("output_labels"):
				var l = Label.new()
				l.text = i
				l.rect_size = Vector2(s,5)
				l.rect_position = Vector2(-l.rect_size.x,0)
				l.align = Label.ALIGN_CENTER
				l.valign = Label.VALIGN_CENTER
				p.add_child(l)
	if y > h2:
		h2 = y
	y = 0
#options
	if a.get("op"):
		var opn = {}
		for i in a.op:
			opn[i.type] = 1 if opn.get(i.type) == null else opn[i.type] +1
			var p
			var opname = str(i.type,opn[i.type]) if i.get("name") == null else i.name
			var W = w if i.get("w") == null else i.w
			var H = h if i.get("h") == null else i.h
			var v = def.options.get(opname) if def.options.get(opname) != null else i.get("default")
			var sv
			var connect_type
			var connect_input
			if i.type == "text":
				p = LineEdit.new()
				p.rect_size = Vector2(W,h)
				p.rect_position = Vector2(x,y)
				p.text = "" if v == null else v
				sv = p.text
				connect_type = "text_changed"
				connect_input = "text"
			elif i.type == "number":
				p = SpinBox.new()
				p.rect_size = Vector2(W,H)
				p.rect_position = Vector2(x,y)
				p.allow_greater = true if i.get("allow_greater") == null else i.allow_greater
				p.allow_lesser = true if i.get("allow_lesser") == null else i.allow_lesser
				p.min_value = 0 if i.get("min_value") == null else i.min_value
				p.max_value = 100 if i.get("max_value") == null else i.max_value
				p.align = LineEdit.ALIGN_CENTER
				p.step = 0.001 if i.get("step") == null else i.step
				p.value = 0 if v == null else v
				sv = p.value
				connect_type = "value_changed"
				connect_input = "value"
			elif i.type == "checkbox":
				p = CheckBox.new()
				p.rect_size = Vector2(W,H)
				p.rect_position = Vector2(x,y)
				p.pressed = v if v != null else i.get("pressed") == true
				p.text = "" if i.get("on_toggle") == null else i.on_toggle[0 if p.pressed == true else 1]
				sv = p.pressed
				connect_type = "toggled"
				connect_input = "pressed"
			elif i.type == "button":
				p = Button.new()
				p.rect_size = Vector2(W,H)
				p.rect_position = Vector2(x,y)
				p.text = "OK" if i.get("text") == null else i.text
			elif i.type == "label":
				p = Label.new()
				p.text = i.text
				p.rect_size = Vector2(W,H)
				p.rect_position = Vector2(x,y)
				p.align = Label.ALIGN_CENTER
				p.valign = Label.VALIGN_CENTER
			elif i.type == "manu":
				p = OptionButton.new()
				for o in i.manu:
					p.add_item(o)
				p.rect_size = Vector2(W,H)
				p.rect_position = Vector2(x,y)
				p.selected = 0 if v == null else v
				sv = p.selected
				connect_type = "item_selected"
				connect_input = "selected"
		
			if i.get("tooltip") != null:
				p.hint_tooltip = i.tooltip
			p.name = opname if i.get("name") == null else i.name
			frame.add_child(p)
			n.options[p.name] = {node=p,type=i.type,value=sv,method=connect_input}
			if i.type == "button":
				p.connect("pressed",self,"button_pressed",[i.ref,i.get("value")],name,i)
			elif connect_type != null:
				p.connect(connect_type,self,"option_value_changed",[{option=n.options[p.name],method=connect_input,opreg=i}])
			x += W
			if H != h and H > next_y:
				next_y = H

			if x >= s:
				x = 0
				y += h if next_y == 0 else next_y
				next_y = 0
	if y > h2:
		h2 = y
	b.rect_size = Vector2(s,h2)
	frame.rect_size = Vector2(s,h2)
				
#add
	add_child(b)
	nodes[id] = n
	return n

func run_mod():
	WaEngine.reload_mod(save_data(true),self)

func button_pressed(ref,v,opreg):
	if ref != null:
		ref.call_func(v,opreg)

func option_value_changed(a=null,b=null):
	var op = a if b == null else b
	op.option.value = op.option.node.get(op.method)
	if op.option.type == "checkbox":
		if op.opreg.get("on_toggle") != null:
			op.option.node.text = op.opreg.on_toggle[0 if op.option.value else 1]
	
func _input(event):
	if core.game == null:
		return
	elif Input.is_action_just_pressed("actioneditor"):
		if core.player.object.gui == null and enabled == false:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			core.player.object.gui = {}
			enable(true)
		else:
			var pos = get_viewport().get_mouse_position()
			for i in nodes:
				var ob = nodes[i]
				var s = ob.node.rect_size
				var p = ob.node.rect_position
				if pos.x >= p.x-10 and pos.x <= p.x+s.x+10 and pos.y >= p.y-10 and pos.y <= p.y+s.y+10:
					return
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			core.player.object.gui = null	
			enable(false)
		return
	elif enabled == false:
		return
	elif Input.is_key_pressed(KEY_CONTROL) and Input.is_key_pressed(KEY_S):
		save_data()
	elif event is InputEventMouseButton:
		var pos = event.position
		var relessed = Input.is_action_just_released("LMB")
		var pressed = Input.is_action_just_pressed("LMB")
		
		if pressed:
			for l in lines:
				var a = (l.pos2-l.pos1).normalized().dot((event.position-l.pos2).normalized())
				var b = (l.pos1-l.pos2).normalized().dot((event.position-l.pos1).normalized())
				if floor(a*10000)*0.0001 == -1 and floor(b*10000)*0.0001 == -1:
					nodes[l.id1].connections[l.output].erase(str(l.input,l.id2))
					update_lines()
					break

		if (relessed or pressed) and select.object == null:
			for i in nodes:
				var ob = nodes[i]
				var s = ob.node.rect_size
				var p = ob.node.rect_position
				
				if pos.x >= p.x-10 and pos.x <= p.x+s.x+10 and pos.y >= p.y-10 and pos.y <= p.y+s.y+10:
					if pressed and pos.x >= p.x and pos.x <= p.x+s.x and pos.y >= p.y and pos.y <= p.y+s.y:
						select.object = ob
						select.pos = ob.node.rect_position-pos
						return
					elif pressed:
						for put in ob.output:
							var o = ob.output[put]
							var os = o.node.rect_size
							var op = o.node.rect_global_position
							if pos.x >= op.x and pos.x <= op.x+os.x and pos.y >= op.y and pos.y <= op.y+os.y:
								select.output = {ob=ob,output=o,name=o.name,pos=op+os/2,type=o.type}
								return
					elif relessed and select.output != null:#not same node
						for put in ob.input:
							var o = ob.input[put]
							var os = o.node.rect_size
							var op = o.node.rect_global_position
							if pos.x >= op.x and pos.x <= op.x+os.x and pos.y >= op.y and pos.y <= op.y+os.y:
								if o.type == "variant" or o.type == select.output.type:
									var sob = select.output.ob
									sob.connections[select.output.name] = {} if sob.connections.get(select.output.name) == null else sob.connections[select.output.name]
									sob.connections[select.output.name][str(o.name,ob.id)] = {id=ob.id,name=o.name}
								select.output = null
								update_lines()
								return	
			if lines.size() > 0 and lines[0].node.name == "tmp":
				lines[0].node.free()
				lines.remove(0)
			select.output = null
		elif Input.is_action_just_released("LMB"):
			if select.del:
				$manu/del.color = del[0]
				select.del = false
				del_node(select.object)
			select.object = null
	elif event is InputEventMouseMotion:
#remove select.object
		if select.object != null:
			var pos = event.position
			select.object.node.rect_position = event.position+select.pos
			update_lines()
			if pos.y >= 550 and pos.x <= 50:
				if select.del == false:
					select.del = true
					$manu/del.color = del[1]
			elif select.del:
				select.del = false
				$manu/del.color = del[0]
		elif select.output != null:
#tmp line
			if lines.size() > 0 and lines[0].node.name == "tmp":
				lines[0].node.points=[select.output.pos,event.position]
			else:
				var l = Line2D.new()
				l.default_color = datatype_color[select.output.type]
				l.points=[select.output.pos,event.position]
				l.width = 2
				l.z_index = 1000
				l.name = "tmp"
				add_child(l)
				lines.push_front({node=l})
		elif Input.is_action_pressed("LMB"):
#remove line
			for l in lines:
				var a = (l.pos2-l.pos1).normalized().dot((event.position-l.pos2).normalized())
				var b = (l.pos1-l.pos2).normalized().dot((event.position-l.pos1).normalized())
				if floor(a*10000)*0.0001 == -1 and floor(b*10000)*0.0001 == -1:
					nodes[l.id1].connections[l.output].erase(str(l.input,l.id2))
					update_lines()
					break
	
func update_lines():
	var new_lines = []
	for id1 in nodes:
		var ob1 = nodes[id1]
		for output in ob1.connections:
			var list = ob1.connections[output]
			var op1 = ob1.output.get(output)
			if op1 == null:
				continue
			var p1 = op1.node.rect_global_position
			var s1 = op1.node.rect_size/2
			for ci in list:
				var c = list[ci]
				var ob2 = nodes.get(c.id)
				if ob2 == null:
					continue
				var inp = nodes[c.id].input.get(c.name)
				if inp == null:
					ob1.connections[output].erase(str(c.name,c.id))
					continue
				var c2 = inp.node
				var p2 = c2.rect_global_position
				var s2 = c2.rect_size/2
				var l = Line2D.new()
				
				l.default_color = datatype_color[ob1.output[output].type]
				l.points=[p1+s1,p2+s2]
				l.width = 2
				l.z_index = 1000
				add_child(l)
				new_lines.push_back({node=l,output=output,input=c.name,id1=id1,id2=ob2.id,pos1=p1+s1,pos2=p2+s2})
	for l in lines:
		l.node.free()
	lines = new_lines

func del_node(ob1):
	var id = ob1.id
	for ob2 in nodes:
		for k in nodes[ob2].connections:
			var output = nodes[ob2].connections[k]
			for c in output:
				if output[c].id == id:
					output.erase(c)
	ob1.node.free()
	nodes.erase(id)
	update_lines()

func load_data():
	var file_mmode = str("user://mods/",$manu/name.text,".mmode")
	var file_mmodt = str("user://mods/",$manu/name.text,".mmodt")
	var file = File.new()
	if file.file_exists(file_mmode):
		file_mmodt = null
	elif file.file_exists(file_mmodt):
		file_mmode = null
	
	else:
		core.option_flash($manu/name,"File doesn't exists",Color(1,1,0),true)
		return
	var s
	if file_mmode != null:
		file.open_encrypted_with_pass(file_mmode,File.READ,paswc)
		s = file.get_var()
	else:
		file.open(file_mmodt,File.READ)
		s = str2var(file.get_as_text())
		if s is String:
			file.close()
			core.option_flash($manu/name,"File is broken",Color(1,1,0),true)
			return
	file.close()

	if s != null and s.password != "" and s.password != $manu/password.text:
		core.option_flash($manu/password/passerr,"Wrong password",Color(1,0,0))
		return
	elif s == null:
		core.option_flash($manu/password/passerr,"Broken file",Color(1,0,0))
		return
		
	password = null if s == null else s.get("password")
	mod_file = file_mmode if file_mmodt == null else file_mmodt
	$manu/password.text = password if password != null else ""
	for id in nodes:
		nodes[id].node.free()
	nodes.clear()
	
	for id in s.data:
		var ob = s.data[id]
		new_node(ob.name,ob)

	update_lines()
	core.option_flash($manu/name,"Loaded",Color(0,1,0),true)
func save_data(test:bool=false):
	
	if $manu/name.text == "":
		core.option_flash($manu/name,"Name it!",Color(1,1,0),true)
		return

	var s = {}
	for id in nodes:
		var ob = nodes[id]
		var options = {}
		for o in ob.options:
			var op = ob.options[o]
			options[op.node.name] = op.value
		s[ob.id] = {
			pos = ob.node.rect_position,
			name=ob.name,
			id=ob.id,
			connections = ob.connections,
			options = options,
		}
	var save = {
		actor=$manu/more/morei/actor.text,
		description=$manu/more/morei/description.text,
		name=$manu/name.text,
		game_version = core.version,
		mod_version = $manu/more/morei/version.value,
		password=password,
		data=s,
	}
	if test:
		return save

	var D = Directory.new()
	var file_mmode = str("user://mods/",$manu/name.text,".mmode")
	var file_mmodt = str("user://mods/",$manu/name.text,".mmodt")
	if D.dir_exists("user://mods") == false:
		D.make_dir("user://mods")

	if D.file_exists(file_mmode) and file_mmode != mod_file:
		var passw_file = File.new()
		passw_file.open_encrypted_with_pass(file_mmode,File.READ,paswc)
		var ls = passw_file.get_var()
		passw_file.close()
		if ls != null and ls.password != "" and ls.password != password:
			core.option_flash($manu/password/passerr,"Load before overwrite",Color(1,0,0))
			return
	save.password = $manu/password.text
	
	var file = File.new()
	if save.password != "":
		if mod_file != null and mod_file.get_extension() == "mmodt":
			var rnf = Directory.new()
			rnf.rename(mod_file,renpath(mod_file,"mmode"))

		file.open_encrypted_with_pass(file_mmode,File.WRITE,paswc)
		file.store_var(save)
		mod_file = file_mmode
	else:
		if mod_file != null and mod_file.get_extension() == "mmode":
			var rnf = Directory.new()
			rnf.rename(mod_file,renpath(mod_file,"mmodt"))
		
		file.open(file_mmodt,file.WRITE_READ)
		file.store_string(var2str(save))
		mod_file = file_mmodt
	file.close()
	core.option_flash($manu/name,"Saved",Color(0,1,0),true)

func renpath(p,n):
	var filex = p.get_file()
	var fname = filex.substr(0,filex.find("."))
	return p.replace(filex,str(fname,".",n))


func _on_nodes_manu_selected(i):
	var name = $manu/nodes.get_item_text(i)
	var ob = new_node(name)
	ob.node.rect_position = get_viewport().get_mouse_position()-(ob.node.rect_size/2)
	select.object = ob
	select.pos = -ob.node.rect_size/2



func more():
	$manu/more/morei.visible = $manu/more/morei.visible == false
