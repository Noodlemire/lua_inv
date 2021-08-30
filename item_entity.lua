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

function lua_inv.tiles_to_cube_textures(tiles)
	local textures = table.copy(tiles)

	if not textures[2] then textures[2] = textures[1] end
	if not textures[3] then textures[3] = textures[2] end
	if not textures[4] then textures[4] = textures[3] end
	if not textures[5] then textures[5] = textures[4] end
	if not textures[6] then textures[6] = textures[5] end

	for i = 1, 6 do
		if type(textures[i]) == "table" then
			textures[i] = textures[i].name
		end
	end

	return textures
end

local old_on_punch = minetest.registered_entities["__builtin:item"].on_punch

entitycontrol.override_entity("__builtin:item", {
	initial_properties = {
		hp_max = 1,
		physical = true,
		collide_with_objects = false,
		collisionbox = {-0.3, -0.3, -0.3, 0.3, 0.3, 0.3},
		visual_size = {x = 0.4, y = 0.4},
		textures = {""},
		is_visible = false,
	},

	set_item = function(self, itemstack)
		if not itemstack then
			itemstack = lua_inv.itemstack()
		end

		if type(itemstack) == "userdata" then
			itemstack = lua_inv.itemstack_from_userdata(itemstack)
		end

		if type(itemstack) == "string" then
			itemstack = lua_inv.itemstack_from_string(itemstack)
		end

		self.itemstring = itemstack:to_string()

		if self.itemstring == "" then
			return
		end

		local max_count = itemstack:get_stack_max()
		local count = itemstack:get_count()
		local size = 0.2 + 0.1 * (count / max_count) ^ (1 / 3)
		local def = itemstack:get_definition()
		local glow = def and math.floor((def.light_source or 0) / 2 + 0.5)

		local anim = itemstack:get_animation(1)
		if anim then
			self._anim = {
				frame = 1,
				max_frame = anim.frames,
				get_frame = anim.frame_template,
				time = anim.speed,
				init_time = anim.speed
			}
		end

		if itemstack:get_inventory_image():sub(1, 14) == "[inventorycube" then
			self.object:set_properties({
				is_visible = true,
				visual_size = {x = size, y = size},
				collisionbox = {-size, -size, -size, size, size, size},
				automatic_rotate = math.pi * 0.5 * 0.2 / size,
				visual = "cube",
				textures = lua_inv.tiles_to_cube_textures(def and def.tiles or {{}}),
				glow = glow,
			})
		else
			self.object:set_properties({
				is_visible = true,
				visual_size = {x = size, y = size},
				collisionbox = {-size, -size, -size, size, size, size},
				automatic_rotate = math.pi * 0.5 * 0.2 / size,
				visual = "mesh",
				mesh = "lua_inv_extrusion.obj",
				textures = {anim and anim.current_frame or itemstack:get_inventory_image()},
				backface_culling = false,
				glow = glow,
			})
		end
	end,

	on_punch = function(self, hitter)
		local inv = lua_inv.player_inventory[hitter:get_player_name()].inv

		if inv and self.itemstring ~= "" then
			local left = inv:add_item("main", lua_inv.itemstack_from_string(self.itemstring))

			if left and not left:is_empty() then
				self:set_item(left)
				return
			end
		end

		self.itemstring = ""
		self.object:remove()
	end,

	on_step = function(self, dtime)
		if self._anim then
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
