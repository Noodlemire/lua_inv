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

function lua_inv.drop_item_button(in_x, in_y)
	return lua_inv.formspec_element(
		"drop_item_button",

		{{in_x, in_y}},

		function(self, player, formname, fields)
			local meta, temp_meta = lua_inv.get_df_meta(player)

			if not meta then
				minetest.log("warning", "Warning: Attempt to form a closed formspec.")
				return ""
			end

			local x, y = self.args[1][1], self.args[1][2]

			local formspec = "image_button["..x..","..y..";1,1;lua_inv_drop_item.png;drop_item_button;]"
							.."tooltip[drop_item_button;Drop Selected Item]"

			if not fields or not fields.drop_item_button or not meta:contains("selection") then return formspec end

			local context = lua_inv.button_field_to_context(meta:get_string("selection"))
			local inv = lua_inv.inventory_from_location(context.inv_location, player)

			local selected_item = inv:get_stack(context.listname, context.index)
			if selected_item:is_empty() then return formspec end

			local dropped = selected_item:take_item(selected_item:get_count())
			if dropped:is_empty() then return formspec end

			meta:remove("selection")

			local pos = player:get_pos()
			pos = {
				x = pos.x,
				y = pos.y + player:get_properties().eye_height,
				z = pos.z
			}

			local ent = minetest.add_entity(pos, "__builtin:item")

			if ent then
				ent:set_velocity(player:get_look_dir())
				ent:get_luaentity():set_item(dropped:to_string())
			end

			return formspec
		end
	)
end
