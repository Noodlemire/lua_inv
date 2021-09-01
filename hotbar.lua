--[[
Complete and Total Lua-Only Inventory Rewrite
Copyright (C) 2021 Noodlemire

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
--]]

local hotbar_data = {}

local default_ratio = minetest.settings:get("screen_w") / minetest.settings:get("screen_h")

local function default_pos(i)
	--0.348 + .0435 * (i - 1), 0.9625
	return 0.30555 + .05555 * (i - 1), -32
end

function lua_inv.update_hotbar(player)
	local pname = player:get_player_name()

	if not lua_inv.player_inventory[pname] then return end

	local inv = lua_inv.player_inventory[pname].inv

	for i = 1, 8 do
		local img = "blank.png"
		local count_txt = ""
		local wear_img = "blank.png"

		local stack = inv:get_stack("main", i)

		if not stack:is_empty() then
			img = stack:get_inventory_image()

			if stack:get_count() > 1 then
				count_txt = stack:get_count()
			end

			if stack:get_wear() > 0 then
				wear_img = stack:get_wear_visual()
			end

			local anim = stack:get_animation()
			if anim then
				local anim_data = hotbar_data[pname].animation[i]
				local frame = anim_data and anim_data.frame or 1
				anim = stack:get_animation(frame)

				img = anim.frame_template and anim.frame_template:format(frame) or img

				hotbar_data[pname].animation[i] = anim_data or {}
				anim_data = hotbar_data[pname].animation[i]

				anim_data.frame = anim_data.frame or 1
				anim_data.max_frame = anim_data.max_frame or anim.frames
				anim_data.time = anim.speed
			elseif hotbar_data[pname].animation[i] then
				hotbar_data[pname].animation[i] = nil
			end
		elseif hotbar_data[pname].animation[i] then
			hotbar_data[pname].animation[i] = nil
		end

		if not hotbar_data[pname]["hotbar_slot_"..i] then
			local x, y = default_pos(i)

			hotbar_data[pname]["hotbar_slot_"..i] = player:hud_add({
				hud_elem_type = "image",
				text = img,

				scale = {x = -4, y = -4 * hotbar_data[pname].aspect_ratio},
				position = {x = 0.5, y = 1},
				direction = 1,
				alignment = {x = 0, y = 0},
				offset = {x = x * 1000 - 500, y = y},
				z_index = 1
			})

			hotbar_data[pname]["hotbar_slot_count_"..i] = player:hud_add({
				hud_elem_type = "text",
				text = count_txt,
				number = "0xFFFFFF",

				scale = {x = -4, y = -4 * hotbar_data[pname].aspect_ratio},
				position = {x = 0.5, y = 1},
				direction = 1,
				alignment = {x = 0, y = 0},
				offset = {x = (x + 0.015) * 1000 - 500, y = y + 16},
				z_index = 1
			})

			hotbar_data[pname]["hotbar_slot_wear_"..i] = player:hud_add({
				hud_elem_type = "image",
				text = wear_img,

				scale = {x = -4, y = -4 * hotbar_data[pname].aspect_ratio},
				position = {x = 0.5, y = 1},
				direction = 1,
				alignment = {x = 0, y = 0},
				offset = {x = x * 1000 - 500, y = y},
				z_index = 1
			})
		else
			player:hud_change(hotbar_data[pname]["hotbar_slot_"..i], "text", img)
			player:hud_change(hotbar_data[pname]["hotbar_slot_count_"..i], "text", count_txt)
			player:hud_change(hotbar_data[pname]["hotbar_slot_wear_"..i], "text", wear_img)
		end
	end
end

minetest.register_on_joinplayer(function(player, last_login)
	local pname = player:get_player_name()
	local x, y = default_pos(1)

	hotbar_data[pname] = {
		wield_index = player:get_wield_index(),
		aspect_ratio = default_ratio,
		animation = {}
	}

	minetest.after(0.25, player.hud_set_flags,  player, {hotbar = false})

	player:hud_add({
		hud_elem_type = "image",
		text = "lua_inv_hotbar.png",

		scale = {x = 0.75, y = 0.75},
		position = {x = 0.5, y = 1},
		direction = 1,
		alignment = {x = 0, y = 0},
		offset = {x = 0, y = y},
		z_index = 0
	})

	hotbar_data[pname].hotbar_wield_index = player:hud_add({
		hud_elem_type = "image",
		text = "lua_inv_selected.png",

		scale = {x = 3.25, y = 3.25},
		position = {x = 0.5, y = 1},
		direction = 1,
		alignment = {x = 0, y = 0},
		offset = {x = x * 1000 - 500, y = y},
		z_index = 2
	})

	minetest.after(0.1, lua_inv.update_hotbar, player)

	if not last_login then
		minetest.chat_send_player(pname, "Some parts of your HUD may be distored. This is normal. You can fix it using /set_aspect_ratio.")
	end
end)

minetest.register_globalstep(function(dtime)
	for _, player in pairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		if not hotbar_data[pname] then return end

		local update_hotbar = false

		for i = 1, 8 do
			--if not update_hotbar and (hotbar_data[pname].animation[i] == nil) ~= (lua_inv.player_inventory[pname].inv:get_stack("main", i):get_animation() == nil) then
				--update_hotbar = true
			--end

			if hotbar_data[pname].animation[i] then
				hotbar_data[pname].animation[i].time = hotbar_data[pname].animation[i].time - dtime * 1000

				if hotbar_data[pname].animation[i].time < 0 then
					hotbar_data[pname].animation[i].frame = hotbar_data[pname].animation[i].frame + 1

					if hotbar_data[pname].animation[i].frame > hotbar_data[pname].animation[i].max_frame then
						hotbar_data[pname].animation[i].frame = 1
					end

					update_hotbar = true
				end
			end
		end

		if hotbar_data[pname].wield_index ~= player:get_wield_index() then
			hotbar_data[pname].wield_index = player:get_wield_index()
			local x, y = default_pos(hotbar_data[pname].wield_index)

			player:hud_change(hotbar_data[pname].hotbar_wield_index, "offset", {x = x * 1000 - 500, y = y})

			lua_inv.update_held_item_data(player)
		end

		if update_hotbar then
			lua_inv.update_hotbar(player)
		end
	end
end)

minetest.register_chatcommand("set_aspect_ratio", {
	description = "Set your aspect ratio to fix distorted HUD elements.",

	params = "[width,height|ratio]",

	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		local ratio = param:split(',', false, 1)

		if ratio[2] then
			local n1, n2 = tonumber(ratio[1]), tonumber(ratio[2])
			ratio = n1 and n2 and n1 / n2 or default_ratio
		else
			ratio = tonumber(ratio[1]) or default_ratio
		end

		hotbar_data[name].aspect_ratio = ratio

		for i = 1, 8 do
			player:hud_change(hotbar_data[name]["hotbar_slot_"..i], "scale", {x = -4, y = -4 * ratio})
		end

		minetest.chat_send_player(name, "Your aspect ratio was successfully set to "..ratio)
	end
})
