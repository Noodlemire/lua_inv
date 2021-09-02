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

lua_inv.survival_inventory = {}

local function get_player_display(player)
	local player_display = nil
	local props = player:get_properties()

	if not props.mesh or props.mesh == "" then
		return "image[1,0.6;1,"..props.visual_size.y..";"..props.textures[1].."]"
	else
		local t = {}

		for _, v in ipairs(props.textures) do
			t[#t+1] = core.formspec_escape(v):gsub(",", "!")
		end

		local textures = table.concat(t, ","):gsub("!", ",")

		return "model[0.5,0.6;"..(2*props.visual_size.x)..","..(2*props.visual_size.y)..";player_model;"..props.mesh..";"..textures..";-15,195;"
			.."false;true;1,1]"
	end
end

function lua_inv.survival_inventory.form()
	local df = lua_inv.dynamic_formspec()
	df:page_add("Crafting")

	df:add(lua_inv.formspec_element("player_view", {}, function(self, player, formname, fields) return get_player_display(player) end))
	df:add(lua_inv.drop_item_button(7, 7.4))
	df:add(lua_inv.dynamic_list("current_player", "main", 0, 3.25, 8, 4))
	df:add(lua_inv.dynamic_list("current_player", "craft", 3, 0, 3, 3))
	df:add(lua_inv.dynamic_list("current_player", "craftpreview", 7, 1, 1, 1))
	df:add(lua_inv.stack_mode_selector(0, 7.4))
	
	return df
end

function lua_inv.survival_inventory.ref(player)
	return lua_inv.inventory(player:get_player_name(),
		--Allow Change
		function(inv, change)
			return lua_inv.set_list_take_only(inv, change, "craftpreview")
		end, 

		nil,

		--After Change
		function(inv, change)
			local is_craft = false
			local is_result = false
			local protected_i = false

			if change.type == "set" then
				is_craft = change.stack.parent.list == "craft"
				is_result = change.stack.parent.list == "craftpreview"
			elseif change.type == "swap" then
				is_craft = change.stack1.parent.list == "craft" or change.stack2.parent.list == "craft"
				is_result = change.stack1.parent.list == "craftpreview"

				if is_craft and is_result then
					protected_i = change.stack2.parent.index
				end
			end

			if is_result then
				for i = 1, inv:get_size("craft") do
					if i ~= protected_i then
						local stack = inv:get_stack("craft", i)
						stack:take_item()
					end
				end
			end

			if is_craft then
				local items = {}

				for i = 1, inv:get_size("craft") do
					items[i] = lua_inv.itemstack_to_userdata(inv:get_stack("craft", i))
				end

				local output = minetest.get_craft_result({method = "normal", width = 3, items = items})

				local craftpreview = inv:get_stack("craftpreview", 1)
				local previewstack = lua_inv.itemstack_from_userdata(output.item)

				rawset(craftpreview, "name", previewstack:get_name())
				rawset(craftpreview, "count", previewstack:get_count())
				rawset(craftpreview, "wear", previewstack:get_wear())
				rawset(craftpreview, "tool_capabilities", previewstack:get_tool_capabilities())	
				craftpreview:get_meta():from_table(previewstack:get_meta():to_table())
			end

			lua_inv.update_hotbar(player)
			lua_inv.update_held_item_data(player)
		end
	)
end
