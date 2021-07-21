extends Control

func center(node):
	var s = get_viewport_rect().size/2
	var c = node.rect_size / 2
	node.rect_position = s - c
func buttom(node):
	var s = get_viewport_rect().size
	node.rect_position = Vector2(node.rect_position.x,s.y-node.rect_size.y)
func slot_index(i):
	if i > 3:
		$hotbar/slotr.rect_position.x = (($hotbar/slotr.rect_size.x))*i
		$hotbar/slotr/active.visible = true
		$hotbar/slotl/active.visible = false
	else:
		$hotbar/slotl.rect_position.x = (($hotbar/slotl.rect_size.x))*i
		$hotbar/slotl/active.visible = true
		$hotbar/slotr/active.visible = false
func update_hotbar(inv):
	var s = $hotbar/slotr.rect_size
	var l = 8 if inv.size() >= 8 else inv.size()
	for i in l:
		var c = $hotbar.get_node_or_null(str(i))
		if c != null:
			c.free()
	for i in l:
		var it = inv[i]
		if it != null:
			var t = core.stack_2invitem(it)
			t.get_node("item").rect_position = Vector2((s.x*i)+4,4)
			#t.rect_size = Vector2(s.x-8,s.x-8)
			t.get_node("item").rect_scale = Vector2(s.x*0.0091,s.x*0.0091)
			t.name = str(i)
			$hotbar.add_child(t)

func _ready():
	core.ui = self
	center($crosshair)
	center($hotbar)
	buttom($hotbar)

	var p = OS.get_screen_size()/2
	var s = OS.window_size/2
	var winpos = p-s
	winpos.y = 0 #now we can see the output
	OS.set_window_position(winpos)
	#yield(get_tree().create_timer(0.1),"timeout")
	#OS.window_size = Vector2(700,700)
	#OS.window_maximized = true
	#OS.window_fullscreen = true


func pause():
	core.game_pause()
	$manu.visible = core.game_paused
	
func quit_to_main():
	$manu.visible = false
	core.world_quit()
func quit_game():
	core.world_quit(true)
	
func _input(event):
	if core.game != null and core.player.object.gui == null and Input.is_action_just_pressed("ui_cancel"):
		if core.game_paused:
			core.game_pause()
			$manu.visible = false
		else:
			core.game_pause()
			$manu.visible = true
