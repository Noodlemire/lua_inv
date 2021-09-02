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

function lua_inv.active_indicator(in_x, in_y, in_w, in_h, in_base_img, in_cover_img, in_var)
	return lua_inv.formspec_element(
		"fuel_indicator",

		{
			{in_x, in_y},
			{in_w, in_h},
			in_base_img,
			in_cover_img,
			in_var,
		},

		function(self, player, formname, fields)
			local meta, temp_meta = lua_inv.get_df_meta(player)

			if not meta then
				minetest.log("warning", "Warning: Attempt to form a closed formspec.")
				return ""
			end

			local pos = self.args[1]
			local size = self.args[2]
			local base_img = self.args[3]
			local cover_img = self.args[4]
			local var = self.args[5]

			local variable = meta:get_float(var)

			return "image["..pos[1]..","..pos[2]..";"..size[1]..","..size[2]..";"..base_img.."^[lowpart:"..(variable)..":"..cover_img.."]"
		end
	)
end
