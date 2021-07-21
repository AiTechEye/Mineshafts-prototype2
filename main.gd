extends Spatial

func _init():
	core.main = self
	set_process(false)
func close_msg():
	$exitmsg.visible = false
