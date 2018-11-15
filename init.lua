hangglider = {}
hangglider.use = {}

minetest.register_entity("hangglider:airstopper", { --A one-instant entity that catches the player and slows them down.
	hp_max = 3,
	is_visible = false,
	immortal = true,
	attach = nil,
	on_step = function(self, _)
		if self.object:get_hp() ~= 1 then
			self.object:set_hp(self.object:get_hp() - 1)
		else
			if self.attach then
				self.attach:set_detach()
			end
			self.object:remove()
		end
	end
})

minetest.register_entity("hangglider:glider", {
	visual = "mesh",
	visual_size = {x = 12, y = 12},
	mesh = "glider.obj",
	immortal = true,
	static_save = false,
	textures = {"wool_white.png","default_wood.png"},
	on_step = function(self, _)
		local canExist = false
		if self.object:get_attach() then
			local player = self.object:get_attach("parent")
			if player then
				local pos = player:getpos()
				if hangglider.use[player:get_player_name()] then
					if minetest.registered_nodes[minetest.get_node(vector.new(pos.x, pos.y-0.5, pos.z)).name] then
						if not minetest.registered_nodes[minetest.get_node(vector.new(pos.x, pos.y-0.5, pos.z)).name].walkable then
							canExist = true
							if player:get_player_velocity().y > -4.5 and player:get_physics_override().gravity < 0 then
								player:set_physics_override({
									gravity = 0.02,
								})
							elseif player:get_player_velocity().y < -5 and player:get_physics_override().gravity > 0 then
								player:set_physics_override({
									gravity = -0.02,
								})
							end
						end
					end
				end
				if not canExist then
					player:set_physics_override({
						gravity = 1,
						jump = 1,
					})
					hangglider.use[player:get_player_name()] = false
				end
			end
		end
		if not canExist then 
			self.object:remove() 
		end
	end
})

minetest.register_on_dieplayer(function(player)
	player:set_physics_override({
		gravity = 1,
		jump = 1,
	})
	hangglider.use[player:get_player_name()] = false
end)


minetest.register_on_joinplayer(function(player)
	player:set_physics_override({
		gravity = 1,
		jump = 1,
	})
	hangglider.use[player:get_player_name()] = false
end)

minetest.register_on_leaveplayer(function(player)
	hangglider.use[player:get_player_name()] = nil
end)

minetest.register_craftitem("hangglider:hangglider", {
	description = "Glider",
	inventory_image = "glider_item.png",
	
	on_use = function(itemstack, user, pointed_thing)
		if not user then
			return
		end
		local pos = user:get_pos()
		if minetest.get_node(pos).name == "air" and not hangglider.use[user:get_player_name()] then --Equip
			minetest.sound_play("bedsheet", {pos=pos, max_hear_distance = 8, gain = 1.0})
			user:set_physics_override({
				gravity = 0.02,
				jump = 0,
			})
			local stopper = minetest.add_entity(pos, "hangglider:airstopper")
			stopper:get_luaentity().attach = user
			user:set_attach( stopper, "", {x=0,y=0,z=0}, {x=0,y=0,z=0})
			hangglider.use[user:get_player_name()] = true
			minetest.add_entity(user:get_pos(), "hangglider:glider"):set_attach(user, "", {x=0,y=0,z=0}, {x=0,y=0,z=0})
			
		elseif hangglider.use[user:get_player_name()] then --Unequip
			user:set_physics_override({
				gravity = 1,
				jump = 1,
			})
			hangglider.use[user:get_player_name()] = false
		end
	end
})

minetest.register_craft({
	output = "hangglider:hangglider",
	recipe = {
		{"wool:white", "wool:white", "wool:white"},
		{"default:stick", "", "default:stick"},
		{"", "default:stick", ""},
	}
})
