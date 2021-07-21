extends Node

func show(player:Dictionary,text:String):
	var s = text.split("]",false)
	var Gui = {player=player,player_object=player.object}
	assert(s[0].substr(0,10) == "background","ERROR: GUI.create: first element must be background!")
	for v in s:
		var n = v.find("[")
		var ob  = v.substr(0,n)
		var op = [Gui]
		var ops = v.substr(n+1,-1).split(";",false)
		for i in ops:
			op.push_back(i)
		var S = ops.size()
		if ob == "background" and GUI.get("background") == null:
			callv("background",op)
		elif ob == "inventory" and S >= 3:
			callv("inventory",op)
	player.object.add_child(Gui.background.object)
	player.object.gui = Gui
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

func background(Gui,x="8",y="4",color="Color(0.1,0.1,0.1,0.9)"):
	x = float(x)*50
	y = float(y)*50
	color = str2var(color)
	var size = Vector2(x,y)
	var vs = core.ui.get_viewport_rect().size
	var pos = (vs/2) - (size/2)
	var back = ColorRect.new()
	back.rect_size = size
	back.rect_position = pos
	back.color = color
	Gui.background = {size=size,pos=pos,object=back}
	return Gui

func inventory(Gui,inv,name,x,y,w="1",h="1",size="50"):
	x = float(x)*50
	y = float(y)*50
	w = int(w)
	h = int(h)
	size = int(size)
	var X = 0
	var Y = 0
	
	if inv.substr(0,7) == "player:":
		inv = core.player.inventory[name]
	elif inv.substr(0,7) == "object:":
		inv = core.objects[inv.substr(7)].inventory[name]
	elif inv.substr(0,5) == "node:":

		inv = core.meta[str2var(inv.substr(5))].inventory[name]

	Gui.inventory = {ref={},selected=null} if Gui.get("inventory") == null else Gui.inventory
	var lab = str(Gui.inventory.ref.size())
	Gui.inventory.ref[lab] = {inv=inv,slots={},name=name}

	for i in w*h:
		var it = inv[i]
		var slot = TextureRect.new()
		slot.texture = load("res://game/textures/slot.png")
		slot.rect_size = Vector2(size,size)
		slot.rect_position = Vector2(x+X,y+Y)
		slot.name = str(i)
		Gui.inventory.ref[lab].slots[slot.name]={slot=slot}
		X += size

		if X >= w*size:
			X = 0
			Y += size
		if it != null:
			var item = core.stack_2invitem(it)
			item.get_node("item").rect_scale = item.get_node("item").rect_scale/2
			Gui.inventory.ref[lab].slots[slot.name].item = item
			slot.add_child(item)
		else:
			Gui.inventory.ref[lab].slots[slot.name].item = null
		Gui.background.object.add_child(slot)
	return Gui
