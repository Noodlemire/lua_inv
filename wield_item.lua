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

local wielded_item_entities = {}

minetest.register_entity("lua_inv:wielded_item", {
	initial_properties = {
		visual_size = {x = 0.25, y = 0.25},
		textures = {""},
		pointable = false,
		is_visible = false,
		static_save = false
	},

	_item = "",

	on_step = function(self, dtime)
		if not self._owner or not lua_inv.player_inventory[self._owner:get_player_name()] then return end

		local wielded_item = lua_inv.get_player_wielded_item(self._owner)

		if self._item ~= wielded_item:to_string() then
			self._item = wielded_item:to_string()

			local anim = wielded_item:get_animation(1)
			if anim then
				self._anim = {
					frame = 1,
					max_frame = anim.frames,
					get_frame = anim.frame_template,
					time = anim.speed,
					init_time = anim.speed
				}
			elseif self._anim then
				self._anim = nil
			end

			if self._item ~= "" then
				if wielded_item:get_inventory_image():sub(1, 14) == "[inventorycube" then
					self.object:set_properties({
						is_visible = true,
						visual = "cube",
						textures = lua_inv.tiles_to_cube_textures(wielded_item:get_definition().tiles)
					})
				else
					self.object:set_properties({
						is_visible = true,
						visual = "mesh",
						mesh = "lua_inv_extrusion.obj",
						textures = {anim and anim.frame_template:format(1) or wielded_item:get_inventory_image()},
						backface_culling = false,
					})
				end
			else
				self.object:set_properties({
					is_visible = false
				})
			end
		elseif self._anim then
			self._anim.time = self._anim.time - dtime * 1000

			if self._anim.time < 0 then
				self._anim.time = self._anim.init_time
				self._anim.frame = self._anim.frame + 1

				if self._anim.frame > self._anim.max_frame then
					self._anim.frame = 1
				end

				self.object:set_properties({textures = {self._anim.get_frame:format(self._anim.frame)}})
			end
		end
	end
})

minetest.register_on_joinplayer(function(player)
	player:hud_set_flags({wielditem = false})

	minetest.after(0.1, function()
		local ent = minetest.add_entity(player:get_pos(), "lua_inv:wielded_item"):get_luaentity()

		ent._owner = player
		wielded_item_entities[player:get_player_name()] = ent

		ent.object:set_attach(player, "Arm_Right", {x=0, y=4, z=2.5}, {x=-45, y=180, z=0}, true)
	end)
end)
