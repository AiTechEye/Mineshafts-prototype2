extends KinematicBody

var direction = Vector3()
var velocity = Vector3()

var gravity = -27
var phys_object = {right=null,left=null}
onready var phys_ray = $head/Camera/phys_ray
var jump_height = 10
var walk_speed = 10
var player
var using = {time=0,wear=0,right_time=0,left_time=0,right=false,left=false,pos=Vector3()}
var cam_mode = 1
var gui
var fpv_camera_angle = 0
var fpv_mouse_sensitivity = 0.3
var tpv_camera_speed = 0.001
var fly_mode = false
var item_drop_timer = 0.1
onready var last_pos_before_fall = transform.origin

func _ready():
	update_player()
	core.ui.slot_index(player.right_slot)
	core.ui.slot_index(player.left_slot)
	core.ui.slot_index(player.slot_index)
func _input(event):
	if Input.is_action_just_pressed("SCREENSHOT"):
		var img = get_viewport().get_texture().get_data()
		img.flip_y()
		var d = Directory.new()
		var i = 1
		var saved = false
		while saved == false:
			var s = str("screenshots/screenshot",i,".png")
			if d.file_exists(s):
				i += 1
			else:
				if d.dir_exists("screenshots") == false:
					d.make_dir("screenshots")
					var file = File.new()
					file.open("screenshots/.gdignore",file.WRITE_READ)
					file.store_string("")
					file.close()
				img.save_png(s)
				saved = true
	elif core.WaEditor.enabled:
		return
	elif Input.is_action_just_pressed("use"):
		if gui != null:
			gui.background.object.queue_free()
			gui = null
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			update_player()
		else:
			var pointed = core.get_pointed_pos()
			if pointed.inside != null:
				var reg = core.get_node_reg(pointed.inside)
				var activated = false
				if reg.get("activatable") == true:
					for i in WaEngine.nodes:
						var ob = WaEngine.nodes[i]
						if ob.name == "register_node" and ob.options.activatable and str(ob.mod_name,":",ob.options.name) == reg.name:
								activated = true
								WaEngine.next_connection(ob,"on_activate",self)
								yield(get_tree().create_timer(0.1),"timeout")
								WaEngine.next_connection(ob,"pos",pointed.inside)
				elif reg.get("on_activate"):
					reg.on_activate.call_func(pointed.inside,reg)
					return
				elif activated:
					return
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			GUI.show(player,"background[8;8]inventory[player:player1;main;0;4;8;4]inventory[player:player1;craft;3;0.5;3;3]inventory[player:player1;craftoutput;6.5;1.5]")

	if gui != null:
		if gui.get("inventory") != null:
			if event is InputEventMouseButton:
				var key_pressed = Input.is_action_just_pressed("LMB")
				var key_released = Input.is_action_just_released("LMB")
				var p = event.position
				var inv# = player.inventory
				var slot
				var index
				var stack
				var stack_reg
				var cur_ref
				
				for ref in gui.inventory.ref:
					cur_ref = gui.inventory.ref[ref]
					for i in cur_ref.slots:
						var s = cur_ref.slots[i]
						var pos = s.slot.rect_global_position
						var size = s.slot.rect_size
						var a = pos+size/2
						if p.distance_to(a) <= s.slot.rect_size.x/2:
							inv = cur_ref.inv
							slot = s
							index = int(i)
							stack = cur_ref.inv[index]
							stack_reg = core.get_item_reg(stack.name) if stack != null else null
							if key_pressed:
								gui.inventory.selected = {ref=cur_ref,slot=s,index=index,stack=stack,name=s.slot.name}
							break
					if slot != null:
						break
						
				if gui.inventory.get("selected") == null:
					return
				elif key_pressed:
					if gui.inventory.selected.slot.item != null:
						gui.inventory.selected.slot.item.z_index = 1000
				elif key_released:
					if gui.inventory.selected.slot.item != null:
						gui.inventory.selected.slot.item.z_index = 100
						var b = gui.background
						if p.x < b.pos.x or p.x > b.size.x+b.pos.x or p.y < b.pos.y or p.y > b.size.y+b.pos.y:
