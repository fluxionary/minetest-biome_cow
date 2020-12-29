

-- Cow by sirrobzeroone, then Krupnov Pavel, then TenPlus1. Flower cow by DrPlamsa

mobs:register_mob("flower_cow:flower_cow", {
	type = "animal",
	passive = false,
	attack_type = "dogfight",
	attack_npcs = false,
	reach = 2,
	damage = 4,
	hp_min = 5,
	hp_max = 20,
	armor = 200,
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1.2, 0.4},
	visual = "mesh",
	mesh = "mobs_cow.b3d",
	textures = {
		{"flower_cow.png"},
		--{"flower_cow2.png"},
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
		{name = "mobs:meat_raw", chance = 1, min = 1, max = 3},
		{name = "mobs:leather", chance = 1, min = 0, max = 2},
		{name = "flowers:rose", chance = 1, min = 0, max = 2},
		{name = "flowers:tulip", chance = 1, min = 0, max = 2},
		{name = "flowers:dandelion_yellow", chance = 1, min = 0, max = 2},
		{name = "flowers:geranium", chance = 1, min = 0, max = 2},
		{name = "flowers:viola", chance = 1, min = 0, max = 2},
		{name = "flowers:dandelion_white", chance = 1, min = 0, max = 2},
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
		"default:grass_1", "bonemeal:mulch", "bonemeal:bonemeal", "bonemeal:fertiliser"
	},
	view_range = 8,
	replace_rate = 1,
	replace_what = {
		{"air", "default:grass_1", 0},
		{"air", "default:grass_2", 0},
		{"air", "default:grass_3", 0},
		{"air", "default:grass_4", 0},
		{"air", "default:grass_5", 0},
		{"group:grass", "flowers:rose", 0},
		{"group:grass", "flowers:tulip", 0},
		{"group:grass", "flowers:dandelion_yellow", 0},
		{"group:grass", "flowers:geranium", 0},
		{"group:grass", "flowers:viola", 0},
		{"group:grass", "flowers:dandelion_white", 0},
		{"default:dirt", "default:dirt_with_grass", -1}
	},
--	stay_near = {{"farming:straw", "group:grass"}, 10},
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

		if mobs:protect(self, clicker) then return end
		if mobs:capture_mob(self, clicker, 0, 5, 60, false, nil) then return end

		local tool = clicker:get_wielded_item()
		local name = clicker:get_player_name()

		-- milk cow with empty bucket
		if tool:get_name() == "bucket:bucket_empty" then

			--if self.gotten == true
			if self.child == true then
				return
			end

			if self.gotten == true then
				minetest.chat_send_player(name,
					S("Flower cow already milked!"))
				return
			end

			local inv = clicker:get_inventory()

			tool:take_item()
			clicker:set_wielded_item(tool)

			if inv:room_for_item("main", {name = "mobs:bucket_milk"}) then
				clicker:get_inventory():add_item("main", "mobs:bucket_milk")
			else
				local pos = self.object:get_pos()
				pos.y = pos.y + 0.5
				minetest.add_item(pos, {name = "mobs:bucket_milk"})
			end

			self.gotten = true -- milked

			return
		end
	end,

	on_replace = function(self, pos, oldnode, newnode)

		self.food = (self.food or 0) + 1

		-- if cow replaces 8x grass then it can be milked again
		if self.food >= 8 then
			self.food = 0
			self.gotten = false
		end
	end,
})


if not mobs.custom_spawn_animal then
mobs:spawn({
	name = "flower_cow:flower_cow",
	nodes = {"default:dirt_with_grass", "ethereal:green_dirt"},
	neighbors = {"group:grass"},
	min_light = 14,
	interval = 60,
	chance = 80000, -- 15000
	min_height = 5,
	max_height = 200,
	day_toggle = true,
})
end


mobs:register_egg("flower_cow:flower_cow", "Flower cow", "mobs_cow_inv.png")




