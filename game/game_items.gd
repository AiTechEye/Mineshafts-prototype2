extends Node

func _ready():
	core.register_node({
		name = "default:chest",
		groups={woody=3},
		on_activate=funcref(GameBase,"chest"),
		tiles = [
			"res://game/textures/default_chest_top.png",
			"res://game/textures/default_chest_top.png"
			,"res://game/textures/default_chest_front.png"
			,"res://game/textures/default_chest_side.png"
			,"res://game/textures/default_chest_side.png"
			,"res://game/textures/default_chest_side.png"
		]
	})
	core.register_node({
		name="default:stone",
		tiles=["res://game/textures/stone.png"],
		groups={cracky=3},
		max_count=100,
		drop={"default:cobble":{count=1},"default:stone":{count=1,chance=10,additional=false}}
	})
	core.register_node({
		name="default:cobble",
		tiles=["res://game/textures/cobble.png"],
		groups={cracky=3},
		max_count=1000,
	})
	core.register_node({
		name="default:grassy",
		groups={crumbly=3},
		drop={"default:dirt":{count=1},"default:grassy":{count=1,chance=10,additional=false}},
		tiles=[
			"res://game/textures/grass.png",
			"res://game/textures/dirt.png",
			"res://game/textures/grass_dirt.png",
			"res://game/textures/grass_dirt.png",
			"res://game/textures/grass_dirt.png",
			"res://game/textures/grass_dirt.png"
			]
	})
	core.register_node({
		name="default:dirt",
		tiles=["res://game/textures/dirt.png"],
		groups={crumbly=3},
	})
	core.register_node({
		name="default:water_source",
		replaceable=true,
		drawtype="liquid",
		collidable=false,
		transparent=true,
		solid_surface=false,
		tiles=["res://game/textures/water.png"],
		max_count=100
	})
	core.register_node({
		name="default:glass",
		transparent=true,
		solid_surface=false,
		tiles=["res://game/textures/default_glass.png"],
		groups={cracky=3}
	})
	core.register_node({
		name="default:wood",
		tiles=["res://game/textures/default_wood.png"],
		groups={woody=3}
	})