#del item outside
							core.spawn_drop_item(transform.origin,gui.inventory.selected.stack,player.name)
							gui.inventory.selected.slot.item.queue_free()
							gui.inventory.selected.slot.item = null
							gui.inventory.selected.ref.inv[gui.inventory.selected.index] = null
							gui.inventory.selected = null
							update_player()
						elif index != null and gui.inventory.selected.index != index and stack == null:
#drop on empty slot
							gui.inventory.selected.slot.item.get_node("item").rect_global_position = slot.slot.rect_global_position
							inv[index] = gui.inventory.selected.stack
							gui.inventory.selected.ref.inv[gui.inventory.selected.index] = null
							slot.item = gui.inventory.selected.slot.item 
							gui.inventory.selected.slot.item = null
							gui.inventory.selected = null
							update_player()
						elif index != null and gui.inventory.selected.index != index and gui.inventory.selected.stack.name == stack.name and stack.count < stack_reg.max_count:
#drop on stack
							var can_add = stack_reg.max_count - stack.count
							if can_add >= gui.inventory.selected.stack.count:
								inv[index].count += gui.inventory.selected.stack.count
								inv[gui.inventory.selected.index] = null
								slot.item.get_node("item/text").text = str(inv[index].count)
								gui.inventory.selected.slot.item.free()
								gui.inventory.selected.slot.item = null
								gui.inventory.selected = null
							else:
								inv[index].count += can_add
								gui.inventory.selected.ref.inv[gui.inventory.selected.index].count -= can_add
								slot.item.get_node("item/text").text = str(inv[index].count)
								gui.inventory.selected.slot.item.get_node("item/text").text = str(gui.inventory.selected.ref.inv[gui.inventory.selected.index].count)
								gui.inventory.selected.slot.item.get_node("item").rect_global_position = gui.inventory.selected.slot.slot.rect_global_position
								gui.inventory.selected = null
							update_player()
						else:
							gui.inventory.selected.slot.item.get_node("item").rect_global_position = gui.inventory.selected.slot.slot.rect_global_position
							gui.inventory.selected = null
			elif event is InputEventMouseMotion and gui.inventory.get("selected") != null and gui.inventory.selected.slot.get("item") != null:
				gui.inventory.selected.slot.item.get_node("item").rect_global_position = event.position-gui.inventory.selected.slot.item.get_node("item").rect_size/3
		return
	elif Input.is_action_just_pressed("switch_index_side"):
		var i = player.slot_index
		var r = player.right_slot
		var l = player.left_slot
		player.slot_index = l if i == r else r
		core.ui.slot_index(player.slot_index)
		change_wield_item()
	elif Input.is_action_just_pressed("throw_item"):
		var inv = core.get_inventory(player,"main")
		var stack = inv[player.slot_index]
		if stack != null:
			var pos = transform.origin
			var aim = -$head/Camera.get_global_transform().basis.z*15
			var stack2 = stack.duplicate()
			if Input.is_key_pressed(KEY_SHIFT):
				stack.count -= 1
				stack2.count = 1
			else:
				inv[player.slot_index] = null
			
			var d = core.spawn_drop_item($head.transform.origin+pos,stack2,player.name)
			d.set_linear_velocity(aim)
			update_player()
		
	elif Input.is_key_pressed(KEY_G) and cam_mode == 2:
			cam_mode = 1
			$head/Camera.current = true
			$head/tpv/Camera.current = false
			$mesh.visible = false
			#$head/tpv/Camera.set_cull_mask(1)
	elif Input.is_key_pressed(KEY_H) and cam_mode == 1:
# == fps
			cam_mode = 2
			$head/Camera.current = false
			$head/tpv/Camera.current = true
			$mesh.visible = true
	elif event is InputEventMouseMotion:
		if cam_mode == 1:
# == First player view
			rotate_y(deg2rad(-event.relative.x * fpv_mouse_sensitivity))
			var change = -event.relative.y * fpv_mouse_sensitivity
			if change + fpv_camera_angle < 90 and change + fpv_camera_angle > -90:
				$head/Camera.rotate_x(deg2rad(change))
				fpv_camera_angle += change
		elif cam_mode == 2:
