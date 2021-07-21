extends Control

var new_world = false
var del_world = false
var del_mod = false
var worlds = {}
var mods = {}
var selected = {mod=0,world=0}
func _ready():
	scan()
	$Camera/mesh.mesh = core.item2mesh("default:grassy")
	for i in mapgen.mapgens:
		$panel/new/mapagens.add_item(i)

func _process(delta):
	delta *= 0.5
	$Camera/mesh.rotation += Vector3(randf()*delta,randf()*delta,randf()*delta)

func scan():
	worlds.clear()
	$panel/worlds.clear()
	var DIR = "user://worlds"
	var d = Directory.new()
	d.open(DIR)
	d.list_dir_begin()
	var dir = d.get_next()
	while dir != "":
		if dir.begins_with(".") == false:
			var cd = str(d.get_current_dir(),"/",dir)
			if dir.get_extension() == "mworld":
				load_world_properties(cd)
		dir = d.get_next()
	d.list_dir_end()
	$panel/mods.clear()
	mods = WaEngine.scan("user://mods",{},true)
	$panel/worlds.select(0)
	worlds_selected(0)
	for i in $panel/mods.get_selected_items():
		var m = $panel/mods.get_item_text(i)
		mod_info(m)
		for ii in $panel/worlds.get_selected_items():
			var w = $panel/worlds.get_item_text(ii)
			$panel/modding/enable.pressed = true if worlds[w].get(m) == true else false
			break
		break
	if mods.size() == 0:
		$panel/modding/DelMod.disabled = true
func mod_info(m):
	var i = mods.get(m)
	if i == null or i.get("broken"):
		$panel/modding/enable.disabled = true
		return
	var w = $panel/worlds.get_item_text(selected.world)
	$panel/modding/actor_info.text = i.actor
	$panel/modding/version_info.text = str(i.mod_version)
	$panel/modding/build_info.text = str(i.game_version)
	$panel/modding/Description_text.text = i.description
	$panel/modding/enable.pressed = true if worlds.get(w) != null and worlds[w].get(m) == true else false
	$panel/modding/enable.disabled = false
func update_mod_list(w):
	$panel/mods.clear()
	var n = 0
	for i in mods:
		if mods[i] == null or mods[i].get("broken"):
			$panel/mods.add_item(str(i," (broken)"))
			$panel/mods.set_item_custom_bg_color(n,Color(1,0,0,0.2))
		else:
			$panel/mods.add_item(mods[i].name)
			if w != "" and worlds[w].get(mods[i].name) == true:
				$panel/mods.set_item_custom_bg_color(n,Color(0,1,0,0.2))
		n += 1

func load_world_properties(path):
	var file = File.new()
	file.open(path,file.READ)
	var s = file.get_var()
	file.close()
	var name = path.get_file().replace(str(".",path.get_extension()),"")
	worlds[name] = s.mods
	$panel/worlds.add_item(name)

func new_pressed():
	if new_world:
		if $panel/new/name.text.is_valid_filename():
			core.world_name = $panel/new/name.text
			core.world.mapgen = mapgen.mapgens[$panel/new/mapagens.selected]
			core.save_data()
			cancel()
			scan()
		else:
			core.option_flash($panel/new/name,"Invalid name")
	else:
		$panel/new.text = "Create"
		$panel/new/name.visible = true
		$panel/play.text = "Cancel"
		$panel/play.text = "Cancel"
		$panel/new/mapagens.visible = true
		var file = File.new()
		var i = 1
		while file.file_exists(str("user://worlds/world",i,".mworld")):
			i += 1
		$panel/new/name.text = str("world",i)
		$panel/new/name.select_all()
		new_world = true
func cancel():
	$panel/new.text = "New world"
	$panel/new/name.visible = false
	$panel/new/name.text = ""
	$panel/play.text = "Play"
	$panel/del.text = "Delete"
	$panel/new.visible = true
	$panel/modding/DelMod.text = "Delete mod"
	$panel/modding/DelMod.rect_size = Vector2(1,1)
	$panel/modding/OpenDir.text = "Game folder"
	$panel/new/mapagens.visible = false
	del_mod = false
	new_world = false
	del_world = false

func play():
	if new_world or del_world:
		cancel()
		return
	var name
	for i in $panel/worlds.get_selected_items():
		name = $panel/worlds.get_item_text(i)
		break
	if name != null:
		core.world_name = name
		var file = File.new()
		if not file.file_exists(str("user://worlds/",name,".mworld")):
			core.world_name = ""
			core.option_flash($panel/play,"The world doesn't exists anymore")
			scan()
		else:
			core.world_main()
			queue_free()
func delworld():
	var name
	for i in $panel/worlds.get_selected_items():
		name = $panel/worlds.get_item_text(i)
		break
	if del_world:
		$panel/del.text = "Delete"
		core.delete_data(name)
		cancel()
		scan()
	elif $panel/del.text != "":
		$panel/del.text = str("Delete ",name," ?")
		$panel/play.text = "Cancel"
		$panel/new.visible = false
		del_world = true

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		get_tree().quit()

func OpenGF():
	if del_mod:
		cancel()
		return
	OS.shell_open(ProjectSettings.globalize_path("user://"))

func enable_mod():
	var w
	var m
	var mi
	for i in $panel/worlds.get_selected_items():
		w = $panel/worlds.get_item_text(i)
		break
	for i in $panel/mods.get_selected_items():
		m = $panel/mods.get_item_text(i)
		mi = i
		break
	if w != null and m != null:
		worlds[w][m] = $panel/modding/enable.pressed
		update_mod_list(w)
		$panel/mods.select(mi)
		
		var file = File.new()
		if file.file_exists(str("user://worlds/",w,".mworld")):
			file.open(str("user://worlds/",w,".mworld"),file.READ)
			var s = file.get_var()
			file.close()
			file.open(str("user://worlds/",w,".mworld"),file.WRITE_READ)
			s.mods = worlds[w]
			file.store_var(s)
			file.close()

func mods_selected(index):
	var w
	var m
	for i in $panel/worlds.get_selected_items():
		w = $panel/worlds.get_item_text(i)
		break
	for i in $panel/mods.get_selected_items():
		m = $panel/mods.get_item_text(i)
		break
	if w != null and m != null:
		$panel/modding/enable.pressed = true if worlds[w].get(m) == true else false
		selected.mod = index
		mod_info(m)

func worlds_selected(index):
	update_mod_list($panel/worlds.get_item_text(index))
	selected.world = index
	if $panel/mods.get_item_count() > 0:
		$panel/mods.select(selected.mod)
		mod_info($panel/mods.get_item_text(selected.mod))

func DelMod():
	if del_mod:
		selected.mod = 0
		cancel()
		var d = Directory.new()
		var p = mods[$panel/mods.get_item_text(selected.mod).replace(" (broken)","")].path
		d.remove(p)
		scan()
	else:
		del_mod = true
		$panel/modding/OpenDir.text = "Cancel"
		$panel/modding/DelMod.text = str("Delete ",$panel/mods.get_item_text(selected.mod)," ?")
