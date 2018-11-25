-- Hangglider mod for Minetest
-- Original code by Piezo_ (orderofthefourthwall@gmail.com)
-- 2018-11-14

-- Modifications by David G (kestral246@gmail.com)
-- 2018-11-24
-- For Minetest 5.x, glider's set_attach needs to be offset by 1 node
--     Switch to alternate commented line below with correct offset.
-- Additional tuning of parameters.
-- Commented out debug hud display code, prefixed with "--debug:".

-- 2018-11-22
-- Give visual indication that hangglider is equiped.
--     Display simple overlay with blurred struts when equiped.
--     Issue: don't know how to disable overlay in third person view.
-- Also Unequip hangglider when landing on water.
-- Attempt to linearize parabolic flight path.
--     Start gravity stronger, but gradually reduce it as descent velocity increases.
--     Don't use airstopper when equipped from the ground (descent velocity is low).
--     Slightly increase flight speed to 1.25.
-- Unequip/equip cycling mid-flight should not fly farther than continuous flight.
--     When equipping mid-air (descent velocity higher), use airstopper but increase descent slope afterwards.
--     Create airbreak flag so all equips mid-flight use faster descent.
--     Reset airbreak flag only when land (canExist goes false).
--     Issue: it wouldn't reset if land in water, use fly, and launch from air, before I added test for water,
--            not sure if there are other such cases.
-- Temporarily add hud debug display to show descent velocity, gravity override, and airbreak flag.
--     Still in process of tuning all the parameters.


-- Modifications by Piezo_
-- 2018-11-25
-- hud overlay and debug can be enabled/disabled
-- Added blender-rendered overlay for struts using the actual model.
-- Reduced airbreak penalty severity
-- gave glider limited durability.


local HUD_Overlay = true --show glider struts as overlay on HUD
local debug = false --show debug info in top-center of hud
hangglider = {} --Make this global, so other mods can tell if hangglider exists.
hangglider.use = {}
if HUD_Overlay then
hangglider.id = {}  -- hud id for displaying overlay with struts
end
if debug then  hangglider.debug = {} end -- hud id for debug data
hangglider.airbreak = {}  -- true if falling fast when equip

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
				local pname = player:get_player_name()
				if hangglider.use[pname] then
					local mrn_name = minetest.registered_nodes[minetest.get_node(vector.new(pos.x, pos.y-0.5, pos.z)).name]
					if mrn_name then
						if not (mrn_name.walkable or (mrn_name.drowning and mrn_name.drowning == 1)) then
							canExist = true
							local vel = player:get_player_velocity()
							local grav = player:get_physics_override().gravity
							if debug then player:hud_change(hangglider.debug[pname].id, "text", vel.y..', '..grav..', '..tostring(hangglider.airbreak[pname])) end
							-- If airbreaking used, increase the descent progression to not give
							-- mid-flight unequip/equip cycles a distance advantage.
							if hangglider.airbreak[pname] then
								if vel.y <= -4.0 then
									grav = -0.2 --Extreme measures are needed, as sometimes speed will get a bit out of control
								elseif vel.y <= -2.0 then
									grav = -0.02
								elseif vel.y <= -1.75 then
									grav = 0.00125  -- *1
								elseif vel.y <= -1.5 then
									grav = 0.0025  -- *2
								elseif vel.y <= -1.25 then
									grav = 0.005  -- *2
								elseif vel.y <= -1 then
									grav = 0.015  -- *3
								elseif vel.y <= -0.75 then
									grav = 0.04  -- *4
								elseif vel.y <= -0.5 then
									grav = 0.08  -- *4
								elseif vel.y <= -0.25 then
									grav = 0.12  -- *3
								elseif vel.y <= 0 then
									grav = 0.3  -- *3
								else  -- vel.y > 0
									grav = 0.75  -- *1.5
								end
							else  -- normal descent progression
								if vel.y <= -4.0 then
									grav = -0.2
								elseif vel.y <= -2.0 then
									grav = -0.02
								elseif vel.y <= -1.5 then
									grav = 0.00125
								elseif vel.y <= -1.25 then
									grav = 0.0025
								elseif vel.y <= -1 then
									grav = 0.005
								elseif vel.y <= -0.75 then
									grav = 0.01
								elseif vel.y <= -0.5 then
									grav = 0.02
								elseif vel.y <= -0.25 then
									grav = 0.04
								elseif vel.y <= 0 then
									grav = 0.1
								else  -- vel.y > 0
									grav = 0.5
								end
							end
							player:set_physics_override({gravity = grav})
						end
					end
				end
				if not canExist then
					player:set_physics_override({
						gravity = 1,
						jump = 1,
						speed = 1,
					})
					hangglider.use[pname] = false
					if HUD_Overlay then
					player:hud_change(hangglider.id[pname], "text", "blank.png")
					end
					hangglider.airbreak[pname] = false
				end
			end
		end
		if not canExist then 
			self.object:set_detach()
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
	local pname = player:get_player_name()
	player:set_physics_override({
		gravity = 1,
		jump = 1,
	})
	hangglider.use[pname] = false
	if HUD_Overlay then
	hangglider.id[pname] = player:hud_add({
		hud_elem_type = "image",
		text = "blank.png",
		position = {x=0, y=0},
		scale = {x=-100, y=-100},
		alignment = {x=1, y=1},
		offset = {x=0, y=0}
	}) end
	if debug then 
		hangglider.debug[pname] = {id = player:hud_add({hud_elem_type = "text",
			position = {x=0.5, y=0.1},
			text = "-",
			number = 0xFF0000}),  -- red text
			-- ht = {50,50,50},
		}
	end
	hangglider.airbreak[pname] = false