# == Third player view
			rotate_y(-event.relative.x * tpv_camera_speed)
			$head/tpv.rotate_x(-event.relative.y * tpv_camera_speed)
	elif event is InputEventMouseButton:
		if Input.is_action_just_pressed("RMB"):
			phys_pickingup()
			using.right = true
			$head/Camera/right/anim.play("pick")
			$head/Camera/right/anim.get_animation("pick").set_loop(true)
		elif Input.is_action_just_released("RMB"):
			phys_pickingup(null,null,true)
			using.right = false
			using.right_time = 0
			$head/Camera/right/anim.get_animation("pick").set_loop(false)
		elif Input.is_action_just_pressed("LMB"):
				phys_pickingup()
				using.left = true
				$head/Camera/left/anim.play("pick")
				$head/Camera/left/anim.get_animation("pick").set_loop(true)
		elif Input.is_action_just_released("LMB"):
			phys_pickingup(null,null,true)
			using.left = false
			using.left_time = 0
			$head/Camera/left/anim.get_animation("pick").set_loop(false)
		if Input.is_action_just_pressed("WHEEL_DOWN"):
			player.slot_index += 1
			if player.slot_index >= player.hotbar_count:
				player.slot_index = 0
			core.ui.slot_index(player.slot_index)
			change_wield_item()
		elif Input.is_action_just_pressed("WHEEL_UP"):
			player.slot_index -= 1
			if player.slot_index < 0:
				player.slot_index = player.hotbar_count-1
			core.ui.slot_index(player.slot_index)
			change_wield_item()


func change_wield_item(inx:int = player.slot_index):
	var stack = player.inventory["main"][inx]
	stack = stack if stack != null else core.itemstack("wieldhand")
	var mesh = core.item2mesh(stack.name,true)
	if inx >= 4:
		player.right_slot = inx
		$head/Camera/right/anim.get_animation("pick").set_loop(false)
		$head/Camera/right/hand/item.mesh = mesh
		using.right_time = 0
	else:
		player.left_slot = inx
		$head/Camera/left/hand/item.mesh = mesh
		$head/Camera/left/anim.get_animation("pick").set_loop(false)
		$head/Camera/left/hand/item.mesh = mesh
		using.left_time = 0
	
func hand(right):
	var stack = player.inventory["main"][player.right_slot] if right else player.inventory["main"][player.left_slot]
	var pos = core.get_pointed_pos()
	stack = core.itemstack("wieldhand") if stack == null else stack
	var stack_reg = core.get_item_reg(stack.name)
	if stack_reg.type == "node" and core.place_node(stack.name):
		stack.count -= 1
		if stack.count <= 0:
			if right:
				player.inventory["main"][player.right_slot] = null
				$head/Camera/right/hand/item.mesh = null
				change_wield_item()
			else: 
				player.inventory["main"][player.left_slot] = null
				$head/Camera/left/hand/item.mesh = null
				change_wield_item()
	elif stack_reg.type == "item":
		var dur = stack_reg.get("item_capabilities")
		if dur != null and pos.inside != null:
			var node_reg = core.get_node_reg(pos.inside)
			var ngroups = core.item_groups(node_reg.name)
			var igroups = dur.groups
			for ig in igroups:
				for ng in ngroups:
					if ig == ng:
						if using.time <= 0:
							using.wear = ngroups[ng]
							using.pos = pos.inside
							using.time = ngroups[ng]
						if right:
							using.right_time = igroups[ig]
						else:
							using.left_time = igroups[ig]
						break
						break
	if using.time > 0 and (right and using.right_time > 0 or right == false and using.left_time > 0):
		var t = using.right_time + using.left_time
		if t == 0 or pos.inside != using.pos:
			using.time = 0
		else:
			using.time -= t
			if using.time <= 0:
				var wear = using.wear/2 if using.right_time > 0 and using.left_time > 0 else using.wear
				if using.right_time > 0:
					var s = player.inventory["main"][player.right_slot]
					if s != null and s.get("durability") != null:
						s.durability -= wear
						if s.durability <= 0:
							player.inventory["main"][player.right_slot] = null
							$head/Camera/right/hand/item.mesh = null
							change_wield_item()
				if using.left_time > 0:
					var s = player.inventory["main"][player.left_slot]
					if s != null and s.get("durability") != null:
						s.durability -= wear
						if s.durability <= 0:
							player.inventory["main"][player.left_slot] = null
							$head/Camera/left/hand/item.mesh = null
							change_wield_item()
				using.right_time = 0
				using.left_time = 0
				var drops = core.get_drop(using.pos)
				for i in drops:
					var stack2 = core.add_to_inventory(player,"main",drops[i])
					if stack2.count > 0:
						core.spawn_drop_item(transform.origin,stack2,player.name)
				
				core.set_node({name="air",pos=using.pos})
	core.ui.update_hotbar(player.inventory["main"])
	
