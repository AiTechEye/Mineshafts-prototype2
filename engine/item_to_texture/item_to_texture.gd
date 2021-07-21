extends Spatial

func texture(a):
	$viewport/mesh.mesh = core.item2mesh(a)
	var reg = core.get_item_reg(a)
	if reg.type == "item":
		$viewport/mesh.transform.origin = Vector3(0.3,-0.1,0)
		$viewport/mesh.scale = Vector3(1.2,1.2,1.2)
		$viewport/mesh.rotation = Vector3(0,3.5,0)
	return $viewport.get_texture()
