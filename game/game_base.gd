extends Node

func chest(pos,reg):
	if reg.name == "default:chest":
		if core.existsMeta(pos) == false:
			core.create_node_inventory(pos,"main",32,[
				core.itemstack("default:chest",{count=10}),
				core.itemstack("default:stone_pick",{count=100}),
				core.itemstack("default:grassy",{count=100}),
				core.itemstack("default:stone_hoe"),
				core.itemstack("default:stone_shovel"),
				core.itemstack("default:axe_stone"),
				core.itemstack("default:stone_pick"),
				core.itemstack("default:stick",{count=100}),
				core.itemstack("default",{count=100}),
				core.itemstack("default:stone",{count=100}),
				core.itemstack("default:cobble",{count=1000}),
				core.itemstack("default:dirt",{count=100}),
				core.itemstack("default:water_source",{count=100}),
				core.itemstack("default:glass",{count=100}),
				core.itemstack("default:wood",{count=100})
				])
		GUI.show(core.player,"background[8;8.5]inventory[player:player1;main;0;4.5;8;4]inventory[node:"+var2str(pos)+";main;0;0;8;4]")