func update_player():
	core.ui.update_hotbar(player.inventory["main"])
	change_wield_item(player.right_slot)
	change_wield_item(player.left_slot)

func _process(delta):
	if gui != null:
		return
# == walking
	direction = Vector3()
	var aim = $head/Camera.get_global_transform().basis
	var pos = transform.origin
	var con = Vector3()

	if phys_ray.enabled:
		phys_pickingup(pos,aim)
	if Input.is_key_pressed(KEY_W):
		con -= aim.z
	if Input.is_key_pressed(KEY_S):
		con += aim.z
	if Input.is_key_pressed(KEY_A):
		con -= aim.x
	if Input.is_key_pressed(KEY_D):
		con += aim.x
	if Input.is_action_just_pressed("fly_mode"):
			fly_mode = fly_mode == false
			$Collision.disabled = fly_mode
			velocity = Vector3(0,0,0)
	
	if fly_mode:
		if Input.is_key_pressed(KEY_SHIFT):
			con*=0.1
		transform.origin += con*0.2
	else:
		var on_floor = is_on_floor()
		direction = con
		direction = direction.normalized()
		if on_floor:
			velocity.y = 0
		elif core.chunk.chunk_loaded_at_pos(pos) == false:
			velocity.y = 0
			return
		else:
			#if player is inside a collidable block, freeze the movement to prevent falling through the ground
			var reg = core.get_node_reg(pos)
			if reg == null or reg.get("collidable") != false or reg.name == "none":
				if last_pos_before_fall != Vector3():
					last_pos_before_fall.y += 1
					transform.origin = last_pos_before_fall
					last_pos_before_fall = Vector3()
				return
			last_pos_before_fall = pos
			velocity.y += gravity * delta
		var tv = velocity
		tv = velocity.linear_interpolate(direction * walk_speed,15 * delta)
		velocity.x = tv.x
		velocity.z = tv.z
		velocity = move_and_slide(velocity,Vector3(0,1,0))
	# == jumping
		if on_floor and Input.is_key_pressed(KEY_SPACE):
			velocity.y = jump_height

func phys_pickingup(pos=null,aim=null,disable=false):
	var r = phys_object.right
	var l = phys_object.left
	var ur = using.right
	var ul = using.left
	
	if (r != null or l != null) and pos != null:
		if r != null and (is_instance_valid(r) == false or ur == false):
			phys_object.right = null
			return
		if l != null and (is_instance_valid(l) == false or ul == false):
			phys_object.left = null
			return
		if r != null and l != null:
			r.set_linear_velocity(((pos+$head.transform.origin+((-aim.z*3)+aim.x*1.2))-r.global_transform.origin)*10)
			l.set_linear_velocity(((pos+$head.transform.origin+((-aim.z*3)-aim.x*1.2))-l.global_transform.origin)*10)
		else:
			var ob = r if l == null else l
			ob.set_linear_velocity(((pos+$head.transform.origin+(-aim.z*3))-ob.global_transform.origin)*10)
	if r == null and l == null and disable:
		phys_ray.enabled = false
	else:
		phys_ray.enabled = true
	if phys_ray.is_colliding():
		var inv = player.inventory["main"]
		if using.right and inv[player.right_slot] == null or using.left and inv[player.left_slot] == null:
			var ob = phys_ray.get_collider()
			if ob is RigidBody:
				if using.right and phys_object.right == null:
					$head/Camera/right/anim.get_animation("pick").set_loop(false)
					phys_object.right = ob
				elif using.left  and phys_object.left == null:
					$head/Camera/left/anim.get_animation("pick").set_loop(false)
					phys_object.left = ob