end)

minetest.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()
	hangglider.use[pname] = nil
	if HUD_Overlay then hangglider.id[pname] = nil end
	if debug then hangglider.debug[pname] = nil end
	hangglider.airbreak[pname] = nil
end)

minetest.register_tool("hangglider:hangglider", {
	description = "Glider",
	inventory_image = "glider_item.png",
	stack_max=1,
	on_use = function(itemstack, user, pointed_thing)
		if not user then
			return
		end
		local pos = user:get_pos()
		local pname = user:get_player_name()
		if minetest.get_node(pos).name == "air" and not hangglider.use[pname] then --Equip
			minetest.sound_play("bedsheet", {pos=pos, max_hear_distance = 8, gain = 1.0})
			if HUD_Overlay then user:hud_change(hangglider.id[pname], "text", "glider_struts.png") end
			local vel = user:get_player_velocity().y
			if vel < -2 then  -- engage mid-air, falling fast, so stop but ramp velocity more quickly
				hangglider.airbreak[pname] = true
				user:set_physics_override({
					gravity = 1,
					jump = 0,
					speed = 1.75,
				})
				local stopper = minetest.add_entity(pos, "hangglider:airstopper")
				stopper:get_luaentity().attach = user
				user:set_attach( stopper, "", {x=0,y=0,z=0}, {x=0,y=0,z=0})
			else
				user:set_physics_override({
					gravity = 0.02,
					jump = 0,
					speed = 1.75,
				})
			end
			hangglider.use[pname] = true
			-- if minetest 0.4.x use this:
			minetest.add_entity(user:get_pos(), "hangglider:glider"):set_attach(user, "", {x=0,y=0,z=0}, {x=0,y=0,z=0})
			-- if minetest 5.x use this:
			-- minetest.add_entity(user:get_pos(), "hangglider:glider"):set_attach(user, "", {x=0,y=10,z=0}, {x=0,y=0,z=0})
			itemstack:set_wear(itemstack:get_wear() + 255)
			return itemstack
		elseif hangglider.use[pname] then --Unequip
			if HUD_Overlay then user:hud_change(hangglider.id[pname], "text", "blank.png") end
			hangglider.use[pname] = false
		end
	end,
	sound = {breaks = "default_tool_breaks"},
})

minetest.register_craft({
	output = "hangglider:hangglider",
	recipe = {
		{"wool:white", "wool:white", "wool:white"},
		{"default:stick", "", "default:stick"},
		{"", "default:stick", ""},
	}
})
