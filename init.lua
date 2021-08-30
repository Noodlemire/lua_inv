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

lua_inv = {}

local mp = minetest.get_modpath(minetest.get_current_modname())..'/'

dofile(mp.."metadata.lua")
dofile(mp.."itemstack.lua")
dofile(mp.."item_entity.lua")
dofile(mp.."hotbar.lua")
dofile(mp.."wield_item.lua")
dofile(mp.."misc.lua")

dofile(mp.."inventories/inventory.lua")
dofile(mp.."inventories/player_inventory.lua")
dofile(mp.."inventories/node_inventory.lua")

dofile(mp.."formspec_elements/formspec_element.lua")
dofile(mp.."formspec_elements/dynamic_list.lua")
dofile(mp.."formspec_elements/stack_mode_selector.lua")
dofile(mp.."formspec_elements/drop_item_button.lua")

dofile(mp.."dynamic_formspecs/manager.lua")
dofile(mp.."dynamic_formspecs/dynamic_formspec.lua")
dofile(mp.."dynamic_formspecs/survival_inventory.lua")

if minetest.get_modpath("default") then
	dofile(mp.."optional_depends/default.lua")
end

minetest.register_on_mods_loaded(function()
	if minetest.get_modpath("sfinv") then
		sfinv.enabled = false
	end
end)
