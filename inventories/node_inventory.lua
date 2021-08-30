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

local node_inventory = smart_vector_table.new()

function lua_inv.fetch_node_inventory(pos, keep_nil)
	local inv = node_inventory.get(pos)

	if not inv and not keep_nil then
		local node = minetest.get_node(pos)
		local def = minetest.registered_nodes[node.name]
		local meta = minetest.get_meta(pos)

		inv = def and def._lua_inv_inventory and def._lua_inv_inventory(pos) or lua_inv.inventory(pos)

		if meta:contains("lua_inv") then
			lua_inv.inventory_from_serialized_string(meta:get_string("lua_inv"), inv)
		end

		node_inventory.set(pos, inv)
	end

	return inv
end

minetest.register_on_shutdown(function()
	for i = 1, node_inventory.size() do
		local pos, inv = node_inventory.getVector(i), node_inventory.getValue(i)
		local meta = minetest.get_meta(pos)

		meta:set_string("lua_inv", "return "..inv:serialize())
	end
end)
