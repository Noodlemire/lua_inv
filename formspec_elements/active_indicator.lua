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
