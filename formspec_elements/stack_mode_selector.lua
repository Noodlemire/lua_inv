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

function lua_inv.stack_mode_selector(in_x, in_y)
	return lua_inv.formspec_element(
		"stack_mode_selector",

		{
			{in_x, in_y},
		},

		function(self, player, formname, fields)
			local meta, temp_meta = lua_inv.get_df_meta(player)

			if not meta then
				minetest.log("warning", "Warning: Attempt to form a closed formspec.")
				return ""
			end

			local stack_mode = meta:get("stack_mode") or "lua_inv_stack_mode_all"

			if fields and not temp_meta:contains("lua_inv_stack_mode_selector_flag") then
				temp_meta:set_string("lua_inv_stack_mode_selector_flag", "true")

				for field in pairs(fields) do
					if field == "lua_inv_stack_mode_all" or field == "lua_inv_stack_mode_half" or field == "lua_inv_stack_mode_single" then
						meta:set_string("stack_mode", field)
						stack_mode = field
						break
					end
				end
			end

			local pos = self.args[1]

			local str = "image_button["..pos[1]..","..pos[2]..";1,1;lua_inv_stack_mode_all.png;lua_inv_stack_mode_all;]"..
						"image_button["..(pos[1]+1)..","..pos[2]..";1,1;lua_inv_stack_mode_half.png;lua_inv_stack_mode_half;]"..
						"image_button["..(pos[1]+2)..","..pos[2]..";1,1;lua_inv_stack_mode_single.png;lua_inv_stack_mode_single;]"..
						"tooltip[lua_inv_stack_mode_all;Set Stack Mode: All]"..
						"tooltip[lua_inv_stack_mode_half;Set Stack Mode: Half]"..
						"tooltip[lua_inv_stack_mode_single;Set Stack Mode: Single]"

			if stack_mode == "lua_inv_stack_mode_single" then
				str = str.."image["..(pos[1]+2)..","..pos[2]..";1,1;lua_inv_selected.png]"
			elseif stack_mode == "lua_inv_stack_mode_half" then
				str = str.."image["..(pos[1]+1)..","..pos[2]..";1,1;lua_inv_selected.png]"
			else
				str = str.."image["..(pos[1])..","..pos[2]..";1,1;lua_inv_selected.png]"
			end

			return str
		end
	)
end
