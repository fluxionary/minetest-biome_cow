biome_cow = fmod.create()

if biome_cow.has.ethereal then
	futil.add_groups("ethereal:crystalgrass", { grass = 1 })
	futil.add_groups("ethereal:dry_shrub", { grass = 1 })
	futil.add_groups("ethereal:snowygrass", { grass = 1 })
end

local S = biome_cow.S

local get_biome_id = minetest.get_biome_id
local get_item_group = minetest.get_item_group
local swap_node = minetest.swap_node

biome_cow.soil_by_biome = {}
biome_cow.grass_by_soil = {}
biome_cow.flora_by_soil = {}

function biome_cow.is_grass(decoration, soil)
	return get_item_group(decoration, "grass") > 0
		or (soil:match("mushroom") and get_item_group(decoration, "mushroom") > 0)
end

function biome_cow.is_flora(decoration)
	return get_item_group(decoration, "grass") == 0
		and (
			get_item_group(decoration, "flora") > 0
			or get_item_group(decoration, "mushroom") > 0
			or get_item_group(decoration, "plant") > 0
			or get_item_group(decoration, "flower") > 0
		)
end

function biome_cow.is_soil(decoration)
	return get_item_group(decoration, "soil") > 0
end

function biome_cow.is_place_on_soil(place_on)
	if type(place_on) == "string" then
		return get_item_group(place_on, "soil") > 0
	else
		for _, place_on2 in ipairs(place_on) do
			if biome_cow.is_place_on_soil(place_on2) then
				return true
			end
		end
	end

	return false
end

function biome_cow.register_soil_decor(soil, decoration)
	if type(soil) ~= "string" then
		for _, soil2 in ipairs(soil) do
			biome_cow.register_soil_decor(soil2, decoration)
		end

		return
	end

	if get_item_group(soil, "soil") <= 0 then
		return
	end

	if type(decoration) ~= "string" then
		for _, decoration2 in ipairs(decoration) do
			biome_cow.register_soil_decor(soil, decoration2)
		end

		return
	end

	local deco_def = minetest.registered_nodes[decoration]
	if not deco_def or deco_def.walkable then
		return
	end

	if biome_cow.is_grass(decoration, soil) then
		local grasses = biome_cow.grass_by_soil[soil] or {}
		if table.indexof(grasses, decoration) == -1 then
			table.insert(grasses, decoration)
		end
		biome_cow.grass_by_soil[soil] = grasses
	end

	if biome_cow.is_flora(decoration) then
		local flora = biome_cow.flora_by_soil[soil] or {}
		if table.indexof(flora, decoration) == -1 then
			table.insert(flora, decoration)
		end
		biome_cow.flora_by_soil[soil] = flora
	end
end

minetest.register_on_mods_loaded(function()
	for biome, def in pairs(minetest.registered_biomes) do
		if biome_cow.is_soil(def.node_top) then
			biome_cow.soil_by_biome[get_biome_id(biome)] = def.node_top
		end
	end

	for _, def in pairs(minetest.registered_decorations) do
		if def.deco_type == "simple" and biome_cow.is_place_on_soil(def.place_on) then
			biome_cow.register_soil_decor(def.place_on, def.decoration)
		end
	end
end)

