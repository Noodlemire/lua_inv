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

function lua_inv.button_field_to_context(field)
	local splits = field:split("__")

	local il = splits[2]

	if il ~= "context" and il ~= "current_player" then
		local il_splits = il:split('_', false, 1)

		if il_splits[1] == "nodemeta" then
			local pos = il_splits[2]:split('_')

			il = {k = "nodemeta", v = {tonumber(pos[1]), tonumber(pos[2]), tonumber(pos[3])}}
		else
			il = {type = il_splits[1], name = il_splits[2]}
		end
	end

	return {
		inv_location = il,
		listname = splits[3],
		index = splits[4],
	}
end

function lua_inv.inventory_from_location(inv_location, player)
	local inv = lua_inv.player_inventory[player:get_player_name()].inv

	if inv_location == "current_player" and player then
		inv = lua_inv.player_inventory[player:get_player_name()].inv
	elseif type(inv_location) == "table" then
		if inv_location.k == "player" then
			if not lua_inv.player_inventory[inv_location.v] then
				error("Error: Attempt to find the inventory of a non-existant player named \""..inv_location.v.."\"")
			end

			inv = lua_inv.player_inventory[inv_location.v].inv
		elseif inv_location.k == "nodemeta" then
			inv = lua_inv.fetch_node_inventory({
				x = tonumber(inv_location.v[1]),
				y = tonumber(inv_location.v[2]),
				z = tonumber(inv_location.v[3])
			})
		elseif location.k == "detached" then
			inv = lua_inv.get_detached_inventory[inv_location.v]

			if not inv then
				error("Error: Attempt to find non-existant inventory location \"detached:"..inv_lovation.v.."\"")
			end
		else
			inv = nil
		end
	end

	if not inv then
		error("Error: Attempt to create unknown inventory type: "..dump(inv_location))
	end

	return inv
end

function lua_inv.dynamic_list(in_inv_location, in_listname, in_x, in_y, in_w, in_h, in_start_i, in_slot_bg)
	return lua_inv.formspec_element(
		"dynamic_list",

		{
			in_inv_location,
			in_listname,
			{in_x, in_y},
			{in_w, in_h},
			in_start_i,
			in_slot_bg
		},

		function(self, player, formname, fields)
			local meta, temp_meta = lua_inv.get_df_meta(player)

			if not meta then
				minetest.log("warning", "Warning: Attempt to form a closed formspec.")
				return ""
			end

			if fields and not temp_meta:contains("dynamic_list_flag") then
				temp_meta:set_string("dynamic_list_flag", "true")

				for field in pairs(fields) do
					if field:sub(1, 15) == "lua_inv_button_" then
						if meta:contains("selection") then
							if field == meta:get_string("selection") then
								meta:remove("selection")
							else
								local stack_mode = meta:get("stack_mode") or "lua_inv_stack_mode_all"

								local context_1 = lua_inv.button_field_to_context(meta:get_string("selection"))
								local context_2 = lua_inv.button_field_to_context(field)

								local inv_1 = lua_inv.inventory_from_location(context_1.inv_location, player)
								local inv_2 = lua_inv.inventory_from_location(context_2.inv_location, player)

								local stack_1 = inv_1:get_stack(context_1.listname, context_1.index)
								local stack_2 = inv_2:get_stack(context_2.listname, context_2.index)

								if stack_mode == "lua_inv_stack_mode_all" or stack_1:get_count() <= 1 then
									if stack_1:is_similar(stack_2) and not (stack_1:is_full() or stack_2:is_full()) then
										stack_2 = stack_2 + stack_1
									else
										inv_1:set_stack(context_1.listname, context_1.index, stack_2)
									end
								elseif stack_mode == "lua_inv_stack_mode_half" then
									if stack_1:peek_item(math.ceil(stack_1:get_count()/2)):item_fits(stack_2) then
										local half_stack = stack_1:take_item(math.ceil(stack_1:get_count()/2))

										stack_2 = stack_2 + half_stack
										stack_1 = stack_1 + half_stack
									end
								else
									if stack_1:peek_item():item_fits(stack_2) then
										local single_stack = stack_1:take_item(1)

										stack_2 = stack_2 + single_stack
										stack_1 = stack_1 + single_stack
									end
								end

								if stack_1:is_empty() then
									meta:remove("selection")
								end
							end
						else
							local con = lua_inv.button_field_to_context(field)

							if not lua_inv.inventory_from_location(con.inv_location, player):get_stack(con.listname, con.index):is_empty() then
								meta:set_string("selection", field)
							end
						end

						break
					end
				end
			end

			local str = ""

			local inv_location = self.args[1]
			local listname = self.args[2]
			local pos = self.args[3]
			local size = self.args[4]
			local start_i = (tonumber(self.args[5]) or 0)
			local slot_bg = self.args[6]

			local inv = lua_inv.inventory_from_location(inv_location, player)

			for x = 1, size[1] do
				for y = 1, size[2] do
					local ind = start_i + x + (y - 1) * size[1]
					local stack = inv:get_stack(listname, ind)

					local slotname = '_'..listname.."__"..ind
					if type(inv_location) == "table" then
						if type(inv_location.v) == "table" then
							slotname = '_'..inv_location.k..'_'..inv_location.v[1]..'_'..inv_location.v[2]..'_'..
								inv_location.v[3]..'_'..slotname
						else
							slotname = '_'..inv_location.k..'_'..inv_location.v..'_'..slotname
						end
					else
						slotname = '_'..inv_location..'_'..slotname
					end

					slotname = "lua_inv_button_"..slotname

					str = str.."image_button["..(pos[1] + x - 1)..','..(pos[2] + y - 1)..";1,1;;"..slotname..";]"

					if stack and not stack:is_empty() then
						str = str.."tooltip["..slotname..';'..stack:get_description()..']'

						local anim = stack:get_animation()
						if anim then
							str = str.."animated_image["..(pos[1] + x - 1)..','..(pos[2] + y - 1)..";1,1;"..stack:get_name()..";"
									..stack:get_inventory_image()..";"..anim.frames..";"..anim.speed..";]"
						elseif not stack:get_inventory_image(true) then
							str = str.."item_image["..(pos[1] + x - 1)..','..(pos[2] + y - 1)..";1,1;"..stack:get_name().."]"
						else
							str = str.."image["..(pos[1] + x - 1)..','..(pos[2] + y - 1)..";1,1;"..stack:get_inventory_image()..']'
						end

						if stack:get_count() > 1 then
							str = str.."label["..(pos[1] + x - 0.4)..','..(pos[2] + y - 0.5)..';'..stack:get_count()..']'
						end

						if stack:get_wear() > 0 then
							str = str.."image["..(pos[1] + x - 0.95)..','..(pos[2] + y - 1.0625)..";0.875,1;"..stack:get_wear_visual()..']'
						end
					elseif slot_bg then
						str = str.."image["..(pos[1] + x - 1)..','..(pos[2] + y - 1)..";0.875,1;"..slot_bg.."]"
					end

					if meta:get_string("selection") == slotname then
						str = str.."image["..(pos[1] + x - 1.0456)..','..(pos[2] + y - 1.0456)..";1.111,1.111;lua_inv_selected.png]"
					end
				end
			end

			return str
		end
	)
end
