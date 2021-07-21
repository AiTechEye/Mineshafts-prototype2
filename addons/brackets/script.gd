tool
extends EditorPlugin
var dock

func _enter_tree():
	dock = preload("res://addons/brackets/dock.tscn").instance()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR,dock)
	dock.get_node("[").connect("button_down",self,"b1")
	dock.get_node("]").connect("button_down",self,"b2")
	dock.get_node("[]").connect("button_down",self,"b3")
	dock.get_node("{").connect("button_down",self,"b4")
	dock.get_node("}").connect("button_down",self,"b5")
	dock.get_node("{}").connect("button_down",self,"b6")
	dock.get_node("$").connect("button_down",self,"b7")
func _exit_tree():
	remove_control_from_docks(dock)
func b1():
	OS.set_clipboard("[")
func b2():
	OS.set_clipboard("]")
func b3():
	OS.set_clipboard("[]")
func b4():
	OS.set_clipboard("{")
func b5():
	OS.set_clipboard("}")
func b6():
	OS.set_clipboard("{}")
func b7():
	OS.set_clipboard("$")
	
	
	
