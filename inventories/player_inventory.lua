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

lua_inv.player_inventory = {}

local storage = minetest.get_mod_storage()



minetest.register_craftitem("lua_inv:held_item_data", {
	description = "If you see this message in-game, there is either a bug or an incompatible mod.",
	groups = {not_in_creative_inventory = 1},
	inventory_image = "blank.png",

	after_use = function(itemstack, user, node, digparams)
		local tool = lua_inv.get_player_wielded_item(user)
		local def = tool:get_definition()

		if not def then return end

		if def.after_use then
			local result = def.after_use(lua_inv.itemstack_to_userdata(tool), user, node, digparams)

			if result then
				lua_inv.set_player_wielded_item(user, lua_inv.itemstack_from_userdata(result))
			end
		elseif tool:is_known() then
			tool:add_wear(digparams.wear * 100 / 65535)
		end
	end
})

function lua_inv.update_held_item_data(player)
	if not lua_inv.player_inventory[player:get_player_name()] then return end

	local wielded = ItemStack("lua_inv:held_item_data")
	wielded:get_meta():set_tool_capabilities(lua_inv.get_player_wielded_item(player):get_tool_capabilities())

	player:set_wielded_item(wielded)
end



minetest.register_on_joinplayer(function(player)
	local player_inventory = {}
	local new_inv = lua_inv.survival_inventory.ref(player)
	local stored_inv = storage:get_string("inv_"..player:get_player_name())

	if stored_inv ~= "" then
		lua_inv.inventory_from_serialized_string(stored_inv, new_inv)
	end

	if new_inv:is_empty() then
		local old_inv = player:get_inventory()

		for listname in pairs(old_inv:get_lists()) do
			new_inv:set_size(listname, old_inv:get_size(listname))
			new_inv:set_width(listname, old_inv:get_width(listname))

			for i = 1, old_inv:get_size(listname) do
				new_inv:set_stack(listname, i, lua_inv.itemstack_from_userdata(old_inv:get_stack(listname, i)))
				old_inv:set_stack(listname, i, ItemStack())
			end
		end
	end

	player_inventory.inv = new_inv
	player_inventory.form = lua_inv.survival_inventory.form(player)
	lua_inv.player_inventory[player:get_player_name()] = player_inventory

	player:set_inventory_formspec("size[8,8]button[1,1;6,6;continue;Please this or hit ESC to continue.]")

	lua_inv.update_held_item_data(player)
	
	if minetest.settings:get_bool("lua_inv_mobile_support", true) then
		player:hud_add({
			hud_elem_type = "image",
			text = "lua_inv_crosshair.png",

			scale = {x = 1, y = 1},
			position = {x = 0.5, y = 0.5},
			direction = 1,
			alignment = {x = 0, y = 0},
			offset = {x = 0, y = 0},
			z_index = 1
		})
	end
end)

function lua_inv.get_player_wielded_item(player)
	return lua_inv.player_inventory[player:get_player_name()].inv:get_stack("main", player:get_wield_index())
end

function lua_inv.set_player_wielded_item(player, itemstack)
	if not player or not player:is_player() then return end

	if type(itemstack) == "userdata" then
		itemstack = lua_inv.itemstack_from_userdata(itemstack)
	end

	lua_inv.player_inventory[player:get_player_name()].inv:set_stack("main", player:get_wield_index(), itemstack)
end

minetest.register_on_dignode(function(pos, oldnode, digger)
	local itemname = ""

	if digger and digger:is_player() then
		itemname = lua_inv.get_player_wielded_item(digger):get_name()
	end

	local drops = minetest.get_node_drops(oldnode, itemname)

	for i = 1, #drops do
		if digger and digger:is_player() then
			local leftover = lua_inv.player_inventory[digger:get_player_name()].inv:add_item("main", lua_inv.itemstack_from_string(drops[i]))

			if not leftover:is_empty() then
				minetest.add_item(pos, lua_inv.itemstack_to_userdata(leftover))
			end

			digger:get_inventory():remove_item("main", ItemStack(drops[i]))
		else
			minetest.add_item(pos, drops[i])
		end
	end
end)

minetest.register_allow_player_inventory_action(function(player, action, inventory, inventory_info)
	return 0
end)



local function get_pointed_thing(player, tool)
	--Get the position of the player's eyes, to determine pointed_thing
	local pos = player:get_pos()
	pos.y = pos.y + player:get_properties().eye_height
	--Get the tool's definition, to check its digparams and range
	local def = tool:get_definition()
	--Create a ray between the player's eyes and where they're looking, limited by their tool's range
	local ray = Raycast(pos, vector.add(pos, vector.multiply(player:get_look_dir(), (def and def.range) or minetest.registered_items[""].range or 4)))

	--Return the first pointable thing found that isn't the player calling this
	for pt in ray do
		if pt.type ~= "nothing" and not (pt.ref and pt.ref == player) then
			return pt
		end
	end

	--Return a pointed thing of "nothing" if nothing could be found.
	return {type = "nothing"}
end

controls.register_on_press(function(player, control)
	if control == "dig" then
		local itemstack = lua_inv.get_player_wielded_item(player)
		if itemstack:is_empty() then return end

		local pointed_thing = get_pointed_thing(player, itemstack)

		local def = itemstack:get_definition()
		if not def then return end

		if def._lua_inv_on_use then
			def._lua_inv_on_use(itemstack, player, pointed_thing)
		end

		if def.on_use then
			itemstack = lua_inv.itemstack_to_userdata(itemstack)

			local output = def.on_use(itemstack, player, pointed_thing)

			if output then
				itemstack = output
			end

			itemstack = lua_inv.itemstack_from_userdata(itemstack)
		end

		lua_inv.set_player_wielded_item(player, itemstack)
	end

	if control == "place" or (minetest.settings:get_bool("lua_inv_mobile_support", true) and control == "aux1") then
		local itemstack = lua_inv.get_player_wielded_item(player)
		if itemstack:is_empty() then return end

		local def = itemstack:get_definition()
		if not def then return end

		local pointed_thing = get_pointed_thing(player, itemstack)

		if pointed_thing.type == "node" then
			if def._lua_inv_on_place then
				def._lua_inv_on_place(itemstack, player, pointed_thing)
			end
		elseif def._lua_inv_on_secondary_use then
			def._lua_inv_on_secondary_use(itemstack, player, pointed_thing)
		end

		if pointed_thing.type == "node" then
			itemstack = lua_inv.itemstack_to_userdata(itemstack)
			local output = (def.on_place or minetest.item_place)(itemstack, player, pointed_thing)

			if output then
				itemstack = output
			end
		elseif def.on_secondary_use then
			itemstack = lua_inv.itemstack_to_userdata(itemstack)
			local output = def.on_secondary_use(itemstack, player, pointed_thing)

			if output then
				itemstack = output
			end
		end

		if type(itemstack) == "userdata" then
			itemstack = lua_inv.itemstack_from_userdata(itemstack)
		end

		if itemstack then
			lua_inv.set_player_wielded_item(player, itemstack)
		end
	end
end)



local function serialize_inventory(player)
	local pname = player:get_player_name()
	storage:set_string("inv_"..pname, "return "..lua_inv.player_inventory[player:get_player_name()].inv:serialize())
	player:get_inventory():set_lists({})
end

minetest.register_on_leaveplayer(function(player)
	serialize_inventory(player)
end)

minetest.register_on_shutdown(function()
	for _, player in pairs(minetest.get_connected_players()) do
		serialize_inventory(player)
	end
end)
