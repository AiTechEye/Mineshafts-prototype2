extends RigidBody

var object
var timer = 300
var droper
var sleep = false
var last_pos = Vector3()

func spawn(pos,stack,der=null,ob=null):
	object = ob
	droper = der
	last_pos = pos
	transform.origin = pos
	$mesh.mesh = core.item2mesh(stack.name)
	var reg = core.get_item_reg(stack.name)
	if reg.type == "item":
		$collision.scale = Vector3(0.62,0.65,0.1)
	core.add_to_inventory(object,"main",stack)
	item()
func _process(delta):
	timer -= delta
	var pos = transform.origin.round()
	if core.map.get(pos) == null:
		sleep = true
		sleeping = true
	elif sleep:
		sleeping = false
		sleep = false
	var reg = core.get_node_reg(pos)
	if reg != null and reg.drawtype == "default":
		transform.origin = last_pos
	else:
		last_pos = pos
	if timer < 0:
		set_process(false)
		queue_free()

func _ready():
	timer = core.settings.item_drop_timeout
	
func item():
	var stack = core.get_inventory(object,"main")[0]
	if stack == null:
		set_process(false)
		queue_free()
		return
	$mesh.mesh = core.item2mesh(stack.name)
	var reg = core.get_item_reg(stack.name)
	if reg.type == "item":
		$collision.scale = Vector3(0.62,0.65,0.1)
func on_spawn(ob):
	object = ob
func on_load(ob):
	object = ob
	sleeping = true
	item()

func _on_area_body_entered(body):
	var ob = body.get("player")
	var itemdrop = false
	if body.get("object") != null and body.object.type == "item_drop" and body.object.id != object.id:
		ob = body.object
		var inv1 = core.get_inventory(object,"main")[0]
		var inv2 = core.get_inventory(ob,"main")[0]
		if inv1.name == inv2.name and (inv1.count < core.get_item_reg(inv2.name).max_count):
			itemdrop = true

	if ob != null and droper != ob.name or itemdrop:
		var stack = core.get_inventory(object,"main")[0]
		var leftover = core.add_to_inventory(ob,"main",stack)
		if body.get("player") != null:
			body.update_player()
		if leftover.count > 0:
			stack.count = leftover.count
		else:
			queue_free()
		return

func _on_Timer_timeout():
	droper = null
	$collision.disabled = false
