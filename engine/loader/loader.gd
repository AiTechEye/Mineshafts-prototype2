extends Control

var progressions = {0:"loading..."}
func _ready():
	core.Loader = self

func setprogress(v):
	$progressbar.value = v
	for i in progressions:
		if v >= i:
			$progressbar/label.text = progressions[i]
	if v >= $progressbar.max_value:
		visible = false
func end():
	visible = false
func start(end,p=null):
	#core.main.move_child(core.main.get_node("loader"),core.main.get_child_count())
	progressions = p
	$progressbar.value = 0
	$progressbar.max_value = end
	visible = true
