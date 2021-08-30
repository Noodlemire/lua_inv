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

-----------------------------------------------------
--                   Chests                        --
-----------------------------------------------------

local function chest_formspec(pos)
	return lua_inv.dynamic_formspec({
		lua_inv.formspec_element("size", {{8, 10}}),
		lua_inv.dynamic_list({k = "nodemeta", v = {pos.x, pos.y, pos.z}}, "main", 0, 0.3, 8, 4),
		lua_inv.dynamic_list("current_player", "main", 0, 4.85, 8, 1),
		lua_inv.dynamic_list("current_player", "main", 0, 6.08, 8, 3, 8),
		lua_inv.stack_mode_selector(0, 9.1)
	})
end

local function chest_override(name)
	local def = minetest.registered_items[name]

	local override_def = {}

	override_def.on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		minetest.sound_play(def.sound_open, {gain = 0.3, pos = pos,
				max_hear_distance = 10}, true)
		if not default.chest.chest_lid_obstructed(pos) then
			minetest.swap_node(pos, {
					name = name .. "_open",
					param2 = node.param2 })
		end
		minetest.after(0.2, lua_inv.show_formspec,
				clicker, name, chest_formspec(pos))
		default.chest.open_chests[clicker:get_player_name()] = { pos = pos,
				sound = def.sound_close, swap = name }
	end

	override_def.can_dig = function(pos, player)
		local inv = lua_inv.fetch_node_inventory(pos, true)

		return inv and inv:is_empty("main") and default.can_interact_with_node(player, pos)
	end

	override_def._lua_inv_inventory = function(pos)
		local inv = lua_inv.inventory(pos)
		inv:set_size("main", 32)

		return inv
	end

	minetest.override_item(name, override_def)
	minetest.override_item(name.."_open", override_def)
end

chest_override("default:chest")
chest_override("default:chest_locked")
