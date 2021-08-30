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

local detached_inventory = {}

function lua_inv.create_detached_inventory(name, input_parent, allow_change_func, on_change_func, after_change_func)
	if detached_inventory[name] then
		error("Error: Attempt to create a detached inventory named \""..name.."\", but one already exists!")
	end

	detached_inventory[name] = lua_inv.inventory(input_parent, allow_change_func, on_change_func, after_change_func)
	return detached_inventory[name]
end

function lua_inv.get_detached_inventory(name)
	return detached_inventory[name]
end
