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

function lua_inv.change_involves_list(change, listname)
	if change.stack and change.stack.parent.list == listname then return change.stack end
	if change.stack1 and change.stack1.parent.list == listname then return change.stack2 end
	if change.stack2 and change.stack2.parent.list == listname then return change.stack1 end
end

function lua_inv.set_list_take_only(inv, change, listname)
	if change.type == "swap" and ((change.stack1.parent.list == listname and change.stack2:is_empty()) or 
				(change.stack2.parent.list == listname and change.stack1:is_empty())) then
		return true
	end

	if change.type == "swap" and (change.stack1.parent.list == listname or change.stack2.parent.list == listname) then
		return false
	end

	if change.type == "set" and change.stack.parent.list == listname and (change.key ~= "count" or change.val ~= 0) then
		return false
	end

	return true
end



minetest.register_chatcommand("is", {
	description = "Get the item string of the item that you are holding.",

	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player:get_pos() then return end

		minetest.chat_send_player(name, lua_inv.get_player_wielded_item(player):to_string())
	end
})

local function give_item(name, param)
	if not minetest.get_player_by_name(name):get_pos() then return end

	local playername, itemname = param:match("^([^ ]+) +(.+)$")

	local player = minetest.get_player_by_name(playername or "")
	local itemstack = lua_inv.itemstack_from_string(itemname or "")
	if not player or not player:get_pos() or itemstack:is_empty() or not itemstack:is_known() or itemstack:get_name() == "ignore" then
		return false, "The provided player or itemstack is invalid."
	end

	itemstack = lua_inv.player_inventory[name].inv:add_item("main", itemstack)

	if not itemstack:is_empty() then
		return false, "That player's inventory was too full. Could not give all of the requested stack."
	end

	return true, "Successfully given."
end

minetest.override_chatcommand("give", {
	func = give_item
})

minetest.override_chatcommand("giveme", {
	func = function(name, param)
		return give_item(name, name.." "..(param or ""))
	end
})

if minetest.settings:get_bool("lua_inv_test_items") then
	minetest.register_craftitem("lua_inv:die", {
		description = "Roll the die!",
		inventory_image = "lua_inv_die_1.png",

		_lua_inv_on_use = function(itemstack, user, pointed_thing)
			local meta = itemstack:get_meta()
			local side = math.random(6)

			minetest.chat_send_player(user:get_player_name(), "You got a "..side.."!")

			meta:set_string("inventory_image", "lua_inv_die_"..side..".png")
		end
	})

	local torch_def = {
		description = "Animated Torch",
		inventory_image = "lua_inv_torch_animated.png",

		_lua_inv_animation = function(self, frame)
			return {frames = 16, speed = 250, frame_template = "lua_inv_torch_%d.png"}
		end
	}

	if minetest.get_modpath("default") then
		minetest.override_item("default:torch", torch_def)
		minetest.register_alias("lua_inv:torch", "default:torch")
	else
		minetest.register_craftitem("lua_inv:torch", torch_def)
	end

	minetest.register_craftitem("lua_inv:pick", {
		description = "Stackable Pickaxe",
		inventory_image = "lua_inv_stackwear_pick.png",

		tool_capabilities = {
			full_punch_interval = 1.2,
			max_drop_level=0,
			groupcaps={
				cracky = {times={[3]=0.60}, uses=2, maxlevel=1},
			},
			damage_groups = {fleshy=2},
		},

		sound = {breaks = "default_tool_breaks"},
		groups = {pickaxe = 1}
	})

	minetest.register_chatcommand("testitems", {
		description = "Gain a set of test lua_inv test 	items.",

		privs = {debug = true},

		func = function(name, param)
			local player = minetest.get_player_by_name(name)
			if not player:get_pos() then return end

			local inv = lua_inv.player_inventory[name].inv

			inv:add_item("main", lua_inv.itemstack("lua_inv:die"))
			inv:add_item("main", lua_inv.itemstack("lua_inv:torch"))
			inv:add_item("main", lua_inv.itemstack("lua_inv:pick", 66, 75))
			inv:add_item("main", lua_inv.itemstack("lua_inv:pick", 75, 33))
		end
	})
end