mobs:register_mob("biome_cow:biome_cow", {
	type = "animal",
	passive = false,
	attack_type = "dogfight",
	attack_npcs = false,
	reach = 2,
	damage = 4,
	hp_min = 5,
	hp_max = 20,
	armor = 200,
	collisionbox = { -0.4, -0.01, -0.4, 0.4, 1.2, 0.4 },
	visual = "mesh",
	mesh = "mobs_cow.b3d",
	textures = {
		{ "flower_cow.png^[multiply:#0f0" },
		{ "flower_cow2.png^[multiply:#0f0" },
	},
	makes_footstep_sound = true,
	sounds = {
		random = "mobs_cow",
	},
	walk_velocity = 1,
	run_velocity = 2,
	jump = true,
	jump_height = 6,
	pushable = true,
	drops = {
		{ name = "mobs:meat_raw", chance = 1, min = 1, max = 3 },
		{ name = "mobs:leather", chance = 1, min = 0, max = 2 },
	},
	water_damage = 0,
	lava_damage = 5,
	light_damage = 0,
	animation = {
		stand_start = 0,
		stand_end = 30,
		stand_speed = 20,
		stand1_start = 35,
		stand1_end = 75,
		stand1_speed = 20,
		walk_start = 85,
		walk_end = 114,
		walk_speed = 20,
		run_start = 120,
		run_end = 140,
		run_speed = 30,
		punch_start = 145,
		punch_end = 160,
		punch_speed = 20,
		die_start = 165,
		die_end = 185,
		die_speed = 10,
		die_loop = false,
	},
	follow = {
		"default:grass_1",
		"bonemeal:mulch",
		"bonemeal:bonemeal",
		"bonemeal:fertiliser",
	},
	view_range = 8,
	replace_rate = 1,
	replace_what = {
		{ "air", "group:grass", 0 },
		{ "group:grass", "group:flora", 0 },
		{ "default:dirt", "default:dirt_with_grass", -1 },
	},
	stay_near = { { "farming:straw", "farming:jackolantern_on" }, 5 },
	fear_height = 2,
	on_rightclick = function(self, clicker)
		-- feed or tame
		if mobs:feed_tame(self, clicker, 8, true, true) then
			-- if fed 7x wheat or grass then cow can be milked again
			if self.food and self.food > 6 then
				self.gotten = false
			end

			return
		end

		if mobs:protect(self, clicker) then
			return
		end
		if mobs:capture_mob(self, clicker, 0, 5, 60, false, nil) then
			return
		end

		local tool = clicker:get_wielded_item()
		local name = clicker:get_player_name()

		-- milk cow with empty bucket
		if tool:get_name() == "bucket:bucket_empty" then
			--if self.gotten == true
			if self.child == true then
				return
			end

			if self.gotten == true then
				minetest.chat_send_player(name, "biome cow already milked!")
				return
			end

			local inv = clicker:get_inventory()

			tool:take_item()
			clicker:set_wielded_item(tool)

			if inv:room_for_item("main", { name = "mobs:bucket_milk" }) then
				clicker:get_inventory():add_item("main", "mobs:bucket_milk")
			else
				local pos = self.object:get_pos()
				pos.y = pos.y + 0.5
				minetest.add_item(pos, { name = "mobs:bucket_milk" })
			end

			self.gotten = true -- milked

			return
		end
	end,

	on_replace = function(self, pos, oldnode, newnode)
		local pos_below = vector.new(pos.x, pos.y - 1, pos.z)
		local owner = self.owner or ""
		local is_protected = minetest.is_protected(pos, owner) or minetest.is_protected(pos_below, owner)
		if is_protected then
			return false
		end

		local node_below = minetest.get_node(pos_below)
		local name_below = node_below.name

		if not biome_cow.is_soil(name_below) then
			return false
		end

		local biome_data_below = minetest.get_biome_data(pos_below)
		local biome_id = biome_data_below.biome
		local expected_soil = biome_cow.soil_by_biome[biome_id]

		if name_below == "default:dirt" then
			node_below.name = expected_soil or "default:dirt_with_grass"
			swap_node(pos_below, node_below)
		elseif (oldnode.name or oldnode) == "air" then
			local grasses = biome_cow.grass_by_soil[node_below.name] or {}
			if #grasses > 0 then
				swap_node(pos, { name = grasses[math.random(#grasses)] })
			end
		else
			local flora = biome_cow.flora_by_soil[node_below.name] or {}
			if #flora > 0 then
				swap_node(pos, { name = flora[math.random(#flora)] })
			end
		end

		if self.gotten then
			self.food = (self.food or 0) + 1
		end

		if (self.food or 0) >= 8 then
			self.food = 0
			self.gotten = false -- milkable again
		end

		return false
	end,
})

if not mobs.custom_spawn_animal then
	mobs:spawn({
		name = "biome_cow:biome_cow",
		nodes = { "group:soil" },
		min_light = 14,
		interval = 60,
		chance = 80000, -- 15000
		min_height = 5,
		max_height = 200,
		day_toggle = true,
	})
end

mobs:register_egg("biome_cow:biome_cow", S("biome cow"), "flower_cow_inv.png^[multiply:#0f0")
